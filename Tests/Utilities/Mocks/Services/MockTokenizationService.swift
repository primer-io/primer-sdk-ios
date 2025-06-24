//
//  TokenizationService.swift
//  PrimerSDKTests
//
//  Created by Jack Newcombe on 22/05/2024.
//

import Foundation
@testable import PrimerSDK

class MockTokenizationService: TokenizationServiceProtocol {

    static var apiClient: (any PrimerSDK.PrimerAPIClientProtocol)?

    var paymentMethodTokenData: PrimerSDK.PrimerPaymentMethodTokenData?

    // MARK: tokenize

    var onTokenize: ((Request.Body.Tokenization) -> Promise<PrimerPaymentMethodTokenData>)?

    func tokenize(requestBody: Request.Body.Tokenization) -> Promise<PrimerPaymentMethodTokenData> {
        return onTokenize?(requestBody) ??
            Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
    }

    func tokenize(requestBody: Request.Body.Tokenization) async throws -> PrimerPaymentMethodTokenData {
        return try await withCheckedThrowingContinuation { continuation in
            firstly {
                onTokenize?(requestBody) ?? Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
            }
            .done { paymentMethodTokenData in
                continuation.resume(returning: paymentMethodTokenData)
            }
            .catch { error in
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: exchangePaymentMethodToken

    var onExchangePaymentMethodToken: ((String, PrimerVaultedPaymentMethodAdditionalData?) -> Promise<PrimerPaymentMethodTokenData>)?

    func exchangePaymentMethodToken(_ paymentMethodTokenId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?) -> Promise<PrimerPaymentMethodTokenData> {
        return onExchangePaymentMethodToken?(paymentMethodTokenId, vaultedPaymentMethodAdditionalData) ??
            Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
    }

    func exchangePaymentMethodToken(
        _ paymentMethodTokenId: String,
        vaultedPaymentMethodAdditionalData: (any PrimerVaultedPaymentMethodAdditionalData)?
    ) async throws -> PrimerPaymentMethodTokenData {
        return try await withCheckedThrowingContinuation { continuation in
            firstly {
                onExchangePaymentMethodToken?(paymentMethodTokenId, vaultedPaymentMethodAdditionalData) ??
                    Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
            }
            .done { paymentMethodTokenData in
                continuation.resume(returning: paymentMethodTokenData)
            }
            .catch { error in
                continuation.resume(throwing: error)
            }
        }
    }
}
