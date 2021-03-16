//
//  PayPalServiceTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 17/01/2021.
//

import XCTest
@testable import PrimerSDK

class PayPalServiceTests: XCTestCase {
    
    // MARK: startOrderSession
    func test_startOrderSession_calls_api_post() throws {
        let response = PayPalCreateOrderResponse(orderId: "oid", approvalUrl: "primer.io")
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState()
        
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        
        let service = PayPalService()
        
        var throwsError = false
        var approvalUrl = ""
        
        service.startOrderSession({ result in
            switch result {
            case .failure: throwsError = true
            case .success(let url): approvalUrl = url
            }
        })
        
        XCTAssertEqual(api.postCalled, true)
        XCTAssertEqual(throwsError, false)
        XCTAssertEqual(approvalUrl, response.approvalUrl)
    }
    
    func test_startOrderSession_fails_if_client_token_nil() throws {
        let response = PayPalCreateOrderResponse(orderId: "oid", approvalUrl: "primer.io")
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState(decodedClientToken: nil)
        
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        
        let service = PayPalService()
        
        var throwsError = false
        var approvalUrl = ""
        
        service.startOrderSession({ result in
            switch result {
            case .failure: throwsError = true
            case .success(let url): approvalUrl = url
            }
        })
        
        XCTAssertEqual(api.postCalled, false)
        XCTAssertEqual(throwsError, true)
        XCTAssertEqual(approvalUrl, "")
    }
    
    func test_startOrderSession_fails_if_configId_nil() throws {
        let response = PayPalCreateOrderResponse(orderId: "oid", approvalUrl: "primer.io")
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState(paymentMethodConfig: nil)
        
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        
        let service = PayPalService()
        
        var throwsError = false
        var approvalUrl = ""
        
        service.startOrderSession({ result in
            switch result {
            case .failure: throwsError = true
            case .success(let url): approvalUrl = url
            }
        })
        
        XCTAssertEqual(api.postCalled, false)
        XCTAssertEqual(throwsError, true)
        XCTAssertEqual(approvalUrl, "")
    }
    
    // MARK: startBillingAgreementSession
    func test_startBillingAgreementSession_calls_api_post() throws {
        let response = PayPalCreateBillingAgreementResponse(tokenId: "tid", approvalUrl: "https://primer.io")
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState()
        
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        
        let service = PayPalService()
        
        var throwsError = false
        var approvalUrl = ""
        
        service.startBillingAgreementSession({ result in
            switch result {
            case .failure: throwsError = true
            case .success(let url): approvalUrl = url
            }
        })
        
        XCTAssertEqual(api.postCalled, true)
        XCTAssertEqual(throwsError, false)
        XCTAssertEqual(approvalUrl, response.approvalUrl)
    }
    
    func test_startBillingAgreementSession_fails_if_client_token_nil() throws {
        let response = PayPalCreateBillingAgreementResponse(tokenId: "tid", approvalUrl: "https://primer.io")
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState(decodedClientToken: nil)
        
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        
        let service = PayPalService()
        
        var throwsError = false
        var approvalUrl = ""
        
        service.startBillingAgreementSession({ result in
            switch result {
            case .failure: throwsError = true
            case .success(let url): approvalUrl = url
            }
        })
        
        XCTAssertEqual(api.postCalled, false)
        XCTAssertEqual(throwsError, true)
        XCTAssertEqual(approvalUrl, "")
    }
    
    func test_startBillingAgreementSession_fails_if_configId_nil() throws {
        let response = PayPalCreateBillingAgreementResponse(tokenId: "tid", approvalUrl: "https://primer.io")
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState(paymentMethodConfig: nil)
        
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        
        let service = PayPalService()
        
        var throwsError = false
        var approvalUrl = ""
        
        service.startBillingAgreementSession({ result in
            switch result {
            case .failure: throwsError = true
            case .success(let url): approvalUrl = url
            }
        })
        
        XCTAssertEqual(api.postCalled, false)
        XCTAssertEqual(throwsError, true)
        XCTAssertEqual(approvalUrl, "")
    }
    
    // MARK: confirmBillingAgreement
    func test_confirmBillingAgreement_calls_api_post() throws {
        let response = mockPayPalBillingAgreement
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState()
        
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        
        let service = PayPalService()
        
        var throwsError = false
        var billingAgreementId = ""
        
        service.confirmBillingAgreement({ result in
            switch result {
            case .failure: throwsError = true
            case .success(let res): billingAgreementId = res.billingAgreementId
            }
        })
        
        XCTAssertEqual(api.postCalled, true)
        XCTAssertEqual(throwsError, false)
        XCTAssertEqual(billingAgreementId, response.billingAgreementId)
    }
    
    func test_confirmBillingAgreement_fails_if_client_token_nil() throws {
        let response = mockPayPalBillingAgreement
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState(decodedClientToken: nil)
        
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        
        let service = PayPalService()
        
        var throwsError = false
        var billingAgreementId = ""
        
        service.confirmBillingAgreement({ result in
            switch result {
            case .failure: throwsError = true
            case .success(let res): billingAgreementId = res.billingAgreementId
            }
        })
        
        XCTAssertEqual(api.postCalled, false)
        XCTAssertEqual(throwsError, true)
        XCTAssertEqual(billingAgreementId, "")
    }
    
    func test_confirmBillingAgreement_fails_if_configId_nil() throws {
        let response = mockPayPalBillingAgreement
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState(paymentMethodConfig: nil)
        
        MockLocator.registerDependencies()
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        
        let service = PayPalService()
        
        var throwsError = false
        var billingAgreementId = ""
        
        service.confirmBillingAgreement({ result in
            switch result {
            case .failure: throwsError = true
            case .success(let res): billingAgreementId = res.billingAgreementId
            }
        })
        
        XCTAssertEqual(api.postCalled, false)
        XCTAssertEqual(throwsError, true)
        XCTAssertEqual(billingAgreementId, "")
    }
}
