//
//  ProcessFormRedirectPaymentInteractorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class ProcessFormRedirectPaymentInteractorTests: XCTestCase {

    // MARK: - Properties

    private var sut: ProcessFormRedirectPaymentInteractorImpl!
    private var mockRepository: MockFormRedirectRepository!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockRepository = MockFormRedirectRepository()
        sut = ProcessFormRedirectPaymentInteractorImpl(formRedirectRepository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - BLIK Payment Tests

    func test_execute_blikPayment_callsTokenize() async throws {
        // Given
        let sessionInfo = FormRedirectTestData.blikSessionInfo

        // When
        _ = try await sut.execute(
            paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
            sessionInfo: sessionInfo
        )

        // Then
        XCTAssertEqual(mockRepository.tokenizeCallCount, 1)
        XCTAssertEqual(mockRepository.tokenizePaymentMethodType, FormRedirectTestData.Constants.blikPaymentMethodType)
    }

    func test_execute_blikPayment_passesBlikSessionInfo() async throws {
        // Given
        let sessionInfo = FormRedirectTestData.blikSessionInfo

        // When
        _ = try await sut.execute(
            paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
            sessionInfo: sessionInfo
        )

        // Then
        XCTAssertTrue(mockRepository.tokenizeSessionInfo is BlikSessionInfo)
        if let passedSessionInfo = mockRepository.tokenizeSessionInfo as? BlikSessionInfo {
            XCTAssertEqual(passedSessionInfo.blikCode, FormRedirectTestData.Constants.validBlikCode)
        }
    }

    func test_execute_blikPayment_callsCreatePayment() async throws {
        // Given
        let sessionInfo = FormRedirectTestData.blikSessionInfo
        mockRepository.createPaymentResult = .success(FormRedirectTestData.successPaymentResponse)

        // When
        _ = try await sut.execute(
            paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
            sessionInfo: sessionInfo
        )

        // Then
        XCTAssertEqual(mockRepository.createPaymentCallCount, 1)
        XCTAssertEqual(mockRepository.createPaymentPaymentMethodType, FormRedirectTestData.Constants.blikPaymentMethodType)
        XCTAssertNotNil(mockRepository.createPaymentToken)
    }

    func test_execute_blikPayment_withPendingStatusAndStatusUrl_pollsForCompletion() async throws {
        // Given
        let sessionInfo = FormRedirectTestData.blikSessionInfo
        mockRepository.createPaymentResult = .success(FormRedirectTestData.pendingPaymentResponse)
        mockRepository.resumePaymentResult = .success(FormRedirectTestData.successPaymentResponse)

        // When
        _ = try await sut.execute(
            paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
            sessionInfo: sessionInfo
        )

        // Then
        XCTAssertEqual(mockRepository.pollForCompletionCallCount, 1)
        XCTAssertEqual(mockRepository.pollForCompletionStatusUrl, FormRedirectTestData.Constants.statusUrl)
    }

    func test_execute_blikPayment_withPendingStatusAndStatusUrl_resumesPayment() async throws {
        // Given
        let sessionInfo = FormRedirectTestData.blikSessionInfo
        mockRepository.createPaymentResult = .success(FormRedirectTestData.pendingPaymentResponse)
        mockRepository.resumePaymentResult = .success(FormRedirectTestData.successPaymentResponse)

        // When
        _ = try await sut.execute(
            paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
            sessionInfo: sessionInfo
        )

        // Then
        XCTAssertEqual(mockRepository.resumePaymentCallCount, 1)
        XCTAssertEqual(mockRepository.resumePaymentPaymentId, FormRedirectTestData.Constants.paymentId)
        XCTAssertEqual(mockRepository.resumePaymentResumeToken, FormRedirectTestData.Constants.resumeToken)
        XCTAssertEqual(mockRepository.resumePaymentPaymentMethodType, FormRedirectTestData.Constants.blikPaymentMethodType)
    }

    func test_execute_blikPayment_withPendingStatusAndStatusUrl_callsPollingStartedCallback() async throws {
        // Given
        let sessionInfo = FormRedirectTestData.blikSessionInfo
        mockRepository.createPaymentResult = .success(FormRedirectTestData.pendingPaymentResponse)
        mockRepository.resumePaymentResult = .success(FormRedirectTestData.successPaymentResponse)
        var callbackCalled = false

        // When
        _ = try await sut.execute(
            paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
            sessionInfo: sessionInfo,
            onPollingStarted: {
                callbackCalled = true
            }
        )

        // Then
        XCTAssertTrue(callbackCalled, "onPollingStarted callback should be called when polling begins")
    }

    func test_execute_blikPayment_withSuccessStatus_doesNotCallPollingStartedCallback() async throws {
        // Given
        let sessionInfo = FormRedirectTestData.blikSessionInfo
        mockRepository.createPaymentResult = .success(FormRedirectTestData.successPaymentResponse)
        var callbackCalled = false

        // When
        _ = try await sut.execute(
            paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
            sessionInfo: sessionInfo,
            onPollingStarted: {
                callbackCalled = true
            }
        )

        // Then
        XCTAssertFalse(callbackCalled, "onPollingStarted callback should not be called when payment succeeds immediately")
    }

    func test_execute_blikPayment_withSuccessStatus_doesNotPoll() async throws {
        // Given
        let sessionInfo = FormRedirectTestData.blikSessionInfo
        mockRepository.createPaymentResult = .success(FormRedirectTestData.successPaymentResponse)

        // When
        _ = try await sut.execute(
            paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
            sessionInfo: sessionInfo
        )

        // Then
        XCTAssertEqual(mockRepository.pollForCompletionCallCount, 0)
        XCTAssertEqual(mockRepository.resumePaymentCallCount, 0)
    }

    func test_execute_blikPayment_withPendingStatusWithoutStatusUrl_throwsError() async {
        // Given
        let sessionInfo = FormRedirectTestData.blikSessionInfo
        mockRepository.createPaymentResult = .success(FormRedirectTestData.pendingPaymentResponseWithoutStatusUrl)

        // When / Then
        do {
            _ = try await sut.execute(
                paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
                sessionInfo: sessionInfo
            )
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case let .invalidValue(key, _, _, _):
                XCTAssertEqual(key, "statusUrl")
            default:
                XCTFail("Expected invalidValue error, got \(error)")
            }
        } catch {
            XCTFail("Expected PrimerError, got \(error)")
        }

        XCTAssertEqual(mockRepository.pollForCompletionCallCount, 0)
        XCTAssertEqual(mockRepository.resumePaymentCallCount, 0)
    }

    func test_execute_blikPayment_returnsPaymentResult() async throws {
        // Given
        let sessionInfo = FormRedirectTestData.blikSessionInfo
        mockRepository.createPaymentResult = .success(FormRedirectTestData.successPaymentResponse)

        // When
        let result = try await sut.execute(
            paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
            sessionInfo: sessionInfo
        )

        // Then
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.paymentMethodType, FormRedirectTestData.Constants.blikPaymentMethodType)
        XCTAssertEqual(result.paymentId, FormRedirectTestData.Constants.paymentId)
    }

    // MARK: - Error Handling Tests

    func test_execute_tokenizationFails_throwsError() async {
        // Given
        let sessionInfo = FormRedirectTestData.blikSessionInfo
        let expectedError = PrimerError.unknown(message: "Tokenization failed")
        mockRepository.tokenizeResult = .failure(expectedError)

        // When / Then
        do {
            _ = try await sut.execute(
                paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
                sessionInfo: sessionInfo
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    func test_execute_createPaymentFails_throwsError() async {
        // Given
        let sessionInfo = FormRedirectTestData.blikSessionInfo
        let expectedError = PrimerError.unknown(message: "Payment creation failed")
        mockRepository.createPaymentResult = .failure(expectedError)

        // When / Then
        do {
            _ = try await sut.execute(
                paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
                sessionInfo: sessionInfo
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    func test_execute_paymentStatusFailed_throwsPaymentFailedError() async {
        // Given
        let sessionInfo = FormRedirectTestData.blikSessionInfo
        mockRepository.createPaymentResult = .success(FormRedirectTestData.failedPaymentResponse)

        // When / Then
        do {
            _ = try await sut.execute(
                paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
                sessionInfo: sessionInfo
            )
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case let .paymentFailed(paymentMethodType, paymentId, _, status, _):
                XCTAssertEqual(paymentMethodType, FormRedirectTestData.Constants.blikPaymentMethodType)
                XCTAssertEqual(paymentId, FormRedirectTestData.Constants.paymentId)
                XCTAssertEqual(status, "FAILED")
            default:
                XCTFail("Expected paymentFailed error, got \(error)")
            }
        } catch {
            XCTFail("Expected PrimerError, got \(error)")
        }
    }

    func test_execute_pollingFails_throwsError() async {
        // Given
        let sessionInfo = FormRedirectTestData.blikSessionInfo
        mockRepository.createPaymentResult = .success(FormRedirectTestData.pendingPaymentResponse)
        let expectedError = PrimerError.unknown(message: "Polling failed")
        mockRepository.pollForCompletionResult = .failure(expectedError)

        // When / Then
        do {
            _ = try await sut.execute(
                paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
                sessionInfo: sessionInfo
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    func test_execute_resumePaymentFailed_throwsPaymentFailedError() async {
        // Given
        let sessionInfo = FormRedirectTestData.blikSessionInfo
        mockRepository.createPaymentResult = .success(FormRedirectTestData.pendingPaymentResponse)
        mockRepository.resumePaymentResult = .success(FormRedirectTestData.failedPaymentResponse)

        // When / Then
        do {
            _ = try await sut.execute(
                paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
                sessionInfo: sessionInfo
            )
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case let .paymentFailed(paymentMethodType, _, _, status, _):
                XCTAssertEqual(paymentMethodType, FormRedirectTestData.Constants.blikPaymentMethodType)
                XCTAssertEqual(status, "FAILED")
            default:
                XCTFail("Expected paymentFailed error, got \(error)")
            }
        } catch {
            XCTFail("Expected PrimerError, got \(error)")
        }
    }

    // MARK: - Tokenization Nil Token Tests

    func test_execute_tokenizationReturnsNilToken_throwsInvalidValueError() async {
        // Given
        let sessionInfo = FormRedirectTestData.blikSessionInfo
        let tokenDataWithNilToken = PrimerPaymentMethodTokenData(
            analyticsId: "analytics_123",
            id: FormRedirectTestData.Constants.paymentId,
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .offSession,
            paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: nil,
            tokenType: .singleUse,
            vaultData: nil
        )
        mockRepository.tokenizeResult = .success(
            FormRedirectTokenizationResponse(tokenData: tokenDataWithNilToken)
        )

        // When / Then
        do {
            _ = try await sut.execute(
                paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
                sessionInfo: sessionInfo
            )
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case let .invalidValue(key, _, _, _):
                XCTAssertEqual(key, "token")
            default:
                XCTFail("Expected invalidValue error for nil token, got \(error)")
            }
        } catch {
            XCTFail("Expected PrimerError, got \(error)")
        }

        XCTAssertEqual(mockRepository.createPaymentCallCount, 0)
    }

    // MARK: - Cancel Polling Tests

    func test_cancelPolling_delegatesToRepository() {
        sut.cancelPolling(paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType)

        XCTAssertEqual(mockRepository.cancelPollingCallCount, 1)
        if case let .cancelled(paymentMethodType, _) = mockRepository.cancelPollingError {
            XCTAssertEqual(paymentMethodType, FormRedirectTestData.Constants.blikPaymentMethodType)
        } else {
            XCTFail("Expected cancelled error")
        }
    }
}
