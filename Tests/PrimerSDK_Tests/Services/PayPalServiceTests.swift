//
//  PayPalServiceTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 17/01/2021.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class PayPalServiceTests: XCTestCase {

    // MARK: startOrderSession
    func test_startOrderSession_calls_api() throws {
        let expectation = XCTestExpectation(description: "Create PayPal payment sesion | Success")
        let approvalUrl = "https://primer.io"
        let response = PaymentMethod.PayPal.CreateOrder.Response(orderId: "oid", approvalUrl: approvalUrl)
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState()

        DependencyContainer.register(api as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)

        let service = PayPalService()

        service.startOrderSession({ result in
            switch result {
            case .failure:
                XCTAssert(false, "Test should not get into the failure case.")
            case .success(let res):
                XCTAssertEqual(res.approvalUrl, approvalUrl)
            }

            expectation.fulfill()
        })

        XCTAssertEqual(api.isCalled, true)

        wait(for: [expectation], timeout: 30.0)
    }

    func test_startOrderSession_fails_if_client_token_nil() throws {
        let expectation = XCTestExpectation(description: "Create PayPal payment sesion | Failure: No client token")

        let response = PaymentMethod.PayPal.CreateOrder.Response(orderId: "oid", approvalUrl: "primer.io")
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: true)
        let state = MockAppState(decodedClientToken: nil)

        DependencyContainer.register(api as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        state.clientToken = nil

        let service = PayPalService()

        service.startOrderSession({ result in
            switch result {
            case .failure:
                XCTAssert(true)
            case .success:
                XCTAssert(false, "Test should not get into the success case.")
            }

            expectation.fulfill()
        })

        // Since no token is found, API call shouldn't be performed.
        XCTAssertEqual(api.isCalled, false)

        wait(for: [expectation], timeout: 30.0)
    }

    func test_startOrderSession_fails_if_configId_nil() throws {
        let expectation = XCTestExpectation(description: "Create PayPal payment sesion | Failure: No config ID")

        let response = PaymentMethod.PayPal.CreateOrder.Response(orderId: "oid", approvalUrl: "primer.io")
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState(primerConfiguration: nil)

        DependencyContainer.register(api as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)

        let service = PayPalService()

        service.startOrderSession({ result in
            switch result {
            case .failure:
                XCTAssert(true)
            case .success:
                XCTAssert(false, "Test should not get into the success case.")
            }

            expectation.fulfill()
        })

        // Since no token is found, API call shouldn't be performed.
        XCTAssertEqual(api.isCalled, false)

        wait(for: [expectation], timeout: 30.0)
    }

    // MARK: startBillingAgreementSession
    func test_startBillingAgreementSession_calls_api() throws {
        let expectation = XCTestExpectation(description: "Create PayPal billing agreement | Success")

        let approvalUrl = "https://primer.io"
        
        let state = MockAppState()
        let settings = MockPrimerSettings()
        let client = MockPrimerAPIClient()

        DependencyContainer.register(state as AppStateProtocol)
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        DependencyContainer.register(client as PrimerAPIClientProtocol)

        let service = PayPalService()
        let createOrderRes = PaymentMethod.PayPal.CreateOrder.Response(orderId: "oid", approvalUrl: approvalUrl)
        let createOrderData = try JSONEncoder().encode(createOrderRes)
        client.response = createOrderData
        client.throwsError = false
        
        service.startOrderSession({ result in
            switch result {
            case .failure:
                XCTAssert(true)
            case .success:
                let createBillingAgreementRes = PaymentMethod.PayPal.CreateBillingAgreement.Response(tokenId: "tid", approvalUrl: "https://primer.io")
                let createBillingAgreementData = try! JSONEncoder().encode(createBillingAgreementRes)
                client.response = createBillingAgreementData
                client.throwsError = false
                
                service.startBillingAgreementSession({ result in
                    switch result {
                    case .failure:
                        XCTAssert(false, "Test should not get into the failure case.")
                    case .success(let url):
                        XCTAssertEqual(url, createOrderRes.approvalUrl)
                    }

                    expectation.fulfill()
                })
            }
        })

        XCTAssertEqual(client.isCalled, true)

        wait(for: [expectation], timeout: 30.0)
    }

    func test_startBillingAgreementSession_fails_if_client_token_nil() throws {
        let expectation = XCTestExpectation(description: "Create PayPal billing agreement | Failure: No client token")

        let response = PaymentMethod.PayPal.CreateBillingAgreement.Response(tokenId: "tid", approvalUrl: "https://primer.io")
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState(decodedClientToken: nil)

        DependencyContainer.register(api as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        state.clientToken = nil

        let service = PayPalService()

        service.startOrderSession({ result in
            switch result {
            case .failure:
                XCTAssert(true)
            case .success:
                XCTAssert(false, "Test should not get into the success case.")
            }

            expectation.fulfill()
        })

        XCTAssertEqual(api.isCalled, false)

        wait(for: [expectation], timeout: 30.0)
    }

    func test_startBillingAgreementSession_fails_if_configId_nil() throws {
        let expectation = XCTestExpectation(description: "Create PayPal billing agreement | Failure: No config ID")

        let response = PaymentMethod.PayPal.CreateBillingAgreement.Response(tokenId: "tid", approvalUrl: "https://primer.io")
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState(primerConfiguration: nil)

        DependencyContainer.register(api as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)

        let service = PayPalService()

        service.startOrderSession({ result in
            switch result {
            case .failure:
                XCTAssert(true)
            case .success:
                XCTAssert(false, "Test should not get into the success case.")
            }

            expectation.fulfill()
        })

        // Since no token is found, API call shouldn't be performed.
        XCTAssertEqual(api.isCalled, false)

        wait(for: [expectation], timeout: 30.0)
    }

    // MARK: confirmBillingAgreement
    func test_confirmBillingAgreement_calls_api() throws {
        let expectation = XCTestExpectation(description: "Create PayPal billing agreement | Failure: No config ID")

        let response = mockPayPalBillingAgreement
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState()
        let settings = MockPrimerSettings()

        DependencyContainer.register(state as AppStateProtocol)
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        
        let createOrderRes = PaymentMethod.PayPal.CreateOrder.Response(orderId: "oid", approvalUrl: "approvalUrl")
        let createOrderData = try JSONEncoder().encode(createOrderRes)
        api.response = createOrderData
        api.throwsError = false

        let service = PayPalService()

        service.startOrderSession({ result in
            expectation.fulfill()
        })
        
        XCTAssertEqual(api.isCalled, true)

        wait(for: [expectation], timeout: 30.0)
    }

    func test_confirmBillingAgreement_fails_if_client_token_nil() throws {
        let expectation = XCTestExpectation(description: "Create PayPal billing agreement | Failure: No client token")

        let response = mockPayPalBillingAgreement
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState(decodedClientToken: nil)

        DependencyContainer.register(api as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)
        state.clientToken = nil

        let service = PayPalService()

        service.startOrderSession({ result in
            switch result {
            case .failure:
                XCTAssert(true)
            case .success:
                XCTAssert(false, "Test should not get into the success case.")
            }

            expectation.fulfill()
        })

        XCTAssertEqual(api.isCalled, false)

        wait(for: [expectation], timeout: 30.0)
    }

    func test_confirmBillingAgreement_fails_if_configId_nil() throws {
        let expectation = XCTestExpectation(description: "Create PayPal billing agreement | Failure: No config ID")

        let response = mockPayPalBillingAgreement
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState(primerConfiguration: nil)

        MockLocator.registerDependencies()
        DependencyContainer.register(api as PrimerAPIClientProtocol)
        DependencyContainer.register(state as AppStateProtocol)

        let service = PayPalService()

        service.startOrderSession({ result in
            switch result {
            case .failure:
                XCTAssert(true)
            case .success:
                XCTAssert(false, "Test should not get into the success case.")
            }

            expectation.fulfill()
        })

        XCTAssertEqual(api.isCalled, false)

        wait(for: [expectation], timeout: 30.0)
    }
}

#endif
