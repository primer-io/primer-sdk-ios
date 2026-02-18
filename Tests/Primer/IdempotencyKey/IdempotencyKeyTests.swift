//
//  IdempotencyKeyTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerNetworking
@testable import PrimerSDK
import XCTest

final class IdempotencyKeyTests: XCTestCase {

    override func setUp() {
        super.setUp()
        SDKSessionHelper.setUp()
        PrimerInternal.shared.currentIdempotencyKey = nil
    }

    override func tearDown() {
        PrimerInternal.shared.currentIdempotencyKey = nil
        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    // MARK: - PrimerPaymentCreationDecision Tests

    func test_continuePaymentCreation_withoutKey_shouldDefaultToNil() {
        // Given / When
        let decision = PrimerPaymentCreationDecision.continuePaymentCreation()

        // Then
        switch decision.type {
        case let .continue(idempotencyKey):
            XCTAssertNil(idempotencyKey)
        case .abort:
            XCTFail("Expected continue but got abort")
        }
    }

    func test_continuePaymentCreation_withKey_shouldStoreKey() {
        // Given
        let expectedKey = "test-idempotency-key-123"

        // When
        let decision = PrimerPaymentCreationDecision.continuePaymentCreation(
            withIdempotencyKey: expectedKey
        )

        // Then
        switch decision.type {
        case let .continue(idempotencyKey):
            XCTAssertEqual(idempotencyKey, expectedKey)
        case .abort:
            XCTFail("Expected continue but got abort")
        }
    }

    func test_abortPaymentCreation_shouldRetainErrorMessage() {
        // Given
        let errorMessage = "Payment cancelled by user"

        // When
        let decision = PrimerPaymentCreationDecision.abortPaymentCreation(
            withErrorMessage: errorMessage
        )

        // Then
        switch decision.type {
        case let .abort(message):
            XCTAssertEqual(message, errorMessage)
        case .continue:
            XCTFail("Expected abort but got continue")
        }
    }

    // MARK: - PrimerInternal Storage Tests

    func test_currentIdempotencyKey_shouldStoreAndRetrieveValue() {
        // Given
        let key = "unique-key-456"

        // When
        PrimerInternal.shared.currentIdempotencyKey = key

        // Then
        XCTAssertEqual(PrimerInternal.shared.currentIdempotencyKey, key)
    }

    func test_currentIdempotencyKey_shouldBeNilByDefault() {
        // Then
        XCTAssertNil(PrimerInternal.shared.currentIdempotencyKey)
    }

    // MARK: - PrimerAPI Header Tests

    func test_createPayment_shouldIncludeIdempotencyKeyHeader_whenKeyIsSet() {
        // Given
        let expectedKey = "idempotency-key-789"
        PrimerInternal.shared.currentIdempotencyKey = expectedKey

        let body = Request.Body.Payment.Create(token: "test_token")
        let endpoint = PrimerAPI.createPayment(
            clientToken: Mocks.decodedJWTToken,
            paymentRequest: body
        )

        // When
        let headers = endpoint.headers

        // Then
        XCTAssertEqual(headers?["X-Idempotency-Key"], expectedKey)
    }

    func test_createPayment_shouldNotIncludeIdempotencyKeyHeader_whenKeyIsNil() {
        // Given
        PrimerInternal.shared.currentIdempotencyKey = nil

        let body = Request.Body.Payment.Create(token: "test_token")
        let endpoint = PrimerAPI.createPayment(
            clientToken: Mocks.decodedJWTToken,
            paymentRequest: body
        )

        // When
        let headers = endpoint.headers

        // Then
        XCTAssertNil(headers?["X-Idempotency-Key"])
    }

    func test_resumePayment_shouldNotIncludeIdempotencyKeyHeader_evenWhenKeyIsSet() {
        // Given
        PrimerInternal.shared.currentIdempotencyKey = "should-not-appear"

        let endpoint = PrimerAPI.resumePayment(
            clientToken: Mocks.decodedJWTToken,
            paymentId: "payment_id",
            paymentResumeRequest: Request.Body.Payment.Resume(token: "token")
        )

        // When
        let headers = endpoint.headers

        // Then
        XCTAssertNil(headers?["X-Idempotency-Key"])
    }

    func test_createPayment_shouldStillIncludeClientTokenHeader_withIdempotencyKey() {
        // Given
        PrimerInternal.shared.currentIdempotencyKey = "some-key"

        let body = Request.Body.Payment.Create(token: "test_token")
        let endpoint = PrimerAPI.createPayment(
            clientToken: Mocks.decodedJWTToken,
            paymentRequest: body
        )

        // When
        let headers = endpoint.headers

        // Then
        XCTAssertNotNil(headers?["Primer-Client-Token"])
        XCTAssertNotNil(headers?["X-Idempotency-Key"])
    }

    // MARK: - CreateResumePaymentService Clearing Tests

    func test_createPayment_shouldClearIdempotencyKey_afterSuccess() async throws {
        // Given
        let apiClient = MockCreateResumeAPIClient()
        apiClient.createResponse = .success(.init(
            id: "id",
            paymentId: "paymentId",
            amount: 1,
            currencyCode: "EUR",
            status: .success
        ))
        AppState.current.clientToken = MockAppState.mockClientToken
        PrimerInternal.shared.currentIdempotencyKey = "key-to-clear"

        let sut = CreateResumePaymentService(
            paymentMethodType: "PAYMENT_CARD",
            apiClient: apiClient
        )

        // When
        _ = try await sut.createPayment(
            paymentRequest: Request.Body.Payment.Create(token: "123")
        )

        // Then
        XCTAssertNil(PrimerInternal.shared.currentIdempotencyKey)
    }

    func test_createPayment_shouldClearIdempotencyKey_afterFailure() async throws {
        // Given
        let apiClient = MockCreateResumeAPIClient()
        apiClient.createResponse = .failure(PrimerError.unknown())
        AppState.current.clientToken = MockAppState.mockClientToken
        PrimerInternal.shared.currentIdempotencyKey = "key-to-clear-on-error"

        let sut = CreateResumePaymentService(
            paymentMethodType: "PAYMENT_CARD",
            apiClient: apiClient
        )

        // When
        do {
            _ = try await sut.createPayment(
                paymentRequest: Request.Body.Payment.Create(token: "123")
            )
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }

        // Then
        XCTAssertNil(PrimerInternal.shared.currentIdempotencyKey)
    }

    func test_createPayment_shouldClearIdempotencyKey_whenClientTokenIsNil() async throws {
        // Given
        let apiClient = MockCreateResumeAPIClient()
        AppState.current.clientToken = nil
        PrimerInternal.shared.currentIdempotencyKey = "key-to-clear-no-token"

        let sut = CreateResumePaymentService(
            paymentMethodType: "PAYMENT_CARD",
            apiClient: apiClient
        )

        // When
        do {
            _ = try await sut.createPayment(
                paymentRequest: Request.Body.Payment.Create(token: "123")
            )
            XCTFail("Expected failure but got success")
        } catch {
            // Expected error
        }

        // Then
        XCTAssertNil(PrimerInternal.shared.currentIdempotencyKey)
    }

    // MARK: - NetworkRequestFactory Integration Tests

    func test_networkRequest_createPayment_shouldIncludeIdempotencyKeyHeader() throws {
        // Given
        PrimerInternal.shared.currentIdempotencyKey = "network-test-key"
        let factory = DefaultNetworkRequestFactory()
        let body = Request.Body.Payment.Create(token: "test_token")
        let endpoint = PrimerAPI.createPayment(
            clientToken: Mocks.decodedJWTToken,
            paymentRequest: body
        )

        // When
        let request = try factory.request(for: endpoint, identifier: nil)

        // Then
        XCTAssertEqual(request.allHTTPHeaderFields?["X-Idempotency-Key"], "network-test-key")
    }

    func test_networkRequest_resumePayment_shouldNotIncludeIdempotencyKeyHeader() throws {
        // Given
        PrimerInternal.shared.currentIdempotencyKey = "should-not-appear-in-resume"
        let factory = DefaultNetworkRequestFactory()
        let endpoint = PrimerAPI.resumePayment(
            clientToken: Mocks.decodedJWTToken,
            paymentId: "payment_id",
            paymentResumeRequest: Request.Body.Payment.Resume(token: "token")
        )

        // When
        let request = try factory.request(for: endpoint, identifier: nil)

        // Then
        XCTAssertNil(request.allHTTPHeaderFields?["X-Idempotency-Key"])
    }
}
