//
//  MockTokenizationService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

final class MockTokenizationService: TokenizationServiceProtocol {

    static var apiClient: (any PrimerSDK.PrimerAPIClientProtocol)?

    var paymentMethodTokenData: PrimerSDK.PrimerPaymentMethodTokenData?
    var onTokenize: ((Request.Body.Tokenization) -> Result<PrimerPaymentMethodTokenData, Error>)?
    var onExchangePaymentMethodToken: ((String, PrimerVaultedPaymentMethodAdditionalData?) -> Result<PrimerPaymentMethodTokenData, Error>)?

    // MARK: tokenize
    
    func tokenize(requestBody: Request.Body.Tokenization) -> Promise<PrimerPaymentMethodTokenData> {
        guard let onTokenize else {
            return Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
        }
        switch onTokenize(requestBody) {
        case .success(let result): return .fulfilled(result)
        case .failure(let error): return .rejected(error)
        }
    }

    func tokenize(requestBody: Request.Body.Tokenization) async throws -> PrimerPaymentMethodTokenData {
        guard let onTokenize else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
        switch onTokenize(requestBody) {
        case .success(let result): return result
        case .failure(let error): throw error
        }
    }

    // MARK: exchangePaymentMethodToken

    func exchangePaymentMethodToken(_ paymentMethodTokenId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?) -> Promise<PrimerPaymentMethodTokenData> {
        switch onExchangePaymentMethodToken?(paymentMethodTokenId, vaultedPaymentMethodAdditionalData) {
        case .success(let result): .fulfilled(result)
        case .failure(let error): .rejected(error)
        case nil: .rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
        }
    }

    func exchangePaymentMethodToken(
        _ paymentMethodTokenId: String,
        vaultedPaymentMethodAdditionalData: (any PrimerVaultedPaymentMethodAdditionalData)?
    ) async throws -> PrimerPaymentMethodTokenData {
        switch onExchangePaymentMethodToken?(paymentMethodTokenId, vaultedPaymentMethodAdditionalData) {
        case .success(let result): return result
        case .failure(let error): throw error
        case nil: throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
    }
}
