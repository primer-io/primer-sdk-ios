//
//  MockTokenizationService.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation
@testable import PrimerSDK

final class MockTokenizationService: TokenizationServiceProtocol {

    static var apiClient: (any PrimerSDK.PrimerAPIClientProtocol)?

    var paymentMethodTokenData: PrimerSDK.PrimerPaymentMethodTokenData?
    var onTokenize: ((Request.Body.Tokenization) -> Result<PrimerPaymentMethodTokenData, Error>)?
    var onExchangePaymentMethodToken: ((String, PrimerVaultedPaymentMethodAdditionalData?) -> Result<PrimerPaymentMethodTokenData, Error>)?

    // MARK: tokenize

    func tokenize(requestBody: Request.Body.Tokenization) async throws -> PrimerPaymentMethodTokenData {
        guard let onTokenize else {
            throw PrimerError.unknown()
        }
        switch onTokenize(requestBody) {
        case let .success(result): return result
        case let .failure(error): throw error
        }
    }

    // MARK: exchangePaymentMethodToken

    func exchangePaymentMethodToken(
        _ paymentMethodTokenId: String,
        vaultedPaymentMethodAdditionalData: (any PrimerVaultedPaymentMethodAdditionalData)?
    ) async throws -> PrimerPaymentMethodTokenData {
        switch onExchangePaymentMethodToken?(paymentMethodTokenId, vaultedPaymentMethodAdditionalData) {
        case let .success(result): return result
        case let .failure(error): throw error
        case nil: throw PrimerError.unknown()
        }
    }
}
