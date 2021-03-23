//
//  KlarnaServiceTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 22/02/2021.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class KlarnaServiceTests: XCTestCase {
    
    override func setUp() {
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
    }
    
    // MARK: createPaymentSession - success
    func test_create_order_session_success() throws {
        let expectation = XCTestExpectation(description: "Create Klarna payment sesion | Success")
        
        let response = KlarnaCreatePaymentSessionAPIResponse(clientToken: "token", sessionId: "id", categories: [], hppSessionId: "hppSessionId", hppRedirectUrl: "https://primer.io/")
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        
        let service = KlarnaService()
        
        service.createPaymentSession({ result in
            switch result {
            case .failure:
                XCTAssert(false, "Test should not get into the failure case.")
            case .success(let url):
                XCTAssertEqual(url, response.hppRedirectUrl)
            }
            
            expectation.fulfill()
        })
        
        XCTAssertEqual(api.isCalled, true)
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: createPaymentSession - fail, api exception
    func test_create_order_session_fail_invalid_response() throws {
        let expectation = XCTestExpectation(description: "Create Klarna payment sesion | Failure: API call failed")
        
        let response = KlarnaCreatePaymentSessionAPIResponse(clientToken: "token", sessionId: "id", categories: [], hppSessionId: "hppSessionId", hppRedirectUrl: "https://primer.io/")
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: true)
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        
        let service = KlarnaService()
        
        service.createPaymentSession({ result in
            switch result {
            case .failure(let err):
                XCTAssertEqual(err as? KlarnaException, KlarnaException.failedApiCall)
            case .success:
                XCTAssert(false, "Test should get into the success case.")
            }
            
            expectation.fulfill()
        })
        
        XCTAssertEqual(api.isCalled, true)
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: createPaymentSession - fail, no client token
    func test_create_order_session_fail_no_client_token() throws {
        let expectation = XCTestExpectation(description: "Create Klarna payment sesion | Failure: No token")
        
        let state = MockAppState(decodedClientToken: nil)
        DependencyContainer.register(state as AppStateProtocol)
        
        let api = MockPrimerAPIClient()
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        
        let service = KlarnaService()
        
        service.createPaymentSession({ result in
            switch result {
            case .failure(let err):
                XCTAssertEqual(err as? KlarnaException, KlarnaException.noToken)
            case .success:
                XCTAssert(false, "Test should get into the failure case.")
            }
            expectation.fulfill()
        })
        
        // Since no token is found, API call shouldn't be performed.
        XCTAssertEqual(api.isCalled, false)
        
        wait(for: [expectation], timeout: 10.0)
    }
}

#endif
