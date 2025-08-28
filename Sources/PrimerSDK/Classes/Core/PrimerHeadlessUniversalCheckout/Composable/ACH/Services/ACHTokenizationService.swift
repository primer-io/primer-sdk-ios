//
//  ACHTokenizationService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/**
 * Protocol for tokenization process regarding an ACH payment.
 *
 * - Returns: A `PrimerPaymentMethodTokenData` object on successful tokenization or throws an `Error` if the tokenization process fails.
 */
protocol ACHTokenizationDelegate: AnyObject {
    func tokenize() async throws -> PrimerPaymentMethodTokenData
}

/**
 * Validation method to ensure data integrity before proceeding with tokenization.
 */
protocol ACHValidationDelegate: AnyObject {
    func validate() throws
}

final class ACHTokenizationService: ACHTokenizationDelegate, ACHValidationDelegate {
    // MARK: - Properties
    private let tokenizationService: TokenizationServiceProtocol
    private let paymentMethod: PrimerPaymentMethod
    private var clientSession: ClientSession.APIResponse?

    // MARK: - Init
    init(paymentMethod: PrimerPaymentMethod, tokenizationService: TokenizationServiceProtocol = TokenizationService()) {
        self.paymentMethod = paymentMethod
        self.tokenizationService = tokenizationService
        self.clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession
    }

    // MARK: - Tokenize

    func tokenize() async throws -> PrimerPaymentMethodTokenData {
        // Ensure the payment method has a valid ID
        guard paymentMethod.id != nil else {
            throw ACHHelpers.getInvalidValueError(key: "configuration.id", value: paymentMethod.id)
        }

        let requestBody = try await getRequestBody()
        return try await tokenizationService.tokenize(requestBody: requestBody)
    }

    // MARK: - Validation
    func validate() throws {
        guard
            let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken,
            decodedJWTToken.isValid,
            decodedJWTToken.pciUrl != nil
        else {
            throw ACHHelpers.getInvalidTokenError()
        }

        guard paymentMethod.id != nil else {
            throw ACHHelpers.getInvalidValueError(
                key: "configuration.id",
                value: paymentMethod.id
            )
        }

        if AppState.current.amount == nil {
            throw ACHHelpers.getInvalidSettingError(name: "amount")
        }

        if AppState.current.currency == nil {
            throw ACHHelpers.getInvalidSettingError(name: "currency")
        }

        let lineItems = clientSession?.order?.lineItems ?? []
        if lineItems.isEmpty {
            throw ACHHelpers.getInvalidValueError(key: "lineItems")
        }

        if !(lineItems.filter({ $0.amount == nil })).isEmpty {
            throw ACHHelpers.getInvalidValueError(key: "settings.orderItems")
        }

        guard let publishableKey = PrimerSettings.current.paymentMethodOptions.stripeOptions?.publishableKey,
              !publishableKey.isEmpty
        else {
            throw ACHHelpers.getInvalidValueError(key: "stripeOptions.publishableKey")
        }

        do {
            _ = try PrimerSettings.current.paymentMethodOptions.validSchemeForUrlScheme()
        } catch let error {
            throw error
        }
    }
}

/**
 * Constructs a tokenization request body for an ACH tokenize method.
 *
 * This private function generates the necessary payload for tokenization by assembling data related to
 * the payment method and additional session information.
 *
 * - Returns: A `Request.Body.Tokenization` containing the payment instrument data.
 */
extension ACHTokenizationService {
    private func getRequestBody() async throws -> Request.Body.Tokenization {
        guard let paymentInstrument = ACHHelpers.getACHPaymentInstrument(paymentMethod: paymentMethod) else {
            throw ACHHelpers.getInvalidValueError(
                key: "configuration.type",
                value: paymentMethod.type
            )
        }

        return Request.Body.Tokenization(paymentInstrument: paymentInstrument)
    }
}
