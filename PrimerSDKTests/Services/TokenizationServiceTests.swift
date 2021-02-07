//
//  TokenizationServiceTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 07/01/2021.
//

import XCTest
@testable import PrimerSDK

class TokenizationServiceTests: XCTestCase {
    
    func test_tokenize_calls_api_post() throws {
        
        let token = PaymentMethodToken(token: "token", paymentInstrumentType: .PAYMENT_CARD, vaultData: VaultData(customerId: "customerId"))
        var newToken = PaymentMethodToken(token: "", paymentInstrumentType: .UNKNOWN, vaultData: VaultData(customerId: ""))
        let data = try JSONEncoder().encode(token)
        let api = MockAPIClient(with: data, throwsError: false)
        let state = MockAppState()
        
        let request = PaymentMethodTokenizationRequest(paymentInstrument: PaymentInstrument(), state: state)
        
        MockLocator.registerDependencies()
        DependencyContainer.register(api as APIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        
        let service = TokenizationService()
        
        service.tokenize(request: request) { result in
            switch result {
            case .failure: print("error")
            case .success(let token): newToken.token = token.token
            }
        }
        
        XCTAssertEqual(api.postCalled, true)
        XCTAssertEqual(newToken.token, token.token)
    }
    
}
