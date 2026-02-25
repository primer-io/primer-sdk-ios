//
//  KlarnaTokenizationComponent.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation
import PrimerNetworking

protocol KlarnaTokenizationComponentProtocol: KlarnaTokenizationManagerProtocol {
    /// - Validates the necessary conditions for proceeding with a payment operation.
    func validate() throws
    /// - Initiates the creation for Klarna Payment Session
    func createPaymentSession() async throws -> Response.Body.Klarna.PaymentSession
    /// - Initiates the authorization for Klarna Payment Session
    func authorizePaymentSession(authorizationToken: String) async throws -> Response.Body.Klarna.CustomerToken
}

final class KlarnaTokenizationComponent: KlarnaTokenizationManager, KlarnaTokenizationComponentProtocol {
    // MARK: - Properties

    private let paymentMethod: PrimerPaymentMethod
    private let apiClient: PrimerAPIClientProtocol
    private var paymentSessionId: String?
    private var recurringPaymentDescription: String?

    // MARK: - Settings

    let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

    // MARK: - Init

    init(
        paymentMethod: PrimerPaymentMethod,
        tokenizationService: TokenizationServiceProtocol = TokenizationService()
    ) {
        self.paymentMethod = paymentMethod
        apiClient = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
        let klarnaOptions = PrimerSettings.current.paymentMethodOptions.klarnaOptions
        recurringPaymentDescription = klarnaOptions?.recurringPaymentDescription

        super.init(
            tokenizationService: tokenizationService,
            createResumePaymentService: CreateResumePaymentService(paymentMethodType: paymentMethod.type)
        )
    }
}

// MARK: - Validate

extension KlarnaTokenizationComponent {
    func validate() throws {
        guard
            let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken,
            decodedJWTToken.isValid,
            decodedJWTToken.pciUrl != nil
        else {
            throw KlarnaHelpers.getInvalidTokenError()
        }
        guard paymentMethod.id != nil else {
            throw KlarnaHelpers.getInvalidValueError(key: "configuration.id")
        }

        switch KlarnaHelpers.getSessionType() {
        case .oneOffPayment:
            try validateOneOffPayment()
        case .recurringPayment:
            break
        }
    }

    /// - Validates the necessary conditions specific to one-off payment operations.
    func validateOneOffPayment() throws {
        guard AppState.current.amount != nil else {
            throw KlarnaHelpers.getInvalidSettingError(name: "amount")
        }

        guard AppState.current.currency != nil else {
            throw KlarnaHelpers.getInvalidSettingError(name: "currency")
        }

        guard
            let lineItems = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.lineItems,
            !lineItems.isEmpty
        else {
            throw KlarnaHelpers.getInvalidSettingError(name: "lineItems")
        }

        guard !lineItems.contains(where: { $0.amount == nil }) else {
            throw KlarnaHelpers.getInvalidValueError(key: "settings.orderItems")
        }
    }
}

// MARK: - Create payment session

extension KlarnaTokenizationComponent {
    func createPaymentSession() async throws -> Response.Body.Klarna.PaymentSession {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw KlarnaHelpers.getInvalidTokenError()
        }

        guard let paymentMethodConfigId = paymentMethod.id else {
            throw handled(primerError: .unsupportedPaymentMethod(paymentMethodType: paymentMethod.type))
        }

        try await requestPrimerConfiguration(
            decodedJWTToken: decodedJWTToken,
            request: prepareKlarnaClientSessionActionsRequestBody()
        )

        return try await createKlarnaSession(
            with: prepareKlarnaPaymentSessionRequestBody(paymentMethodConfigId: paymentMethodConfigId),
            decodedJWTToken: decodedJWTToken
        )
    }
}

// MARK: - Authorize payment session

extension KlarnaTokenizationComponent {
    func authorizePaymentSession(authorizationToken: String) async throws -> Response.Body.Klarna.CustomerToken {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            throw KlarnaHelpers.getInvalidTokenError()
        }

        guard let paymentMethodConfigId = paymentMethod.id else {
            throw handled(primerError: .unsupportedPaymentMethod(paymentMethodType: paymentMethod.type))
        }

        guard let paymentSessionId else {
            throw handled(primerError: .invalidValue(key: "paymentSessionId"))
        }

        switch KlarnaHelpers.getSessionType() {
        case .oneOffPayment:
            return try await finalizeKlarnaPaymentSession(
                with: decodedJWTToken,
                body: prepareKlarnaFinalizePaymentSessionBody(
                    paymentMethodConfigId: paymentMethodConfigId,
                    sessionId: paymentSessionId
                )
            )
        case .recurringPayment:
            return try await createKlarnaCustomerToken(
                with: decodedJWTToken,
                body: prepareKlarnaCustomerTokenBody(
                    paymentMethodConfigId: paymentMethodConfigId,
                    sessionId: paymentSessionId,
                    authorizationToken: authorizationToken
                )
            )
        }
    }
}

// MARK: - Klarna Creation helpers

private extension KlarnaTokenizationComponent {
    /// - Helper method to prepare Klarna Payment Session request body
    private func prepareKlarnaPaymentSessionRequestBody(paymentMethodConfigId: String) -> Request.Body.Klarna.CreatePaymentSession {
        let urlScheme = (try? settings.paymentMethodOptions.validUrlForUrlScheme())?.absoluteString
        return KlarnaHelpers.getKlarnaPaymentSessionBody(
            with: paymentMethodConfigId,
            clientSession: PrimerAPIConfigurationModule.apiConfiguration?.clientSession,
            recurringPaymentDescription: recurringPaymentDescription,
            redirectUrl: urlScheme
        )
    }

    /// - Helper method to prepare Client Session Update Request body with actions
    private func prepareKlarnaClientSessionActionsRequestBody() -> ClientSessionUpdateRequest {
        let params: [String: Any] = ["paymentMethodType": paymentMethod.type]
        let actions = [ClientSession.Action.selectPaymentMethodActionWithParameters(params)]
        return ClientSessionUpdateRequest(actions: ClientSessionAction(actions: actions))
    }

    /// - Request to update Primer Configuration with actions
    /// - Sets the client session with updated primer configuration request data
    private func requestPrimerConfiguration(
        decodedJWTToken: DecodedJWTToken,
        request: ClientSessionUpdateRequest
    ) async throws {
        let (configuration, _) = try await apiClient.requestPrimerConfigurationWithActions(
            clientToken: decodedJWTToken,
            request: request
        )
        PrimerAPIConfigurationModule.apiConfiguration?.clientSession = configuration.clientSession
    }

    /// - Request to create  Klarna Payment Session
    /// - Sets the 'paymentSessionId'  with response's 'sessionId'
    private func createKlarnaSession(with body: Request.Body.Klarna.CreatePaymentSession,
                                     decodedJWTToken: DecodedJWTToken) async throws -> Response.Body.Klarna.PaymentSession {
        let response = try await apiClient.createKlarnaPaymentSession(
            clientToken: decodedJWTToken,
            klarnaCreatePaymentSessionAPIRequest: body
        )
        paymentSessionId = response.sessionId
        return response
    }
}

// MARK: - Klarna Authorization helpers

extension KlarnaTokenizationComponent {
    /// - Helper method to prepare Klarna Finalize Payment Session body
    private func prepareKlarnaFinalizePaymentSessionBody(paymentMethodConfigId: String, sessionId: String) -> Request.Body.Klarna.FinalizePaymentSession {
        KlarnaHelpers.getKlarnaFinalizePaymentBody(
            with: paymentMethodConfigId,
            sessionId: sessionId
        )
    }

    /// - Request to finalize  Klarna Payment Session
    private func finalizeKlarnaPaymentSession(
        with clientToken: DecodedJWTToken,
        body: Request.Body.Klarna.FinalizePaymentSession
    ) async throws -> Response.Body.Klarna.CustomerToken {
        try await apiClient.finalizeKlarnaPaymentSession(
            clientToken: clientToken,
            klarnaFinalizePaymentSessionRequest: body
        )
    }

    /// - Helper method to prepare Klarna Customer Token body
    private func prepareKlarnaCustomerTokenBody(paymentMethodConfigId: String, sessionId: String, authorizationToken: String) -> Request.Body.Klarna.CreateCustomerToken {
        KlarnaHelpers.getKlarnaCustomerTokenBody(
            with: paymentMethodConfigId,
            sessionId: sessionId,
            authorizationToken: authorizationToken,
            recurringPaymentDescription: recurringPaymentDescription
        )
    }

    /// - Request to create  Klarna Customer Token
    private func createKlarnaCustomerToken(
        with clientToken: DecodedJWTToken,
        body: Request.Body.Klarna.CreateCustomerToken
    ) async throws -> Response.Body.Klarna.CustomerToken {
        try await apiClient.createKlarnaCustomerToken(
            clientToken: clientToken,
            klarnaCreateCustomerTokenAPIRequest: body
        )
    }
}

// MARK: - Klarna Testing helpers

extension KlarnaTokenizationComponent {
    func setSessionId(paymentSessionId: String) {
        self.paymentSessionId = paymentSessionId
    }
}
