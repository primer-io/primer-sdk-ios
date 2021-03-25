//
//  TokenizationServiceTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 07/01/2021.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class TokenizationServiceTests: XCTestCase {
    
    func test_tokenize_calls_api() throws {
        let expectation = XCTestExpectation(description: "Create PayPal payment sesion | Success")
        
        let mockedToken = PaymentMethodToken(token: "token", paymentInstrumentType: .paymentCard, vaultData: VaultData(customerId: "customerId"))
        let data = try JSONEncoder().encode(mockedToken)
        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState()
        
        let request = PaymentMethodTokenizationRequest(paymentInstrument: PaymentInstrument(), state: state)
        
        MockLocator.registerDependencies()
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        
        let service = TokenizationService()
        
        service.tokenize(request: request) { result in
            switch result {
            case .failure:
                XCTAssert(false, "Test should not get into the failure case.")
            case .success(let token):
                XCTAssertEqual(mockedToken.token, token.token)
            }
            
            expectation.fulfill()
        }
        
        XCTAssertEqual(api.isCalled, true)
        
        wait(for: [expectation], timeout: 10.0)
    }
    
}

#endif
