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

    //

    // MARK: createPaymentSession - success
    func test_create_order_session_success() throws {
        let expectation = XCTestExpectation(description: "Create Klarna payment session | Success")

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
        let expectation = XCTestExpectation(description: "Create Klarna payment session | Failure: API call failed")

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
        let expectation = XCTestExpectation(description: "Create Klarna payment session | Failure: No token")

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

    //

    // MARK: createClientToken - success
    func test_create_client_token_success() throws {
        let expectation = XCTestExpectation(description: "Create Klarna client token | Success")

        let sessionData = KlarnaSessionData(recurringDescription: "subscription", purchaseCountry: "SE", purchaseCurrency: "SEK", locale: "en-SE", orderAmount: 2000, orderLines: [], billingAddress: nil)
        let response = KlarnaCustomerTokenAPIResponse(customerTokenId: "token", sessionData: sessionData)
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)

        DependencyContainer.register(api as PrimerAPIClientProtocol)

        let service = KlarnaService()

        service.createKlarnaCustomerToken({ result in
            switch result {
            case .failure:
                XCTAssert(false, "Test should not get into the failure case.")
            case .success(let response):
                XCTAssertEqual(response.customerTokenId, response.customerTokenId)
            }

            expectation.fulfill()
        })

        XCTAssertEqual(api.isCalled, true)

        wait(for: [expectation], timeout: 10.0)
    }

    // MARK: createClientToken - fail, api exception
    func test_create_client_token_fail_invalid_response() throws {
        let expectation = XCTestExpectation(description: "Create Klarna client token | Failure: API call failed")

        let sessionData = KlarnaSessionData(recurringDescription: "subscription", purchaseCountry: "SE", purchaseCurrency: "SEK", locale: "en-SE", orderAmount: 2000, orderLines: [], billingAddress: nil)
        let response = KlarnaCustomerTokenAPIResponse(customerTokenId: "token", sessionData: sessionData)
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: true)

        DependencyContainer.register(api as PrimerAPIClientProtocol)

        let service = KlarnaService()

        service.createKlarnaCustomerToken({ result in
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

    // MARK: createClientToken - fail, no client token
    func test_create_client_token_fail_no_client_token() throws {
        let expectation = XCTestExpectation(description: "Create Klarna client token | Failure: No token")

        let state = MockAppState(decodedClientToken: nil)
        DependencyContainer.register(state as AppStateProtocol)

        let api = MockPrimerAPIClient()
        DependencyContainer.register(api as PrimerAPIClientProtocol)

        let service = KlarnaService()

        service.createKlarnaCustomerToken({ result in
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

    //

    // MARK: finalizePaymentSession - success
    func test_finalize_payment_session_success() throws {
        let expectation = XCTestExpectation(description: "Finalize Klarna payment session | Success")

        let sessionData = KlarnaSessionData(recurringDescription: "subscription", purchaseCountry: "SE", purchaseCurrency: "SEK", locale: "en-SE", orderAmount: 2000, orderLines: [], billingAddress: nil)
        let response = KlarnaFinalizePaymentSessionresponse(sessionData: sessionData)
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: false)

        DependencyContainer.register(api as PrimerAPIClientProtocol)

        let service = KlarnaService()

        service.finalizePaymentSession({ result in
            switch result {
            case .failure:
                XCTAssert(false, "Test should not get into the failure case.")
            case .success(let res):
                XCTAssertEqual(res.sessionData.purchaseCountry, response.sessionData.purchaseCountry)
            }

            expectation.fulfill()
        })

        XCTAssertEqual(api.isCalled, true)

        wait(for: [expectation], timeout: 10.0)
    }

    // MARK: finalizePaymentSession - fail, api exception
    func test_finalize_payment_session_fail_invalid_response() throws {
        let expectation = XCTestExpectation(description: "Finalize Klarna payment session | Failure: API call failed")

        let sessionData = KlarnaSessionData(recurringDescription: "subscription", purchaseCountry: "SE", purchaseCurrency: "SEK", locale: "en-SE", orderAmount: 2000, orderLines: [], billingAddress: nil)
        let response = KlarnaFinalizePaymentSessionresponse(sessionData: sessionData)
        let data = try JSONEncoder().encode(response)
        let api = MockPrimerAPIClient(with: data, throwsError: true)

        DependencyContainer.register(api as PrimerAPIClientProtocol)

        let service = KlarnaService()

        service.finalizePaymentSession({ result in
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

    // MARK: finalizePaymentSession - fail, no client token
    func test_finalize_payment_session_fail_no_client_token() throws {
        let expectation = XCTestExpectation(description: "Finalize Klarna payment session | Failure: No token")

        let state = MockAppState(decodedClientToken: nil)
        DependencyContainer.register(state as AppStateProtocol)

        let api = MockPrimerAPIClient()
        DependencyContainer.register(api as PrimerAPIClientProtocol)

        let service = KlarnaService()

        service.finalizePaymentSession({ result in
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
