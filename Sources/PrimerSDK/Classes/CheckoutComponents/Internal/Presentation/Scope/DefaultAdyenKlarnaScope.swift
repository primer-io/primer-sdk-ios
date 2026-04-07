//
//  DefaultAdyenKlarnaScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class DefaultAdyenKlarnaScope: PrimerAdyenKlarnaScope, ObservableObject, LogReporter {

    let paymentMethodType: String

    private(set) var presentationContext: PresentationContext

    var dismissalMechanism: [DismissalMechanism] {
        checkoutScope?.dismissalMechanism ?? []
    }

    var state: AsyncStream<PrimerAdyenKlarnaState> {
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

    var screen: AdyenKlarnaScreenComponent?
    var payButton: AdyenKlarnaButtonComponent?
    var submitButtonText: String?

    private weak var checkoutScope: DefaultCheckoutScope?
    private let interactor: ProcessAdyenKlarnaPaymentInteractor
    private let accessibilityService: AccessibilityAnnouncementService?
    private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?
    private let repository: AdyenKlarnaRepository?

    @Published private var internalState: PrimerAdyenKlarnaState

    init(
        paymentMethodType: String = PrimerPaymentMethodType.adyenKlarna.rawValue,
        checkoutScope: DefaultCheckoutScope,
        presentationContext: PresentationContext = .fromPaymentSelection,
        interactor: ProcessAdyenKlarnaPaymentInteractor,
        accessibilityService: AccessibilityAnnouncementService? = nil,
        analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol? = nil,
        repository: AdyenKlarnaRepository? = nil,
        paymentMethod: CheckoutPaymentMethod? = nil,
        surchargeAmount: String? = nil
    ) {
        self.paymentMethodType = paymentMethodType
        self.checkoutScope = checkoutScope
        self.presentationContext = presentationContext
        self.interactor = interactor
        self.accessibilityService = accessibilityService
        self.analyticsInteractor = analyticsInteractor
        self.repository = repository
        internalState = PrimerAdyenKlarnaState(
            paymentMethod: paymentMethod,
            surchargeAmount: surchargeAmount
        )
    }

    func start() {
        Task { [self] in
            await loadPaymentOptions()
        }
    }

    func selectOption(_ option: AdyenKlarnaPaymentOption) {
        internalState.selectedOption = option
        submit()
    }

    func submit() {
        guard internalState.selectedOption != nil else { return }
        Task { [self] in
            await performPayment()
        }
    }

    func cancel() {
        repository?.cancelPolling(paymentMethodType: paymentMethodType)
        internalState.status = .idle
        checkoutScope?.onDismiss()
    }

    func onBack() {
        if presentationContext.shouldShowBackButton {
            checkoutScope?.checkoutNavigator.navigateBack()
        }
    }

    // MARK: - Private

    private func loadPaymentOptions() async {
        internalState.status = .loading

        do {
            let options = try await interactor.fetchPaymentOptions()

            guard !options.isEmpty else {
                let error = PrimerError.invalidValue(
                    key: "paymentOptions",
                    reason: "No Klarna payment options available"
                )
                ErrorHandler.handle(error: error)
                internalState.status = .failure(error.localizedDescription)
                return
            }

            internalState.paymentOptions = options

            if options.count == 1 {
                internalState.selectedOption = options[0]
                await performPayment()
            } else {
                internalState.status = .optionSelection
            }
        } catch {
            let errorMessage = extractUserFriendlyErrorMessage(from: error)
            internalState.status = .failure(errorMessage)
        }
    }

    private func performPayment() async {
        guard let checkoutScope else { return }
        guard let selectedOption = internalState.selectedOption else { return }

        internalState.status = .submitting
        checkoutScope.startProcessing()

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

            let result = try await interactor.execute(selectedOption: selectedOption)

            checkoutScope.startProcessing()

            internalState.status = .polling

            await analyticsInteractor?.trackEvent(
                .paymentRedirectToThirdParty,
                metadata: .payment(PaymentEvent(paymentMethod: paymentMethodType))
            )

            internalState.status = .success
            checkoutScope.handlePaymentSuccess(result)

        } catch {
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
