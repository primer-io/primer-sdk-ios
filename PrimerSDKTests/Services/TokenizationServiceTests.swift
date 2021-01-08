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
        
        let token = PaymentMethodToken(token: "token")
        var newToken = PaymentMethodToken()
        
        let data = try JSONEncoder().encode(token)
        
        let api = MockAPIClient(with: data, throwsError: false)
        
        let request = PaymentMethodTokenizationRequest(with: .CHECKOUT, and: "", and: PaymentInstrument())
        
        let service = TokenizationService(with: api)
        
        service.tokenize(with: mockClientToken, request: request, onTokenizeSuccess: { result in
            switch result {
            case .failure: print("error")
            case .success(let token): newToken.token = token.token
            }
        })
        
        XCTAssertEqual(api.postCalled, true)
        XCTAssertEqual(newToken.token, token.token)
    }
    
}
