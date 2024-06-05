//
//  PayPalServiceTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 17/01/2021.
//

import XCTest
@testable import PrimerSDK

class PayPalServiceTests: XCTestCase {

    func test_startOrderSession_fails_if_client_token_nil() throws {
        let expectation = self.expectation(description: "Create PayPal payment sesion | Failure: No client token")

        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        state.clientToken = nil

        let service = PayPalService()

        service.startOrderSession({ result in
            switch result {
            case .failure:
                break
            case .success:
                XCTFail("Test should not get into the success case.")
            }

            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 2.0)
    }

    func test_startOrderSession_fails_if_configId_nil() throws {
        let expectation = self.expectation(description: "Create PayPal payment sesion | Failure: No config ID")

        let response = Response.Body.PayPal.CreateOrder(orderId: "oid", approvalUrl: "primer.io")
        let data = try JSONEncoder().encode(response)
        //        let api = MockPrimerAPIClient(with: data, throwsError: false)
        let state = MockAppState(apiConfiguration: nil)

        DependencyContainer.register(state as AppStateProtocol)

        let service = PayPalService()

        service.startOrderSession({ result in
            switch result {
            case .failure:
                break
            case .success:
                XCTFail("Test should not get into the success case.")
            }

            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 2.0)
    }

    func test_startBillingAgreementSession_fails_if_client_token_nil() throws {
        let expectation = self.expectation(description: "Create PayPal billing agreement | Failure: No client token")

        let state = MockAppState()

        DependencyContainer.register(state as AppStateProtocol)
        state.clientToken = nil

        let service = PayPalService()

        service.startOrderSession({ result in
            switch result {
            case .failure:
                break
            case .success:
                XCTFail("Test should not get into the success case.")
            }

            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 2.0)
    }

    func test_startBillingAgreementSession_fails_if_configId_nil() throws {
        let expectation = self.expectation(description: "Create PayPal billing agreement | Failure: No config ID")

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
                break
            case .success:
                XCTFail("Test should not get into the success case.")
            }

            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 2.0)
    }

    func test_confirmBillingAgreement_fails_if_client_token_nil() throws {
        let expectation = self.expectation(description: "Create PayPal billing agreement | Failure: No client token")

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
                break
            case .success:
                XCTFail("Test should not get into the success case.")
            }

            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 2.0)
    }

    func test_confirmBillingAgreement_fails_if_configId_nil() throws {
        let expectation = self.expectation(description: "Create PayPal billing agreement | Failure: No config ID")

        let state = MockAppState(apiConfiguration: nil)

        MockLocator.registerDependencies()
        DependencyContainer.register(state as AppStateProtocol)

        let service = PayPalService()

        service.startOrderSession({ result in
            switch result {
            case .failure:
                break
            case .success:
                XCTFail("Test should not get into the success case.")
            }

            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 2.0)
    }

    func testStartOrderSession() throws {
        let apiClient = MockPayPalAPIClient()
        let service = PayPalService(apiClient: apiClient)

        MockLocator.registerDependencies()
        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "scheme://"))
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paypalPaymentMethod])

        let state = MockAppState()
        DependencyContainer.register(state as AppStateProtocol)
        state.amount = 123
        state.currency = Currency(code: "GBP", decimalDigits: 2)

        apiClient.onCreateOrderSession = { _, _ in
            return .init(orderId: "order_id", approvalUrl: "scheme://approve")
        }

        let startOrderSessionExpectation = self.expectation(description: "Billing agreement started")
        service.startOrderSession { result in
            switch result {
            case .success(let model):
                XCTAssertEqual(model.orderId, "order_id")
                XCTAssertEqual(model.approvalUrl, "scheme://approve")
            case .failure(_):
                XCTFail()
            }
            startOrderSessionExpectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testCreateBillingAgreement() throws {
        let apiClient = MockPayPalAPIClient()
        let service = PayPalService(apiClient: apiClient)

        MockLocator.registerDependencies()
        let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "scheme://"))
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paypalPaymentMethod])

        apiClient.onCreateBillingAgreementSession = { _, _ in
            return .init(tokenId: "my_token", approvalUrl: "scheme://approve")
        }

        let startBillingAgreementExpectation = self.expectation(description: "Billing agreement started")
        service.startBillingAgreementSession { result in
            switch result {
            case .success(let approvalUrl):
                XCTAssertEqual(approvalUrl, "scheme://approve")
            case .failure(_):
                XCTFail()
            }
            startBillingAgreementExpectation.fulfill()
        }
        wait(for: [startBillingAgreementExpectation], timeout: 2.0)

        apiClient.onConfirmBillingAgreement = { _, _ in
            return .init(billingAgreementId: "agreement_id",
                         externalPayerInfo: .init(externalPayerId: "external_payer_id",
                                                  email: "email@email.com",
                                                  firstName: "first_name",
                                                  lastName: "last_name"),
                         shippingAddress: nil)
        }

        let expectation = self.expectation(description: "Billing agreement is confirmed")
        service.confirmBillingAgreement { result in
            switch result {
            case .success(let model):
                XCTAssertEqual(model.externalPayerInfo.externalPayerId, "external_payer_id")
            case .failure(_):
                XCTFail()
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }
}

fileprivate class MockPayPalAPIClient: PrimerAPIClientPayPalProtocol {

    var onCreateOrderSession: ((DecodedJWTToken, Request.Body.PayPal.CreateOrder) -> Response.Body.PayPal.CreateOrder)?

    func createPayPalOrderSession(clientToken: PrimerSDK.DecodedJWTToken, 
                                  payPalCreateOrderRequest: Request.Body.PayPal.CreateOrder,
                                  completion: @escaping APICompletion<Response.Body.PayPal.CreateOrder>) {
        if let onCreateOrderSession = onCreateOrderSession {
            completion(.success(onCreateOrderSession(clientToken, payPalCreateOrderRequest)))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }
    
    var onCreateBillingAgreementSession: ((DecodedJWTToken, Request.Body.PayPal.CreateBillingAgreement) -> Response.Body.PayPal.CreateBillingAgreement)?

    func createPayPalBillingAgreementSession(clientToken: DecodedJWTToken,
                                             payPalCreateBillingAgreementRequest: Request.Body.PayPal.CreateBillingAgreement,
                                             completion: @escaping APICompletion<Response.Body.PayPal.CreateBillingAgreement>) {
        if let onCreateBillingAgreementSession = onCreateBillingAgreementSession {
            completion(.success(onCreateBillingAgreementSession(clientToken, payPalCreateBillingAgreementRequest)))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }
    
    var onConfirmBillingAgreement: ((DecodedJWTToken, Request.Body.PayPal.ConfirmBillingAgreement) -> Response.Body.PayPal.ConfirmBillingAgreement)?

    func confirmPayPalBillingAgreement(clientToken: DecodedJWTToken,
                                       payPalConfirmBillingAgreementRequest: Request.Body.PayPal.ConfirmBillingAgreement, 
                                       completion: @escaping APICompletion<Response.Body.PayPal.ConfirmBillingAgreement>) {
        if let onConfirmBillingAgreement = onConfirmBillingAgreement {
            completion(.success(onConfirmBillingAgreement(clientToken, payPalConfirmBillingAgreementRequest)))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }
    
    var onFetchExternalPayerInfo: ((DecodedJWTToken, Request.Body.PayPal.PayerInfo) -> Response.Body.PayPal.PayerInfo)?

    func fetchPayPalExternalPayerInfo(clientToken: DecodedJWTToken,
                                      payPalExternalPayerInfoRequestBody: Request.Body.PayPal.PayerInfo, 
                                      completion: @escaping APICompletion<Response.Body.PayPal.PayerInfo>) {
        if let onFetchExternalPayerInfo = onFetchExternalPayerInfo {
            completion(.success(onFetchExternalPayerInfo(clientToken, payPalExternalPayerInfoRequestBody)))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }
    

}
