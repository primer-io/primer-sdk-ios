//
//  File.swift
//  
//
//  Created by Niall Quinn on 01/08/24.
//

import XCTest
@testable import PrimerSDK

final class CreateResumePaymentServiceTests: XCTestCase {

    typealias Payment = Response.Body.Payment

    func test_createNoJWT() throws {
        let response = Payment.successResponse
        let apiClient = MockCreateResumeAPI(createResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = nil
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")
        createResumeService.createPayment(paymentRequest: createRequest).done { payment in
        }.catch { error in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createSuccess() throws {
        let response = Payment.successResponse
        let apiClient = MockCreateResumeAPI(createResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")
        createResumeService.createPayment(paymentRequest: createRequest).done { payment in
            XCTAssert(payment.status == .success)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Promise rejected: \(error)")
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createFailure() throws {
        let response = Payment.failedStatusResponse
        let apiClient = MockCreateResumeAPI(createResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")
        createResumeService.createPayment(paymentRequest: createRequest).done { payment in
            XCTFail("Succeeded when it should have failed")
        }.catch { error in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createPending() throws {
        let response = Payment.pendingStatusResponse
        let apiClient = MockCreateResumeAPI(createResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")
        createResumeService.createPayment(paymentRequest: createRequest).done { payment in
            XCTAssert(payment.status == .pending)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Promise rejected: \(error)")
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createError() throws {
        let response = Payment.errorResponse
        let apiClient = MockCreateResumeAPI(createResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")
        createResumeService.createPayment(paymentRequest: createRequest).done { payment in
            XCTFail("Succeeded when it should have failed")
        }.catch { error in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }


    func test_resumeNoJWT() throws {
        let response = Payment.successResponse
        let apiClient = MockCreateResumeAPI(resumeResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = nil
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { payment in
        }.catch { error in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumeSuccess() throws {
        let response = Payment.successResponse
        let apiClient = MockCreateResumeAPI(resumeResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { payment in
            XCTAssert(payment.status == .success)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Promise rejected: \(error)")
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumeFailure() throws {
        let response = Payment.failedStatusResponse
        let apiClient = MockCreateResumeAPI(resumeResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { payment in
            XCTFail("Succeeded when it should have failed")
        }.catch { error in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumePending() throws {
        let response = Payment.pendingStatusResponse
        let apiClient = MockCreateResumeAPI(resumeResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { payment in
            XCTFail("Succeeded when it should have failed")
        }.catch { error in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumeError() throws {
        let response = Payment.errorResponse
        let apiClient = MockCreateResumeAPI(resumeResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { payment in
            XCTFail("Succeeded when it should have failed")
        }.catch { error in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumePending_showSuccessCheckoutOnPendingPayment() throws {
        let response = Payment.pendingStatusResponseWithShowCheckoutSuccessOnPending
        let apiClient = MockCreateResumeAPI(resumeResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { payment in
            XCTAssert(payment.status == .pending)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Failed, but flag should result in success")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_complete_token_completeUrl() throws {
        let response = Response.Body.Complete.successResponse
        let apiClient = MockCreateResumeAPI(completeResponse: response)

        let createResumeService = CreateResumePaymentService(paymentMethodType: "STRIPE_ACH",
                                                             apiClient: apiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")

        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            XCTFail()
            return
        }
        
        let _ = createResumeService.completePayment(clientToken: clientToken,
                                            completeUrl: URL(string: "https://example.com")!
        ).done {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

}


private class MockCreateResumeAPI: PrimerAPIClientCreateResumePaymentProtocol {

    var resumeResponse: APIResult<Response.Body.Payment>?
    var createResponse: APIResult<Response.Body.Payment>?
    var completeResponse: APIResult<Response.Body.Complete>?

    init(resumeResponse: APIResult<Response.Body.Payment>? = nil,
         createResponse: APIResult<Response.Body.Payment>? = nil,
         completeResponse: APIResult<Response.Body.Complete>? = nil) {
        self.resumeResponse = resumeResponse
        self.createResponse = createResponse
        self.completeResponse = completeResponse
    }

    func createPayment(clientToken: DecodedJWTToken, paymentRequestBody: Request.Body.Payment.Create, completion: @escaping APICompletion<Response.Body.Payment>) {
        guard let createResponse else {
            XCTFail("No create response set")
            return
        }
        completion(createResponse)
    }

    func resumePayment(clientToken: DecodedJWTToken, paymentId: String, paymentResumeRequest: Request.Body.Payment.Resume, completion: @escaping APICompletion<Response.Body.Payment>) {
        guard let resumeResponse else {
            XCTFail("No resume response set")
            return
        }
        completion(resumeResponse)
    }

    func completePayment(clientToken: DecodedJWTToken,
                         url: URL, paymentRequest: Request.Body.Payment.Complete,
                         completion: @escaping APICompletion<Response.Body.Complete>) {
        guard let completeResponse else {
            XCTFail("No complete response set")
            return
        }
        completion(completeResponse)
    }
}

private extension Response.Body.Payment {
    static var successResponse: APIResult<Response.Body.Payment> {
        .success(.init(id: "id",
                       paymentId: "paymentId",
                       amount: 1,
                       currencyCode: "EUR",
                       customer: nil,
                       customerId: nil,
                       dateStr: nil,
                       order: nil,
                       orderId: nil,
                       requiredAction: nil,
                       status: .success,
                       paymentFailureReason: nil))
    }

    static var failedStatusResponse: APIResult<Response.Body.Payment> {
        .success(.init(id: "id",
                       paymentId: "paymentId",
                       amount: 1,
                       currencyCode: "EUR",
                       customer: nil,
                       customerId: nil,
                       dateStr: nil,
                       order: nil,
                       orderId: nil,
                       requiredAction: nil,
                       status: .failed,
                       paymentFailureReason: nil))
    }

    static var pendingStatusResponse: APIResult<Response.Body.Payment> {
        .success(.init(id: "id",
                       paymentId: "paymentId",
                       amount: 1,
                       currencyCode: "EUR",
                       customer: nil,
                       customerId: nil,
                       dateStr: nil,
                       order: nil,
                       orderId: nil,
                       requiredAction: nil,
                       status: .pending,
                       paymentFailureReason: nil))
    }

    static var pendingStatusResponseWithShowCheckoutSuccessOnPending: APIResult<Response.Body.Payment> {
        .success(.init(id: "id",
                       paymentId: "paymentId",
                       amount: 1,
                       currencyCode: "EUR",
                       customer: nil,
                       customerId: nil,
                       dateStr: nil,
                       order: nil,
                       orderId: nil,
                       requiredAction: nil,
                       status: .pending,
                       paymentFailureReason: nil,
                       showSuccessCheckoutOnPendingPayment: true))
    }

    static var errorResponse: APIResult<Response.Body.Payment> {
        .failure(PrimerError.failedToCreatePayment(paymentMethodType: "PAYMENT_CARD",
                                                   description: "",
                                                   userInfo: [:],
                                                   diagnosticsId: ""))
    }
}

private extension Response.Body.Complete {
    static var successResponse: APIResult<Response.Body.Complete> {
        .success(.init())
    }
}
