//
//  DefaultWebRedirectScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import SwiftUI

@available(iOS 15.0, *)
@MainActor
public final class DefaultWebRedirectScope: PrimerWebRedirectScope, ObservableObject, LogReporter {

    // MARK: - Public Properties

    public let paymentMethodType: String

    public private(set) var presentationContext: PresentationContext

    public var dismissalMechanism: [DismissalMechanism] {
        checkoutScope?.dismissalMechanism ?? []
    }

    public var state: AsyncStream<WebRedirectState> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                for await _ in $internalState.values {
                    continuation.yield(internalState)
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - UI Customization Properties

    public var screen: WebRedirectScreenComponent?
    public var payButton: WebRedirectButtonComponent?
    public var submitButtonText: String?

    // MARK: - Private Properties

    private weak var checkoutScope: DefaultCheckoutScope?
    private let processWebRedirectInteractor: ProcessWebRedirectPaymentInteractor
    private let repository: WebRedirectRepository?

    @Published private var internalState: WebRedirectState

    // MARK: - Initialization

    init(
        paymentMethodType: String,
        checkoutScope: DefaultCheckoutScope,
        presentationContext: PresentationContext = .fromPaymentSelection,
        processWebRedirectInteractor: ProcessWebRedirectPaymentInteractor,
        repository: WebRedirectRepository? = nil,
        paymentMethod: CheckoutPaymentMethod? = nil,
        surchargeAmount: String? = nil
    ) {
        self.paymentMethodType = paymentMethodType
        self.checkoutScope = checkoutScope
        self.presentationContext = presentationContext
        self.processWebRedirectInteractor = processWebRedirectInteractor
        self.repository = repository
        self.internalState = WebRedirectState(
            status: .idle,
            paymentMethod: paymentMethod,
            surchargeAmount: surchargeAmount
        )
    }

    // MARK: - PrimerPaymentMethodScope Methods

    public func start() {
        internalState.status = .idle
    }

    public func submit() {
        Task {
            await performPayment()
        }
    }

    public func cancel() {
        // Cancel any in-flight polling before resetting state
        repository?.cancelPolling(paymentMethodType: paymentMethodType)
        internalState.status = .idle
        checkoutScope?.onDismiss()
    }

    // MARK: - Navigation Methods

    public func onBack() {
        if presentationContext.shouldShowBackButton {
            checkoutScope?.checkoutNavigator.navigateBack()
        }
    }

    public func onCancel() {
        checkoutScope?.onDismiss()
    }

    // MARK: - Private Methods

    private func performPayment() async {
        // Capture strong reference to checkoutScope before Safari opens
        // Safari redirect causes SwiftUI views to go off-screen, releasing weak references
        guard let checkoutScope = checkoutScope else { return }

        internalState.status = .loading
        checkoutScope.startProcessing()

        do {
            internalState.status = .redirecting

            let result = try await processWebRedirectInteractor.execute(paymentMethodType: paymentMethodType)

            // Show checkout processing screen to avoid WebRedirectScreen flash when returning from Safari
            checkoutScope.startProcessing()

            internalState.status = .polling

            internalState.status = .success

            checkoutScope.handlePaymentSuccess(result)

        } catch {
            // Show checkout processing screen to avoid WebRedirectScreen flash when returning from Safari
            checkoutScope.startProcessing()

            let errorMessage = extractUserFriendlyErrorMessage(from: error)
            internalState.status = .failure(errorMessage)

            let primerError = error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
            checkoutScope.handlePaymentError(primerError)
        }
    }

    private func extractUserFriendlyErrorMessage(from error: Error) -> String {
        if let primerError = error as? PrimerError {
            return primerError.localizedDescription
        }
        return error.localizedDescription
    }
}
