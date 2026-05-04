//
//  DefaultWebRedirectScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class DefaultWebRedirectScope: PrimerWebRedirectScope, ObservableObject, LogReporter {

    let paymentMethodType: String

    private(set) var presentationContext: PresentationContext

    var dismissalMechanism: [DismissalMechanism] {
        checkoutScope?.dismissalMechanism ?? []
    }

    var state: AsyncStream<PrimerWebRedirectState> {
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

    var screen: WebRedirectScreenComponent?
    var payButton: WebRedirectButtonComponent?
    var submitButtonText: String?

    private weak var checkoutScope: DefaultCheckoutScope?
    private let processWebRedirectInteractor: ProcessWebRedirectPaymentInteractor
    private let accessibilityService: AccessibilityAnnouncementService?
    private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?
    private let repository: WebRedirectRepository?

    @Published private var internalState: PrimerWebRedirectState

    init(
        paymentMethodType: String,
        checkoutScope: DefaultCheckoutScope,
        presentationContext: PresentationContext = .fromPaymentSelection,
        processWebRedirectInteractor: ProcessWebRedirectPaymentInteractor,
        accessibilityService: AccessibilityAnnouncementService? = nil,
        analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol? = nil,
        repository: WebRedirectRepository? = nil,
        paymentMethod: CheckoutPaymentMethod? = nil,
        surchargeAmount: String? = nil
    ) {
        self.paymentMethodType = paymentMethodType
        self.checkoutScope = checkoutScope
        self.presentationContext = presentationContext
        self.processWebRedirectInteractor = processWebRedirectInteractor
        self.accessibilityService = accessibilityService
        self.analyticsInteractor = analyticsInteractor
        self.repository = repository
        internalState = PrimerWebRedirectState(
            status: .idle,
            paymentMethod: paymentMethod,
            surchargeAmount: surchargeAmount
        )
    }

    func start() {
        internalState.status = .idle
    }

    func submit() {
        Task {
            await performPayment()
        }
    }

    func cancel() {
        // Cancel any in-flight polling before resetting state
        repository?.cancelPolling(paymentMethodType: paymentMethodType)
        internalState.status = .idle
        checkoutScope?.onDismiss()
    }

    func onBack() {
        if presentationContext.shouldShowBackButton {
            checkoutScope?.checkoutNavigator.navigateBack()
        }
    }

    private func performPayment() async {
        // Capture strong reference to checkoutScope before Safari opens
        // Safari redirect causes SwiftUI views to go off-screen, releasing weak references
        guard let checkoutScope else { return }

        internalState.status = .loading
        checkoutScope.startProcessing()

        accessibilityService?.announceStateChange(CheckoutComponentsStrings.a11yWebRedirectLoading)

        await analyticsInteractor?.trackEvent(
            .paymentSubmitted,
            metadata: .payment(PaymentEvent(paymentMethod: paymentMethodType))
        )

        do {
            try await checkoutScope.invokeBeforePaymentCreate(
                paymentMethodType: paymentMethodType
            )

            await analyticsInteractor?.trackEvent(
                .paymentProcessingStarted,
                metadata: .payment(PaymentEvent(paymentMethod: paymentMethodType))
            )

            internalState.status = .redirecting
            accessibilityService?.announceStateChange(CheckoutComponentsStrings.a11yWebRedirectRedirecting)

            let result = try await processWebRedirectInteractor.execute(paymentMethodType: paymentMethodType)

            // Show checkout processing screen to avoid WebRedirectScreen flash when returning from Safari
            checkoutScope.startProcessing()

            internalState.status = .polling
            accessibilityService?.announceStateChange(CheckoutComponentsStrings.a11yWebRedirectPolling)

            await analyticsInteractor?.trackEvent(
                .paymentRedirectToThirdParty,
                metadata: .payment(PaymentEvent(paymentMethod: paymentMethodType))
            )

            internalState.status = .success
            accessibilityService?.announceStateChange(CheckoutComponentsStrings.a11yWebRedirectSuccess)

            checkoutScope.handlePaymentSuccess(result)

        } catch {
            // Show checkout processing screen to avoid WebRedirectScreen flash when returning from Safari
            checkoutScope.startProcessing()

            let errorMessage = extractUserFriendlyErrorMessage(from: error)
            internalState.status = .failure(errorMessage)
            accessibilityService?.announceError(CheckoutComponentsStrings.a11yWebRedirectFailure(errorMessage))

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
