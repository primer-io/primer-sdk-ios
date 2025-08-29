//
//  TokenizationService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable function_body_length

import Foundation

internal protocol TokenizationServiceProtocol {
    var paymentMethodTokenData: PrimerPaymentMethodTokenData? { get set }
    func tokenize(requestBody: Request.Body.Tokenization) async throws -> PrimerPaymentMethodTokenData
    func exchangePaymentMethodToken(_ paymentMethodTokenId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?) async throws -> PrimerPaymentMethodTokenData
}

final class TokenizationService: TokenizationServiceProtocol, LogReporter {
    var paymentMethodTokenData: PrimerPaymentMethodTokenData?

    let apiClient: PrimerAPIClientProtocol

    init(apiClient: PrimerAPIClientProtocol = PrimerAPIClient()) {
        self.apiClient = apiClient
    }

    func tokenize(requestBody: Request.Body.Tokenization) async throws -> PrimerPaymentMethodTokenData {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken()
            ErrorHandler.handle(error: err)
            throw err
        }
        logger.debug(message: "Client Token: \(decodedJWTToken)")

        guard let pciURL = decodedJWTToken.pciUrl else {
            let err = PrimerError.invalidValue(
                key: "decodedClientToken.pciUrl",
                value: decodedJWTToken.pciUrl
            )
            ErrorHandler.handle(error: err)
            throw err
        }
        logger.debug(message: "PCI URL: \(pciURL)")

        guard let url = URL(string: "\(pciURL)/payment-instruments") else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", value: decodedJWTToken.pciUrl)
            ErrorHandler.handle(error: err)
            throw err
        }

        logger.debug(message: "URL: \(url)")

        let paymentMethodTokenData = try await apiClient.tokenizePaymentMethod(
            clientToken: decodedJWTToken,
            tokenizationRequestBody: requestBody
        )
        self.paymentMethodTokenData = paymentMethodTokenData
        return paymentMethodTokenData
    }

    @MainActor
    func exchangePaymentMethodToken(
        _ paymentMethodTokenId: String,
        vaultedPaymentMethodAdditionalData: (any PrimerVaultedPaymentMethodAdditionalData)?
    ) async throws -> PrimerPaymentMethodTokenData {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken()
            ErrorHandler.handle(error: err)
            throw err
        }

        return try await apiClient.exchangePaymentMethodToken(
            clientToken: decodedJWTToken,
            vaultedPaymentMethodId: paymentMethodTokenId,
            vaultedPaymentMethodAdditionalData: vaultedPaymentMethodAdditionalData
        )
    }
}
// swiftlint:enable function_body_length
