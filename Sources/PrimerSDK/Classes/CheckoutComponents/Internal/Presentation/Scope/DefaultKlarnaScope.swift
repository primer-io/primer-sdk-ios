//
//  DefaultKlarnaScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import SwiftUI
import UIKit

/// Default implementation of PrimerKlarnaScope that handles the multi-step Klarna payment flow.
@available(iOS 15.0, *)
@MainActor
public final class DefaultKlarnaScope: PrimerKlarnaScope, ObservableObject, LogReporter {

    // MARK: - Public Properties

    public private(set) var presentationContext: PresentationContext

    public var dismissalMechanism: [DismissalMechanism] {
        checkoutScope?.dismissalMechanism ?? []
    }

    public private(set) var paymentView: UIView?

    public var state: AsyncStream<KlarnaState> {
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

    public var screen: KlarnaScreenComponent?
    public var authorizeButton: KlarnaButtonComponent?
    public var finalizeButton: KlarnaButtonComponent?
    public var categoryItem: KlarnaCategoryItemComponent?

    // MARK: - Private Properties

    private weak var checkoutScope: DefaultCheckoutScope?
    private let processKlarnaInteractor: ProcessKlarnaPaymentInteractor
    private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?

    @Published private var internalState = KlarnaState()

    /// The Klarna client token from session creation, needed for category configuration
    private var klarnaClientToken: String?

    /// The auth token from authorization, needed for tokenization
    private var authorizationToken: String?

    // MARK: - Initialization

    init(
        checkoutScope: DefaultCheckoutScope,
        presentationContext: PresentationContext = .fromPaymentSelection,
        processKlarnaInteractor: ProcessKlarnaPaymentInteractor,
        analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol? = nil
    ) {
        self.checkoutScope = checkoutScope
        self.presentationContext = presentationContext
        self.processKlarnaInteractor = processKlarnaInteractor
        self.analyticsInteractor = analyticsInteractor
    }

    // MARK: - PrimerPaymentMethodScope Methods

    public func start() {
        logger.debug(message: "Klarna scope started")
        Task {
            await createSession()
        }
    }

    public func submit() {
        authorizePayment()
    }

    public func cancel() {
        logger.debug(message: "Klarna payment cancelled")
        checkoutScope?.onDismiss()
    }

    // MARK: - Klarna Flow Actions

    public func selectPaymentCategory(_ categoryId: String) {
        guard internalState.categories.contains(where: { $0.id == categoryId }) else {
            logger.warn(message: "Invalid category ID: \(categoryId)")
            return
        }

        internalState.selectedCategoryId = categoryId
        internalState.step = .categorySelection
        paymentView = nil

        Task {
            await loadPaymentView(for: categoryId)
        }
    }

    public func authorizePayment() {
        guard internalState.step == .viewReady || internalState.step == .categorySelection else {
            logger.warn(message: "Cannot authorize in current step: \(internalState.step)")
            return
        }

        internalState.step = .authorizationStarted

        Task {
            await performAuthorization()
        }
    }

    public func finalizePayment() {
        guard internalState.step == .awaitingFinalization else {
            logger.warn(message: "Cannot finalize in current step: \(internalState.step)")
            return
        }

        Task {
            await performFinalization()
        }
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

    // MARK: - Private Flow Methods

    private func createSession() async {
        internalState.step = .loading

        await analyticsInteractor?.trackEvent(
            .paymentSubmitted,
            metadata: .payment(PaymentEvent(paymentMethod: PrimerPaymentMethodType.klarna.rawValue))
        )

        do {
            let sessionResult = try await processKlarnaInteractor.createSession()
            klarnaClientToken = sessionResult.clientToken

            internalState.categories = sessionResult.categories
            internalState.step = .categorySelection

            logger.debug(message: "Klarna session created with \(sessionResult.categories.count) categories")
        } catch {
            logger.error(message: "Klarna session creation failed: \(error.localizedDescription)")
            let primerError = error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
            checkoutScope?.handlePaymentError(primerError)
        }
    }

    private func loadPaymentView(for categoryId: String) async {
        guard let clientToken = klarnaClientToken else {
            logger.error(message: "Klarna client token not available")
            return
        }

        do {
            let view = try await processKlarnaInteractor.configureForCategory(
                clientToken: clientToken,
                categoryId: categoryId
            )

            // Guard against race condition: user may have switched categories while loading
            guard internalState.selectedCategoryId == categoryId else { return }

            paymentView = view
            internalState.step = .viewReady
        } catch {
            logger.error(message: "Failed to load Klarna payment view: \(error.localizedDescription)")

            guard internalState.selectedCategoryId == categoryId else { return }

            // Revert to category selection on failure
            paymentView = nil
            internalState.step = .categorySelection
        }
    }

    private func performAuthorization() async {
        checkoutScope?.startProcessing()

        await analyticsInteractor?.trackEvent(
            .paymentProcessingStarted,
            metadata: .payment(PaymentEvent(paymentMethod: PrimerPaymentMethodType.klarna.rawValue))
        )

        do {
            let result = try await processKlarnaInteractor.authorize()

            switch result {
            case let .approved(authToken):
                authorizationToken = authToken
                await processPayment(authToken: authToken)

            case let .finalizationRequired(authToken):
                authorizationToken = authToken
                internalState.step = .awaitingFinalization

            case .declined:
                let primerError = PrimerError.klarnaError(
                    message: "Klarna payment was declined",
                    diagnosticsId: UUID().uuidString
                )
                checkoutScope?.handlePaymentError(primerError)
            }
        } catch {
            logger.error(message: "Klarna authorization failed: \(error.localizedDescription)")
            let primerError = error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
            checkoutScope?.handlePaymentError(primerError)
        }
    }

    private func performFinalization() async {
        checkoutScope?.startProcessing()

        do {
            let result = try await processKlarnaInteractor.finalize()

            switch result {
            case let .approved(authToken):
                authorizationToken = authToken
                await processPayment(authToken: authToken)

            case .finalizationRequired:
                // Unexpected - finalization should not require further finalization
                logger.warn(message: "Unexpected finalizationRequired after finalize()")
                await processPayment(authToken: authorizationToken ?? "")

            case .declined:
                let primerError = PrimerError.klarnaError(
                    message: "Klarna finalization was declined",
                    diagnosticsId: UUID().uuidString
                )
                checkoutScope?.handlePaymentError(primerError)
            }
        } catch {
            logger.error(message: "Klarna finalization failed: \(error.localizedDescription)")
            let primerError = error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
            checkoutScope?.handlePaymentError(primerError)
        }
    }

    private func processPayment(authToken: String) async {
        do {
            let result = try await processKlarnaInteractor.tokenize(authToken: authToken)
            checkoutScope?.handlePaymentSuccess(result)
        } catch {
            logger.error(message: "Klarna payment processing failed: \(error.localizedDescription)")
            let primerError = error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
            checkoutScope?.handlePaymentError(primerError)
        }
    }
}
