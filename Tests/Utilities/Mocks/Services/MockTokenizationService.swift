import Foundation
@testable import PrimerSDK

final class MockTokenizationService: TokenizationServiceProtocol {

    static var apiClient: (any PrimerSDK.PrimerAPIClientProtocol)?

    var paymentMethodTokenData: PrimerSDK.PrimerPaymentMethodTokenData?
    var onTokenize: ((Request.Body.Tokenization) -> PrimerPaymentMethodTokenData)?
    var onExchangePaymentMethodToken: ((String, PrimerVaultedPaymentMethodAdditionalData?) -> PrimerPaymentMethodTokenData)?

    // MARK: tokenize
    
    func tokenize(requestBody: Request.Body.Tokenization) -> Promise<PrimerPaymentMethodTokenData> {
        guard let onTokenize else {
            return Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
        }
        return Promise.fulfilled(onTokenize(requestBody))
    }

    func tokenize(requestBody: Request.Body.Tokenization) async throws -> PrimerPaymentMethodTokenData {
        guard let onTokenize else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
        return onTokenize(requestBody)
    }

    // MARK: exchangePaymentMethodToken

    func exchangePaymentMethodToken(_ paymentMethodTokenId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?) -> Promise<PrimerPaymentMethodTokenData> {
        guard let onExchangePaymentMethodToken else {
            return Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
        }
        return Promise.fulfilled(onExchangePaymentMethodToken(paymentMethodTokenId, vaultedPaymentMethodAdditionalData))
    }

    func exchangePaymentMethodToken(
        _ paymentMethodTokenId: String,
        vaultedPaymentMethodAdditionalData: (any PrimerVaultedPaymentMethodAdditionalData)?
    ) async throws -> PrimerPaymentMethodTokenData {
        guard let onExchangePaymentMethodToken else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }
        return onExchangePaymentMethodToken(paymentMethodTokenId, vaultedPaymentMethodAdditionalData)
    }
}
