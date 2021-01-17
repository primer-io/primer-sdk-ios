//
//  TokenizationService.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

@testable import PrimerSDK

class MockTokenizationService: TokenizationServiceProtocol {
    
    var tokenizeCalled = false
    
    func tokenize(request: PaymentMethodTokenizationRequest, onTokenizeSuccess: @escaping (Result<PaymentMethodToken, Error>) -> Void) {
        tokenizeCalled = true
        let token = PaymentMethodToken(token: "tokenID", paymentInstrumentType: .PAYMENT_CARD)
        return onTokenizeSuccess(.success(token))
    }
}
