//
//  TokenizationService.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockTokenizationService: TokenizationServiceProtocol {
    var tokenizedPaymentMethodToken: PaymentMethodToken?
    
    var paymentInstrumentType: String
    var tokenType: String
    var tokenizeCalled = false
    lazy var paymentMethodTokenJSON: [String: Any] = [
        "token": "payment_method_token",
        "analyticsId": "analytics_id",
        "tokenType":  tokenType,
        "paymentInstrumentType": paymentInstrumentType
    ]
    
    init(paymentInstrumentType: String, tokenType: String) {
        self.paymentInstrumentType = paymentInstrumentType
        self.tokenType = tokenType
    }

    func tokenize(request: PaymentMethodTokenizationRequest, onTokenizeSuccess: @escaping (Result<PaymentMethodToken, PrimerError>) -> Void) {
        tokenizeCalled = true
        
        let paymentMethodTokenData = try! JSONSerialization.data(withJSONObject: paymentMethodTokenJSON, options: .fragmentsAllowed)
        let token = try! JSONParser().parse(PaymentMethodToken.self, from: paymentMethodTokenData) //PaymentMethodToken(token: "tokenID", paymentInstrumentType: .paymentCard, vaultData: VaultData())
        return onTokenizeSuccess(.success(token))
    }
}

#endif
