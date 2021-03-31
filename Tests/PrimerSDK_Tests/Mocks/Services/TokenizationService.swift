//
//  TokenizationService.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockTokenizationService: TokenizationServiceProtocol {
    var tokenizeCalled = false
    
    func tokenize(request: PaymentMethodTokenizationRequest, onTokenizeSuccess: @escaping (Result<PaymentMethodToken, PrimerError>) -> Void) {
        tokenizeCalled = true
        let token = PaymentMethodToken(token: "tokenID", paymentInstrumentType: .paymentCard, vaultData: VaultData())
        return onTokenizeSuccess(.success(token))
    }
}

#endif
