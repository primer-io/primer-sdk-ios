//
//  ProcessWebRedirectPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import UIKit

@available(iOS 15.0, *)
protocol ProcessWebRedirectPaymentInteractor {
    func execute(paymentMethodType: String) async throws -> PaymentResult
}

@available(iOS 15.0, *)
final class ProcessWebRedirectPaymentInteractorImpl: ProcessWebRedirectPaymentInteractor, LogReporter {

    // MARK: - Vipps Deep Link URL
    // See: https://developer.vippsmobilepay.com/docs/knowledge-base/user-flow/#deep-link-flow
    // If changing these values, they must also be updated in `Info.plist` `LSApplicationQueriesSchemes` of the host app.
    #if DEBUG
    private static let adyenVippsDeeplinkUrl = "vippsmt://"
    #else
    private static let adyenVippsDeeplinkUrl = "vipps://"
    #endif

    // MARK: - Dependencies

    private let repository: WebRedirectRepository
    private let clientSessionActionsFactory: () -> ClientSessionActionsProtocol
    private let deeplinkAbilityProvider: DeeplinkAbilityProviding

    init(
        repository: WebRedirectRepository,
        clientSessionActionsFactory: @escaping () -> ClientSessionActionsProtocol = { ClientSessionActionsModule() },
        deeplinkAbilityProvider: DeeplinkAbilityProviding = UIApplication.shared
    ) {
        self.repository = repository
        self.clientSessionActionsFactory = clientSessionActionsFactory
        self.deeplinkAbilityProvider = deeplinkAbilityProvider
    }

    func execute(paymentMethodType: String) async throws -> PaymentResult {
        do {
            logger.debug(message: "[WebRedirect] Starting payment for: \(paymentMethodType)")

            // 1. Select the payment method via client session actions
            let clientSessionActions = clientSessionActionsFactory()
            try await clientSessionActions.selectPaymentMethodIfNeeded(paymentMethodType, cardNetwork: nil)

            // 2. Call willCreatePayment delegate (allows merchant to abort)
            try await handlePrimerWillCreatePaymentEvent(paymentMethodType: paymentMethodType)

            // 3. Create the session info
            let sessionInfo = createSessionInfo(for: paymentMethodType)

            // 4. Tokenize and create payment to get redirect URLs
            let (redirectUrl, statusUrl) = try await repository.tokenize(
                paymentMethodType: paymentMethodType,
                sessionInfo: sessionInfo
            )

            // 5. Open web authentication (Safari)
            _ = try await repository.openWebAuthentication(
                paymentMethodType: paymentMethodType,
                url: redirectUrl
            )

            // 6. Poll for payment completion
            let resumeToken = try await repository.pollForCompletion(statusUrl: statusUrl)

            // 7. Resume payment with the resume token
            let result = try await repository.resumePayment(
                paymentMethodType: paymentMethodType,
                resumeToken: resumeToken
            )

            logger.debug(message: "[WebRedirect] Payment completed: \(result.status)")
            return result
        } catch {
            // Log all errors for analytics
            ErrorHandler.handle(error: error)
            throw error
        }
    }

    // MARK: - Private Helpers

    private func createSessionInfo(for paymentMethodType: String) -> WebRedirectSessionInfo {
        let localeCode = PrimerSettings.current.localeData.localeCode

        // Special handling for Vipps: if app is not installed, use "WEB" platform
        // to force web redirect instead of deep link
        if paymentMethodType == PrimerPaymentMethodType.adyenVipps.rawValue {
            let vippsAppInstalled = isVippsAppInstalled()
            if !vippsAppInstalled {
                return WebRedirectSessionInfo(locale: localeCode, platform: "WEB")
            }
        }

        return WebRedirectSessionInfo(locale: localeCode)
    }

    private func isVippsAppInstalled() -> Bool {
        guard let url = URL(string: Self.adyenVippsDeeplinkUrl) else {
            return false
        }
        return deeplinkAbilityProvider.canOpenURL(url)
    }

    /// Notifies merchant via delegate before creating payment.
    /// Allows merchant to abort payment based on application logic.
    private func handlePrimerWillCreatePaymentEvent(paymentMethodType: String) async throws {
        // Skip delegate callback for vault intent
        guard PrimerInternal.shared.intent != .vault else { return }

        let checkoutPaymentMethodType = PrimerCheckoutPaymentMethodType(type: paymentMethodType)
        let checkoutPaymentMethodData = PrimerCheckoutPaymentMethodData(type: checkoutPaymentMethodType)

        let decision = await PrimerDelegateProxy.primerWillCreatePaymentWithData(checkoutPaymentMethodData)

        switch decision.type {
        case let .abort(errorMessage):
            throw PrimerError.merchantError(message: errorMessage ?? "")
        case .continue:
            return
        }
    }
}
