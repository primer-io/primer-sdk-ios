//
//  KlarnaTokenizationManager.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerNetworking

protocol KlarnaTokenizationManagerProtocol {
    /**
     Tokenizes the payment information for a customer using Klarna's payment service.
     - Parameters:
     - customerToken: An optional `Response.Body.Klarna.CustomerToken` object containing the customer's token and session data.
     - `offSessionAuthorizationId`: An optional `String` representing an off-session authorization ID. This is used when the session `intent` is `checkout`.

     - Returns: A `PrimerPaymentMethodTokenData` object on successful tokenization or throws an `Error` if the tokenization process fails.
     */
    func tokenizeHeadless(customerToken: Response.Body.Klarna.CustomerToken?, offSessionAuthorizationId: String?) async throws -> PrimerCheckoutData
    func tokenizeDropIn(customerToken: Response.Body.Klarna.CustomerToken?, offSessionAuthorizationId: String?) async throws -> PrimerPaymentMethodTokenData
}

class KlarnaTokenizationManager: KlarnaTokenizationManagerProtocol {
    // MARK: - Properties

    private let tokenizationService: TokenizationServiceProtocol

    private let createResumePaymentService: CreateResumePaymentServiceProtocol

    // MARK: - Init

    init(
        tokenizationService: TokenizationServiceProtocol,
        createResumePaymentService: CreateResumePaymentServiceProtocol
    ) {
        self.tokenizationService = tokenizationService
        self.createResumePaymentService = createResumePaymentService
    }

    // MARK: - Tokenize Headless

    func tokenizeHeadless(
        customerToken: Response.Body.Klarna.CustomerToken?,
        offSessionAuthorizationId: String?
    ) async throws -> PrimerCheckoutData {
        await PrimerDelegateProxy.primerHeadlessUniversalCheckoutDidStartTokenization(for: PrimerPaymentMethodType.klarna.rawValue)

        let requestBody = try await getRequestBody(
            customerToken: customerToken,
            offSessionAuthorizationId: offSessionAuthorizationId
        )
        let paymentMethodTokenData = try await tokenizationService.tokenize(requestBody: requestBody)
        return try await startPaymentFlow(withPaymentMethodTokenData: paymentMethodTokenData)
    }

    // MARK: - Tokenize DropIn

    func tokenizeDropIn(
        customerToken: Response.Body.Klarna.CustomerToken?,
        offSessionAuthorizationId: String?
    ) async throws -> PrimerPaymentMethodTokenData {
        let requestBody = try await getRequestBody(
            customerToken: customerToken,
            offSessionAuthorizationId: offSessionAuthorizationId
        )
        return try await tokenizationService.tokenize(requestBody: requestBody)
    }
}

extension KlarnaTokenizationManager {
    func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> PrimerCheckoutData {
        if PrimerSettings.current.paymentHandling == .manual {
            try await startManualPaymentFlow(withPaymentMethodTokenData: paymentMethodTokenData)
        } else {
            try await startAutomaticPaymentFlow(withPaymentMethodTokenData: paymentMethodTokenData)
        }
    }

    func startManualPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) async throws -> PrimerCheckoutData {
        let resumeDecision = await PrimerDelegateProxy.primerDidTokenizePaymentMethod(paymentMethodTokenData)

        if let resumeDecisionType = resumeDecision.type as? PrimerHeadlessUniversalCheckoutResumeDecision.DecisionType {
            switch resumeDecisionType {
            case .continueWithNewClientToken:
                preconditionFailure()
            case .complete:
                return PrimerCheckoutData(payment: nil)
            }
        } else {
            throw KlarnaHelpers.getPaymentFailedError()
        }
    }

    func startAutomaticPaymentFlow(
        withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData
    ) async throws -> PrimerCheckoutData {
        guard let token = paymentMethodTokenData.token else {
            throw KlarnaHelpers.getInvalidTokenError()
        }
        let paymentResponse = try await createPaymentEvent(token)
        return PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
    }

    private func createPaymentEvent(_ paymentMethodData: String) async throws -> Response.Body.Payment {
        try await createResumePaymentService.createPayment(
            paymentRequest: Request.Body.Payment.Create(token: paymentMethodData)
        )
    }

    private func getRequestBody(
        customerToken: Response.Body.Klarna.CustomerToken?,
        offSessionAuthorizationId: String?
    ) async throws -> Request.Body.Tokenization {
        guard let sessionData = customerToken?.sessionData else {
            throw KlarnaHelpers.getInvalidValueError(key: "tokenization.sessionData")
        }

        let paymentInstrument: TokenizationRequestBodyPaymentInstrument

        if KlarnaHelpers.getSessionType() == .recurringPayment {
            guard let klarnaCustomerToken = customerToken?.customerTokenId else {
                throw KlarnaHelpers.getInvalidValueError(key: "tokenization.customerToken")
            }
            paymentInstrument = KlarnaCustomerTokenPaymentInstrument(klarnaCustomerToken: klarnaCustomerToken, sessionData: sessionData)
        } else {
            paymentInstrument = KlarnaAuthorizationPaymentInstrument(klarnaAuthorizationToken: offSessionAuthorizationId, sessionData: sessionData)
        }

        return Request.Body.Tokenization(paymentInstrument: paymentInstrument)
    }
}
