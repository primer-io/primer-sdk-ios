//
//  CreateResumePaymentServiceTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class CreateResumePaymentServiceTests: XCTestCase {
    var sut: CreateResumePaymentService!
    private var apiClient: MockCreateResumeAPIClient!

    override func setUp() {
        super.setUp()
        apiClient = MockCreateResumeAPIClient()
        sut = CreateResumePaymentService(paymentMethodType: "PAYMENT_CARD", apiClient: apiClient)
    }

    // ** Complete Payment **//

    func test_completePayment_shouldSuccess() async throws {
        // Given
        apiClient.completeResponse = .success(.init())
        AppState.current.clientToken = MockAppState.mockClientToken

        // When
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            XCTFail()
            return
        }

        do {
            _ = try await sut.completePayment(
                clientToken: clientToken,
                completeUrl: URL(string: "https://example.com")!,
                body: StripeAchTokenizationViewModel.defaultCompleteBodyWithTimestamp
            )
        } catch {
            XCTFail("Expected success but got error: \(error)")
        }
    }

    func test_completePayment_shouldFail() async throws {
        // Given
        apiClient.completeResponse = .failure(PrimerError.unknown())
        AppState.current.clientToken = MockAppState.mockClientToken

        // When
        guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            XCTFail()
            return
        }

        do {
            _ = try await sut.completePayment(
                clientToken: clientToken,
                completeUrl: URL(string: "https://example.com")!,
                body: StripeAchTokenizationViewModel.defaultCompleteBodyWithTimestamp
            )
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    // ** Create Payment **//

    func test_createPayment_shouldFailWhenClientTokenIsNil() async throws {
        // Given
        apiClient.createResponse = .success(.successStatus)
        AppState.current.clientToken = nil
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        do {
            _ = try await sut.createPayment(paymentRequest: createRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_createPayment_shouldFailWhenResponseIsError() async throws {
        // Given
        apiClient.createResponse = .failure(PrimerError.unknown())
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        do {
            _ = try await sut.createPayment(paymentRequest: createRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_createPayment_shouldFailWhenPaymentIdIsNil() async throws {
        // Given
        apiClient.createResponse = .success(.noId)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        do {
            _ = try await sut.createPayment(paymentRequest: createRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_createPayment_shouldSucceedWhenSuccessStatus() async throws {
        // Given
        apiClient.createResponse = .success(.successStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        let payment = try await sut.createPayment(paymentRequest: createRequest)
        XCTAssert(payment.status == .success)
    }

    func test_createPayment_shouldFailWhenFailedStatus() async throws {
        // Given
        apiClient.createResponse = .success(.failedStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        do {
            _ = try await sut.createPayment(paymentRequest: createRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_createPayment_shouldSuccessWithPendingStatus() async throws {
        // Given
        apiClient.createResponse = .success(.pendingStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        let payment = try await sut.createPayment(paymentRequest: createRequest)
        XCTAssert(payment.status == .pending)
    }

    func test_createPayment_shouldSucceedWhenPendingStatusWithShowSuccess() async throws {
        // Given
        apiClient.createResponse = .success(.pendingStatusWithShowSuccess)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        let payment = try await sut.createPayment(paymentRequest: createRequest)
        XCTAssert(payment.status == .pending)
    }

    func test_createPayment_shouldSucceedWhenCheckoutComplete() async throws {
        // Given
        apiClient.createResponse = .success(.checkoutComplete)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        let payment = try await sut.createPayment(paymentRequest: createRequest)
        XCTAssert(payment.status == .success)
    }

    func test_createPayment_shouldFailWhenCheckoutFailure() async throws {
        // Given
        apiClient.createResponse = .success(.checkoutFailure)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        do {
            _ = try await sut.createPayment(paymentRequest: createRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_createPayment_shouldSuccessWithFallbackWithSuccessStatus() async throws {
        // Given
        apiClient.createResponse = .success(.fallbackWithSuccessStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        let payment = try await sut.createPayment(paymentRequest: createRequest)
        XCTAssert(payment.status == .success)
    }

    func test_createPayment_shouldFailWhenFallbackWithFailedStatus() async throws {
        // Given
        apiClient.createResponse = .success(.fallbackWithFailedStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        do {
            _ = try await sut.createPayment(paymentRequest: createRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_createPayment_shouldSuccessWithFallbackWithPendingStatus() async throws {
        // Given
        apiClient.createResponse = .success(.fallbackWithPendingStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        let payment = try await sut.createPayment(paymentRequest: createRequest)
        XCTAssert(payment.status == .pending)
    }

    func test_createPayment_shouldSucceedWhenFallbackWithPendingStatusWithShowSuccess() async throws {
        // Given
        apiClient.createResponse = .success(.fallbackWithPendingStatusWithShowSuccess)
        AppState.current.clientToken = MockAppState.mockClientToken
        let createRequest = Request.Body.Payment.Create(token: "123")

        // When
        let payment = try await sut.createPayment(paymentRequest: createRequest)
        XCTAssert(payment.status == .pending)
    }

    // ** Resume Payment **//

    func test_resumePayment_shouldFailWhenClientTokenIsNil() async throws {
        // Given
        apiClient.resumeResponse = .success(.successStatus)
        AppState.current.clientToken = nil
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        do {
            _ = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_resumePayment_shouldFailWhenResponseIsError() async throws {
        // Given
        apiClient.resumeResponse = .failure(PrimerError.unknown())
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        do {
            _ = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_resumePayment_shouldFailWhenNoId() async throws {
        // Given
        apiClient.resumeResponse = .success(.noId)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        do {
            _ = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_resumePayment_shouldSucceedWhenSuccessStatus() async throws {
        // Given
        apiClient.resumeResponse = .success(.successStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        let payment = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
        XCTAssert(payment.status == .success)
    }

    func test_resumePayment_shouldFailWhenFailedStatus() async throws {
        // Given
        apiClient.resumeResponse = .success(.failedStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        do {
            _ = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_resumePayment_shouldFailWhenPendingStatus() async throws {
        // Given
        apiClient.resumeResponse = .success(.pendingStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        do {
            _ = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_resumePayment_shouldSucceedWhenPendingStatusWithShowSuccess() async throws {
        // Given
        apiClient.resumeResponse = .success(.pendingStatusWithShowSuccess)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        let payment = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
        XCTAssert(payment.status == .pending)
    }

    func test_resumePayment_shouldSucceedWhenCheckoutComplete() async throws {
        // Given
        apiClient.resumeResponse = .success(.checkoutComplete)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        let payment = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
        XCTAssert(payment.status == .success)
    }

    func test_resumePayment_shouldFailWhenCheckoutFailure() async throws {
        // Given
        apiClient.resumeResponse = .success(.checkoutFailure)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        do {
            _ = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_resumePayment_shouldSucceedWhenFallbackWithSuccessStatus() async throws {
        // Given
        apiClient.resumeResponse = .success(.fallbackWithSuccessStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        let payment = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
        XCTAssert(payment.status == .success)
    }

    func test_resumePayment_shouldFailWhenFallbackWithFailedStatus() async throws {
        // Given
        apiClient.resumeResponse = .success(.fallbackWithFailedStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        do {
            _ = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_resumePayment_shouldFailWhenFallbackWithPendingStatus() async throws {
        // Given
        apiClient.resumeResponse = .success(.fallbackWithPendingStatus)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        do {
            _ = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }
    }

    func test_resumePayment_shouldSucceedWhenFallbackWithPendingStatusWithShowSuccess() async throws {
        // Given
        apiClient.resumeResponse = .success(.fallbackWithPendingStatusWithShowSuccess)
        AppState.current.clientToken = MockAppState.mockClientToken
        let resumeRequest = Request.Body.Payment.Resume(token: "")

        // When
        let payment = try await sut.resumePaymentWithPaymentId("", paymentResumeRequest: resumeRequest)
        XCTAssert(payment.status == .pending)
    }
}

private extension Response.Body.Payment {
    static var noId: Response.Body.Payment {
        .init(id: nil,
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .success)
    }

    static var successStatus: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .success)
    }

    static var failedStatus: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .failed)
    }

    static var pendingStatus: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .pending)
    }

    static var pendingStatusWithShowSuccess: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .pending,
              showSuccessCheckoutOnPendingPayment: true)
    }

    static var checkoutComplete: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .success,
              checkoutOutcome: .complete)
    }

    static var checkoutFailure: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .failed,
              checkoutOutcome: .failure)
    }

    static var fallbackWithSuccessStatus: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .success,
              checkoutOutcome: .determineFromPaymentStatus)
    }

    static var fallbackWithFailedStatus: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .failed,
              checkoutOutcome: .determineFromPaymentStatus)
    }

    static var fallbackWithPendingStatus: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .pending,
              checkoutOutcome: .determineFromPaymentStatus)
    }

    static var fallbackWithPendingStatusWithShowSuccess: Response.Body.Payment {
        .init(id: "id",
              paymentId: "paymentId",
              amount: 1,
              currencyCode: "EUR",
              status: .pending,
              showSuccessCheckoutOnPendingPayment: true,
              checkoutOutcome: .determineFromPaymentStatus)
    }
}