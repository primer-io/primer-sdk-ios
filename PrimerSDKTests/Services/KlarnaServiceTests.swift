//
//  KlarnaServiceTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 22/02/2021.
//

import XCTest
@testable import PrimerSDK

class KlarnaServiceTests: XCTestCase {
    
    var throwsError = false
    var error: KlarnaException?
    var redirectUrl: String?
    
    override func setUp() {
        throwsError = false
        error = nil
        redirectUrl = nil
        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
    }
    
    // MARK: createPaymentSession - success
    func test_create_order_session_success() throws {
        let response = KlarnaCreatePaymentSessionAPIResponse(sessionId: "id", redirectUrl: "https://primer.io/")
        let data = try JSONEncoder().encode(response)
        let api = MockAPIClient(with: data, throwsError: false)
        DependencyContainer.register(api as APIClientProtocol)
        
        let service = KlarnaService()
        
        service.createPaymentSession({ [weak self] result in
            switch result {
            case .failure(let err): self?.throwsError = true; self?.error = err as? KlarnaException
            case .success(let url): self?.redirectUrl = url
            }
        })
        
        XCTAssertEqual(api.postCalled, true)
        XCTAssertEqual(throwsError, false)
        XCTAssertEqual(error, nil)
        XCTAssertEqual(redirectUrl, response.redirectUrl)
    }
    
    // MARK: createPaymentSession - fail, api exception
    func test_create_order_session_fail_invalid_response() throws {
        let response = KlarnaCreatePaymentSessionAPIResponse(sessionId: "id", redirectUrl: "https://primer.io/")
        let data = try JSONEncoder().encode(response)
        let api = MockAPIClient(with: data, throwsError: true)
        DependencyContainer.register(api as APIClientProtocol)
        
        let service = KlarnaService()
        
        service.createPaymentSession({ [weak self] result in
            switch result {
            case .failure(let err): self?.throwsError = true; self?.error = err as? KlarnaException
            case .success(let url): self?.redirectUrl = url
            }
        })
        
        XCTAssertEqual(api.postCalled, true)
        XCTAssertEqual(throwsError, true)
        XCTAssertEqual(error, KlarnaException.failedApiCall)
        XCTAssertEqual(redirectUrl, nil)
    }
    
    // MARK: createPaymentSession - fail, no client token
    func test_create_order_session_fail_no_client_token() throws {
        let state = MockAppState(decodedClientToken: nil)
        DependencyContainer.register(state as AppStateProtocol)
        
        let api = MockAPIClient()
        DependencyContainer.register(api as APIClientProtocol)
        
        let service = KlarnaService()
        
        service.createPaymentSession({ [weak self] result in
            switch result {
            case .failure(let err): self?.throwsError = true; self?.error = err as? KlarnaException
            case .success(let url): self?.redirectUrl = url
            }
        })
        
        XCTAssertEqual(api.postCalled, false)
        XCTAssertEqual(throwsError, true)
        XCTAssertEqual(error, KlarnaException.noToken)
        XCTAssertEqual(redirectUrl, nil)
    }
}
