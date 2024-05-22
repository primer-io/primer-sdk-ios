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
            Promise.rejected(PrimerError.generic(message: "", userInfo: nil, diagnosticsId: ""))
    }

    // MARK: exchangePaymentMethodToken

    var onExchangePaymentMethodToken: ((String, PrimerVaultedPaymentMethodAdditionalData?) -> Promise<PrimerPaymentMethodTokenData>)?

    func exchangePaymentMethodToken(_ paymentMethodTokenId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?) -> Promise<PrimerPaymentMethodTokenData> {
        return onExchangePaymentMethodToken?(paymentMethodTokenId, vaultedPaymentMethodAdditionalData) ??
            Promise.rejected(PrimerError.generic(message: "", userInfo: nil, diagnosticsId: ""))
    }
}
