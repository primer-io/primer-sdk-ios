//
//  TokenizationService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable function_body_length

import Foundation

internal protocol TokenizationServiceProtocol {
    var paymentMethodTokenData: PrimerPaymentMethodTokenData? { get set }
    func tokenize(requestBody: Request.Body.Tokenization) -> Promise<PrimerPaymentMethodTokenData>
    func tokenize(requestBody: Request.Body.Tokenization) async throws -> PrimerPaymentMethodTokenData
    func exchangePaymentMethodToken(_ paymentMethodTokenId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?) -> Promise<PrimerPaymentMethodTokenData>
    func exchangePaymentMethodToken(_ paymentMethodTokenId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?) async throws -> PrimerPaymentMethodTokenData
}

final class TokenizationService: TokenizationServiceProtocol, LogReporter {
    var paymentMethodTokenData: PrimerPaymentMethodTokenData?

    let apiClient: PrimerAPIClientProtocol

    init(apiClient: PrimerAPIClientProtocol = PrimerAPIClient()) {
        self.apiClient = apiClient
    }

    func tokenize(requestBody: Request.Body.Tokenization) -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            self.logger.debug(message: "Client Token: \(decodedJWTToken)")
            guard let pciURL = decodedJWTToken.pciUrl else {
                let err = PrimerError.invalidValue(
                    key: "decodedClientToken.pciUrl",
                    value: decodedJWTToken.pciUrl,
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            self.logger.debug(message: "PCI URL: \(pciURL)")
            guard let url = URL(string: "\(pciURL)/payment-instruments") else {
                let err = PrimerError.invalidValue(
                    key: "decodedClientToken.pciUrl",
                    value: decodedJWTToken.pciUrl,
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            self.logger.debug(message: "URL: \(url)")
            self.apiClient.tokenizePaymentMethod(clientToken: decodedJWTToken, tokenizationRequestBody: requestBody) { (result) in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                case .success(let paymentMethodTokenData):
                    self.paymentMethodTokenData = paymentMethodTokenData
                    seal.fulfill(paymentMethodTokenData)
                }
            }
        }
    }

    func tokenize(requestBody: Request.Body.Tokenization) async throws -> PrimerPaymentMethodTokenData {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: err)
            throw err
        }
        logger.debug(message: "Client Token: \(decodedJWTToken)")

        guard let pciURL = decodedJWTToken.pciUrl else {
            let err = PrimerError.invalidValue(
                key: "decodedClientToken.pciUrl",
                value: decodedJWTToken.pciUrl,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
            ErrorHandler.handle(error: err)
            throw err
        }
        logger.debug(message: "PCI URL: \(pciURL)")

        guard let url = URL(string: "\(pciURL)/payment-instruments") else {
            let err = PrimerError.invalidValue(
                key: "decodedClientToken.pciUrl",
                value: decodedJWTToken.pciUrl,
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
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

    func exchangePaymentMethodToken( _ vaultedPaymentMethodId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?) -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            self.apiClient.exchangePaymentMethodToken(
                clientToken: decodedJWTToken,
                vaultedPaymentMethodId: vaultedPaymentMethodId,
                vaultedPaymentMethodAdditionalData: vaultedPaymentMethodAdditionalData) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let singleUsePaymentMethod):
                        seal.fulfill(singleUsePaymentMethod)
                    case .failure(let error):
                        seal.reject(error)
                    }
                }
            }
        }
    }

    @MainActor
    func exchangePaymentMethodToken(
        _ paymentMethodTokenId: String,
        vaultedPaymentMethodAdditionalData: (any PrimerVaultedPaymentMethodAdditionalData)?
    ) async throws -> PrimerPaymentMethodTokenData {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let err = PrimerError.invalidClientToken(
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString
            )
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
