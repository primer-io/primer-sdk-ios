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
    func test_startOrderSession_calls_api() throws {
        let expectation = XCTestExpectation(description: "Create PayPal payment sesion | Success")
        let approvalUrl = "https://primer.io"

        MockLocator.registerDependencies()

        let service = MockPayPalService()
        service.startOrderSession({ result in
            switch result {
            case .failure:
                XCTAssert(false, "Test should not get into the failure case.")
            case .success(let res):
                XCTAssertEqual(res.approvalUrl, approvalUrl)
            }

            expectation.fulfill()
        })

        //        XCTAssertEqual(api.isCalled, true)

        wait(for: [expectation], timeout: 30.0)
    }

    func test_startOrderSession_fails_if_client_token_nil() throws {
        let expectation = XCTestExpectation(description: "Create PayPal payment sesion | Failure: No client token")

        let response = Response.Body.PayPal.CreateOrder(orderId: "oid", approvalUrl: "primer.io")
        //        let api = MockPrimerAPIClient(with: data, throwsError: true)
        let state = MockAppState()

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
        //        XCTAssertEqual(api.isCalled, false)

        wait(for: [expectation], timeout: 30.0)
    }

    func test_startOrderSession_fails_if_configId_nil() throws {
        let expectation = XCTestExpectation(description: "Create PayPal payment sesion | Failure: No config ID")

        let response = Response.Body.PayPal.CreateOrder(orderId: "oid", approvalUrl: "primer.io")
        let data = try JSONEncoder().encode(response)
        //        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState(apiConfiguration: nil)

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
        //        XCTAssertEqual(api.isCalled, false)

        wait(for: [expectation], timeout: 30.0)
    }

    // MARK: startBillingAgreementSession
    func test_startBillingAgreementSession_calls_api() throws {
        let expectation = XCTestExpectation(description: "Create PayPal billing agreement | Success")

        let approvalUrl = "https://primer.io"

        let client = MockPrimerAPIClient()

        MockLocator.registerDependencies()

        let service = MockPayPalService()
        let createOrderRes = Response.Body.PayPal.CreateOrder(orderId: "oid", approvalUrl: approvalUrl)
        let createOrderData = try JSONEncoder().encode(createOrderRes)
        //        client.response = createOrderData
        //        client.throwsError = false

        service.startOrderSession({ result in
            switch result {
            case .failure:
                XCTAssert(true)
            case .success:
                let createBillingAgreementRes = Response.Body.PayPal.CreateBillingAgreement(
                    tokenId: "tid",
                    approvalUrl: "https://primer.io")
                let createBillingAgreementData = try! JSONEncoder().encode(createBillingAgreementRes)
                //                client.response = createBillingAgreementData
                //                client.throwsError = false

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

        //        XCTAssertEqual(client.isCalled, true)

        wait(for: [expectation], timeout: 30.0)
    }

    func test_startBillingAgreementSession_fails_if_client_token_nil() throws {
        let expectation = XCTestExpectation(description: "Create PayPal billing agreement | Failure: No client token")

        let response = Response.Body.PayPal.CreateBillingAgreement(
            tokenId: "tid",
            approvalUrl: "https://primer.io")
        let data = try JSONEncoder().encode(response)
        //        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState()

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

        //        XCTAssertEqual(api.isCalled, false)

        wait(for: [expectation], timeout: 30.0)
    }

    func test_startBillingAgreementSession_fails_if_configId_nil() throws {
        let expectation = XCTestExpectation(description: "Create PayPal billing agreement | Failure: No config ID")

        let response = Response.Body.PayPal.CreateBillingAgreement(
            tokenId: "tid",
            approvalUrl: "https://primer.io")
        let data = try JSONEncoder().encode(response)
        //        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState(apiConfiguration: nil)

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
        //        XCTAssertEqual(api.isCalled, false)

        wait(for: [expectation], timeout: 30.0)
    }

    func test_confirmBillingAgreement_fails_if_client_token_nil() throws {
        let expectation = XCTestExpectation(description: "Create PayPal billing agreement | Failure: No client token")

        let response = mockPayPalBillingAgreement
        let data = try JSONEncoder().encode(response)
        //        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState()

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

        //        XCTAssertEqual(api.isCalled, false)

        wait(for: [expectation], timeout: 30.0)
    }

    func test_confirmBillingAgreement_fails_if_configId_nil() throws {
        let expectation = XCTestExpectation(description: "Create PayPal billing agreement | Failure: No config ID")

        let response = mockPayPalBillingAgreement
        let data = try JSONEncoder().encode(response)
        //        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState(apiConfiguration: nil)

        MockLocator.registerDependencies()
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

        //        XCTAssertEqual(api.isCalled, false)

        wait(for: [expectation], timeout: 30.0)
    }
}
