//
//  File.swift
//
//
//  Created by Niall Quinn on 01/08/24.
//

@testable import PrimerSDK
import XCTest

final class CreateResumePaymentServiceTests: XCTestCase {
    typealias Payment = Response.Body.Payment

    // ** Complete Payment **//

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

        _ = createResumeService.completePayment(clientToken: clientToken,
                                                completeUrl: URL(string: "https://example.com")!,
                                                body: StripeAchTokenizationViewModel.defaultCompleteBodyWithTimestamp).done {
                                                    expectation.fulfill()
                                                }

        waitForExpectations(timeout: 5, handler: nil)
    }

    // ** Create Payment **//

    func test_createPayment_shouldFailWhenClientTokenIsNil() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithSuccessStatus)
        let apiClient = MockCreateResumeAPI(createResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = nil
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        createResumeService.createPayment(paymentRequest: createRequest).done { _ in
            XCTFail("Succeeded when it should have failed")
        }.catch { _ in
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createPayment_shouldFailWhenResponseIsError() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .failure(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
        let apiClient = MockCreateResumeAPI(createResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        createResumeService.createPayment(paymentRequest: createRequest).done { _ in
            XCTFail("Succeeded when it should have failed")
        }.catch { _ in
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createPayment_shouldFailWhenPaymentIdIsNil() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithNoId)
        let apiClient = MockCreateResumeAPI(createResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        createResumeService.createPayment(paymentRequest: createRequest).done { _ in
            XCTFail("Succeeded when it should have failed")
        }.catch { _ in
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createPayment_shouldSucceedWithSuccessStatus() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithSuccessStatus)
        let apiClient = MockCreateResumeAPI(createResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        createResumeService.createPayment(paymentRequest: createRequest).done { payment in
            XCTAssert(payment.status == .success)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Promise rejected: \(error)")
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createPayment_shouldFailWithFailedStatus() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithFailedStatus)
        let apiClient = MockCreateResumeAPI(createResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        createResumeService.createPayment(paymentRequest: createRequest).done { _ in
            XCTFail("Succeeded when it should have failed")
        }.catch { _ in
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createPayment_shouldSuccessWithPendingStatus() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithPendingStatus)
        let apiClient = MockCreateResumeAPI(createResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        createResumeService.createPayment(paymentRequest: createRequest).done { payment in
            XCTAssert(payment.status == .pending)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Promise rejected: \(error)")
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createPayment_shouldSuccessWithPendingStatusAndShowSuccessCheckoutOnPendingPayment() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithPendingStatusAndShowSuccessCheckoutOnPendingPayment)
        let apiClient = MockCreateResumeAPI(createResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        createResumeService.createPayment(paymentRequest: createRequest).done { payment in
            XCTAssert(payment.status == .pending)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Promise rejected: \(error)")
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createPayment_shouldSucceedWithCompleteCheckoutOutcome() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithCompleteCheckoutOutcome)
        let apiClient = MockCreateResumeAPI(createResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        createResumeService.createPayment(paymentRequest: createRequest).done { payment in
            XCTAssert(payment.status == .success)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Promise rejected: \(error)")
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createPayment_shouldFailWithFailureCheckoutOutcome() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithFailureCheckoutOutcome)
        let apiClient = MockCreateResumeAPI(createResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        createResumeService.createPayment(paymentRequest: createRequest).done { _ in
            XCTFail("Succeeded when it should have failed")
        }.catch { _ in
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createPayment_shouldSuccessWithDetermineFromPaymentStatusCheckoutOutcomeAndSuccessStatus() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithDetermineFromPaymentStatusCheckoutOutcomeAndSuccessStatus)
        let apiClient = MockCreateResumeAPI(createResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        createResumeService.createPayment(paymentRequest: createRequest).done { payment in
            XCTAssert(payment.status == .success)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Promise rejected: \(error)")
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createPayment_shouldFailWithDetermineFromPaymentStatusCheckoutOutcomeAndFailedStatus() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithDetermineFromPaymentStatusCheckoutOutcomeAndFailedStatus)
        let apiClient = MockCreateResumeAPI(createResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        createResumeService.createPayment(paymentRequest: createRequest).done { _ in
            XCTFail("Succeeded when it should have failed")
        }.catch { _ in
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createPayment_shouldSuccessWithDetermineFromPaymentStatusCheckoutOutcomeAndPendingStatus() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithDetermineFromPaymentStatusCheckoutOutcomeAndPendingStatus)
        let apiClient = MockCreateResumeAPI(createResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        createResumeService.createPayment(paymentRequest: createRequest).done { payment in
            XCTAssert(payment.status == .pending)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Promise rejected: \(error)")
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_createPayment_shouldSuccessWithDetermineFromPaymentStatusCheckoutOutcomeAndPendingStatusAndShowSuccessCheckoutOnPendingPayment() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> =
            .success(.paymentWithDetermineFromPaymentStatusCheckoutOutcomeAndPendingStatusAndShowSuccessCheckoutOnPendingPayment)
        let apiClient = MockCreateResumeAPI(createResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        createResumeService.createPayment(paymentRequest: createRequest).done { payment in
            XCTAssert(payment.status == .pending)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Promise rejected: \(error)")
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    // ** Resume Payment **//

    func test_resumePayment_shouldFailWhenClientTokenIsNil() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithSuccessStatus)
        let apiClient = MockCreateResumeAPI(resumeResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = nil
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { _ in
            XCTFail("Succeeded when it should have failed")
        }.catch { _ in
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumePayment_shouldFailWhenResponseIsError() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .failure(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
        let apiClient = MockCreateResumeAPI(resumeResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { _ in
            XCTFail("Succeeded when it should have failed")
        }.catch { _ in
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumePayment_shouldFailWhenPaymentIdIsNil() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithNoId)
        let apiClient = MockCreateResumeAPI(resumeResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { _ in
            XCTFail("Succeeded when it should have failed")
        }.catch { _ in
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumePayment_shouldSucceedWithSuccessStatus() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithSuccessStatus)
        let apiClient = MockCreateResumeAPI(resumeResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { payment in
            XCTAssert(payment.status == .success)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Promise rejected: \(error)")
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumePayment_shouldFailWithFailedStatus() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithFailedStatus)
        let apiClient = MockCreateResumeAPI(resumeResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { _ in
            XCTFail("Succeeded when it should have failed")
        }.catch { _ in
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumePayment_shouldFailWithPendingStatus() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithPendingStatus)
        let apiClient = MockCreateResumeAPI(resumeResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { _ in
            XCTFail("Succeeded when it should have failed")
        }.catch { _ in
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumePayment_shouldSuccessWithPendingStatusAndShowSuccessCheckoutOnPendingPayment() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithPendingStatusAndShowSuccessCheckoutOnPendingPayment)
        let apiClient = MockCreateResumeAPI(resumeResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { payment in
            XCTAssert(payment.status == .pending)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Promise rejected: \(error)")
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumePayment_shouldSucceedWithCompleteCheckoutOutcome() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithCompleteCheckoutOutcome)
        let apiClient = MockCreateResumeAPI(resumeResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { payment in
            XCTAssert(payment.status == .success)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Promise rejected: \(error)")
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumePayment_shouldFailWithFailureCheckoutOutcome() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithFailureCheckoutOutcome)
        let apiClient = MockCreateResumeAPI(resumeResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { _ in
            XCTFail("Succeeded when it should have failed")
        }.catch { _ in
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumePayment_shouldSucceedWithDetermineFromPaymentStatusCheckoutOutcomeAndSuccessStatus() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithDetermineFromPaymentStatusCheckoutOutcomeAndSuccessStatus)
        let apiClient = MockCreateResumeAPI(resumeResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { payment in
            XCTAssert(payment.status == .success)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Promise rejected: \(error)")
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumePayment_shouldFailWithDetermineFromPaymentStatusCheckoutOutcomeAndFailedStatus() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithDetermineFromPaymentStatusCheckoutOutcomeAndFailedStatus)
        let apiClient = MockCreateResumeAPI(resumeResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { _ in
            XCTFail("Succeeded when it should have failed")
        }.catch { _ in
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumePayment_shouldFailWithDetermineFromPaymentStatusCheckoutOutcomeAndPendingStatus() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> = .success(.paymentWithDetermineFromPaymentStatusCheckoutOutcomeAndPendingStatus)
        let apiClient = MockCreateResumeAPI(resumeResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { _ in
            XCTFail("Succeeded when it should have failed")
        }.catch { _ in
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_resumePayment_shouldSuccessWithDetermineFromPaymentStatusCheckoutOutcomeAndPendingStatusAndShowSuccessCheckoutOnPendingPayment() throws {
        // Given
        let response: Result<Response.Body.Payment, Error> =
            .success(.paymentWithDetermineFromPaymentStatusCheckoutOutcomeAndPendingStatusAndShowSuccessCheckoutOnPendingPayment)
        let apiClient = MockCreateResumeAPI(resumeResponse: response)
        let createResumeService = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD",
                                                             apiClient: apiClient)
        AppState.current.clientToken = MockAppState.mockClientToken
        let expectation = self.expectation(description: "Promise fulfilled")
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        createResumeService.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest).done { payment in
            XCTAssert(payment.status == .pending)
            expectation.fulfill()
        }.catch { error in
            XCTFail("Promise rejected: \(error)")
        }

        // Then
        waitForExpectations(timeout: 5, handler: nil)
    }
}

private extension Response.Body.Payment {
    static var paymentWithNoId: Response.Body.Payment {
        .init(id: nil,
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
              paymentFailureReason: nil,
              checkoutOutcome: nil)
    }

    static var paymentWithSuccessStatus: Response.Body.Payment {
        .init(id: "id",
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
              paymentFailureReason: nil,
              checkoutOutcome: nil)
    }

    static var paymentWithFailedStatus: Response.Body.Payment {
        .init(id: "id",
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
              paymentFailureReason: nil,
              checkoutOutcome: nil)
    }

    static var paymentWithPendingStatus: Response.Body.Payment {
        .init(id: "id",
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
              checkoutOutcome: nil)
    }

    static var paymentWithPendingStatusAndShowSuccessCheckoutOnPendingPayment: Response.Body.Payment {
        .init(id: "id",
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
              showSuccessCheckoutOnPendingPayment: true,
              checkoutOutcome: nil)
    }

    static var paymentWithCompleteCheckoutOutcome: Response.Body.Payment {
        .init(id: "id",
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
              paymentFailureReason: nil,
              checkoutOutcome: .checkoutComplete)
    }

    static var paymentWithFailureCheckoutOutcome: Response.Body.Payment {
        .init(id: "id",
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
              paymentFailureReason: nil,
              checkoutOutcome: .checkoutFailure)
    }

    static var paymentWithDetermineFromPaymentStatusCheckoutOutcomeAndSuccessStatus: Response.Body.Payment {
        .init(id: "id",
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
              paymentFailureReason: nil,
              checkoutOutcome: .determineFromPaymentStatus)
    }

    static var paymentWithDetermineFromPaymentStatusCheckoutOutcomeAndFailedStatus: Response.Body.Payment {
        .init(id: "id",
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
              paymentFailureReason: nil,
              checkoutOutcome: .determineFromPaymentStatus)
    }

    static var paymentWithDetermineFromPaymentStatusCheckoutOutcomeAndPendingStatus: Response.Body.Payment {
        .init(id: "id",
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
              checkoutOutcome: .determineFromPaymentStatus)
    }

    static var paymentWithDetermineFromPaymentStatusCheckoutOutcomeAndPendingStatusAndShowSuccessCheckoutOnPendingPayment: Response.Body.Payment {
        .init(id: "id",
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
              showSuccessCheckoutOnPendingPayment: true,
              checkoutOutcome: .determineFromPaymentStatus)
    }
}

private extension Response.Body.Complete {
    static var successResponse: APIResult<Response.Body.Complete> {
        .success(.init())
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

    func createPayment(
        clientToken: DecodedJWTToken,
        paymentRequestBody: Request.Body.Payment.Create,
        completion: @escaping APICompletion<Response.Body.Payment>
    ) {
        guard let createResponse else {
            XCTFail("No create response set")
            return
        }
        completion(createResponse)
    }

    func resumePayment(
        clientToken: DecodedJWTToken,
        paymentId: String,
        paymentResumeRequest: Request.Body.Payment.Resume,
        completion: @escaping APICompletion<Response.Body.Payment>
    ) {
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
