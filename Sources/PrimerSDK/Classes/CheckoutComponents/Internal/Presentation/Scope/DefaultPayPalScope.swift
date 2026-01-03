//
//  DefaultPayPalScope.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import SwiftUI

/// Default implementation of PrimerPayPalScope that handles PayPal payment flow.
@available(iOS 15.0, *)
@MainActor
public final class DefaultPayPalScope: PrimerPayPalScope, ObservableObject, LogReporter {

    // MARK: - Public Properties

    public private(set) var presentationContext: PresentationContext

    public var dismissalMechanism: [DismissalMechanism] {
        checkoutScope?.dismissalMechanism ?? []
    }

    public var state: AsyncStream<PayPalState> {
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

    public var screen: PayPalScreenComponent?
    public var payButton: PayPalButtonComponent?
    public var submitButtonText: String?

    // MARK: - Private Properties

    private weak var checkoutScope: DefaultCheckoutScope?
    private let processPayPalInteractor: ProcessPayPalPaymentInteractor
    private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?

    @Published private var internalState = PayPalState()

    // MARK: - Initialization

    init(
        checkoutScope: DefaultCheckoutScope,
        presentationContext: PresentationContext = .fromPaymentSelection,
        processPayPalInteractor: ProcessPayPalPaymentInteractor,
        analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol? = nil
    ) {
        self.checkoutScope = checkoutScope
        self.presentationContext = presentationContext
        self.processPayPalInteractor = processPayPalInteractor
        self.analyticsInteractor = analyticsInteractor
    }

    // MARK: - PrimerPaymentMethodScope Methods

    public func start() {
        logger.debug(message: "PayPal scope started")
        internalState.status = .idle
    }

    public func submit() {
        Task {
            await performPayment()
        }
    }

    public func cancel() {
        logger.debug(message: "PayPal payment cancelled")
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
        internalState.status = .loading
        checkoutScope?.startProcessing()

        await analyticsInteractor?.trackEvent(
            .paymentSubmitted,
            metadata: .payment(PaymentEvent(paymentMethod: PrimerPaymentMethodType.payPal.rawValue))
        )

        do {
            internalState.status = .redirecting

            await analyticsInteractor?.trackEvent(
                .paymentProcessingStarted,
                metadata: .payment(PaymentEvent(paymentMethod: PrimerPaymentMethodType.payPal.rawValue))
            )

            let result = try await processPayPalInteractor.execute()

            internalState.status = .success
            checkoutScope?.handlePaymentSuccess(result)
        } catch {
            logger.error(message: "PayPal payment failed: \(error.localizedDescription)")
            internalState.status = .failure(error.localizedDescription)

            let primerError = error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
            checkoutScope?.handlePaymentError(primerError)
        }
    }
}
