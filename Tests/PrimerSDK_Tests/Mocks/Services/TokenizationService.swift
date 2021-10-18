//
//  TokenizationService.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

#if canImport(UIKit)

@testable import PrimerSDK

class MockTokenizationService: TokenizationServiceProtocol {
    
    var paymentMethod: PaymentMethod?
    
    var paymentInstrumentType: String
    var tokenType: String
    var tokenizeCalled = false
    lazy var paymentMethodJSON: [String: Any] = [
        "token": "payment_method_token",
        "analyticsId": "analytics_id",
        "tokenType":  tokenType,
        "paymentInstrumentType": paymentInstrumentType
    ]
    
    init(paymentInstrumentType: String, tokenType: String) {
        self.paymentInstrumentType = paymentInstrumentType
        self.tokenType = tokenType
    }

    func tokenize(request: TokenizationRequest, onTokenizeSuccess: @escaping (Result<PaymentMethod, PrimerError>) -> Void) {
        tokenizeCalled = true
        
        let paymentMethodData = try! JSONSerialization.data(withJSONObject: paymentMethodJSON, options: .fragmentsAllowed)
        self.paymentMethod = try! JSONParser().parse(PaymentMethod.self, from: paymentMethodData) //PaymentMethodToken(token: "tokenID", paymentInstrumentType: .paymentCard, vaultData: VaultData())
        return onTokenizeSuccess(.success(self.paymentMethod!))
    }
    
    func tokenize(request: TokenizationRequest) -> Promise<PaymentMethod> {
        return Promise { seal in
            self.tokenize(request: request) { result in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                case .success(let res):
                    seal.fulfill(res)
                }
            }
        }
    }
}

#endif
