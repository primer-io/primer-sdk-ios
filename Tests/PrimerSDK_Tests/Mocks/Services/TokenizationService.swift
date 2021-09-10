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
    let paymentMethodTokenJSON: String = """
        """

    func tokenize(request: PaymentMethodRequest, onTokenizeSuccess: @escaping (Result<PaymentMethod, PrimerError>) -> Void) {
        tokenizeCalled = true
        
        let paymentMethodTokenData = paymentMethodTokenJSON.data(using: .utf8)!
        let token = try! JSONParser().parse(PaymentMethod.self, from: paymentMethodTokenData)
        return onTokenizeSuccess(.success(token))
    }
}

#endif
