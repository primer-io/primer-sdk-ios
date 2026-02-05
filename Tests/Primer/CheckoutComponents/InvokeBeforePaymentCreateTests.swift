//
//  InvokeBeforePaymentCreateTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class InvokeBeforePaymentCreateTests: XCTestCase {

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

    // MARK: - onBeforePaymentCreate Property Tests

    @MainActor
    func test_onBeforePaymentCreate_isNilByDefault() {
        // Given
        let scope = createScope()

        // Then
        XCTAssertNil(scope.onBeforePaymentCreate)
    }

    @MainActor
    func test_onBeforePaymentCreate_canBeSet() {
        // Given
        let scope = createScope()

        // When
        scope.onBeforePaymentCreate = { _, decisionHandler in
            decisionHandler(.continuePaymentCreation())
        }

        // Then
        XCTAssertNotNil(scope.onBeforePaymentCreate)
    }

    @MainActor
    func test_onBeforePaymentCreate_canBeSetToNil() {
        // Given
        let scope = createScope()
        scope.onBeforePaymentCreate = { _, decisionHandler in
            decisionHandler(.continuePaymentCreation())
        }

        // When
        scope.onBeforePaymentCreate = nil

        // Then
        XCTAssertNil(scope.onBeforePaymentCreate)
    }

    // MARK: - invokeBeforePaymentCreate Tests

    @MainActor
    func test_invokeBeforePaymentCreate_whenCallbackIsNil_shouldNotThrow() async throws {
        // Given
        let scope = createScope()
        scope.onBeforePaymentCreate = nil

        // When / Then — should not throw
        try await scope.invokeBeforePaymentCreate(paymentMethodType: "PAYMENT_CARD")
    }

    @MainActor
    func test_invokeBeforePaymentCreate_whenCallbackIsNil_shouldNotSetIdempotencyKey() async throws {
        // Given
        let scope = createScope()
        scope.onBeforePaymentCreate = nil

        // When
        try await scope.invokeBeforePaymentCreate(paymentMethodType: "PAYMENT_CARD")

        // Then
        XCTAssertNil(PrimerInternal.shared.currentIdempotencyKey)
    }

    @MainActor
    func test_invokeBeforePaymentCreate_withContinueAndKey_shouldStoreIdempotencyKey() async throws {
        // Given
        let expectedKey = "cc-test-key-123"
        let scope = createScope()
        scope.onBeforePaymentCreate = { _, decisionHandler in
            decisionHandler(.continuePaymentCreation(withIdempotencyKey: expectedKey))
        }

        // When
        try await scope.invokeBeforePaymentCreate(paymentMethodType: "PAYMENT_CARD")

        // Then
        XCTAssertEqual(PrimerInternal.shared.currentIdempotencyKey, expectedKey)
    }

    @MainActor
    func test_invokeBeforePaymentCreate_withContinueWithoutKey_shouldStoreNilIdempotencyKey() async throws {
        // Given
        let scope = createScope()
        scope.onBeforePaymentCreate = { _, decisionHandler in
            decisionHandler(.continuePaymentCreation())
        }

        // When
        try await scope.invokeBeforePaymentCreate(paymentMethodType: "PAYMENT_CARD")

        // Then
        XCTAssertNil(PrimerInternal.shared.currentIdempotencyKey)
    }

    @MainActor
    func test_invokeBeforePaymentCreate_withAbort_shouldThrowMerchantError() async {
        // Given
        let scope = createScope()
        scope.onBeforePaymentCreate = { _, decisionHandler in
            decisionHandler(.abortPaymentCreation(withErrorMessage: "User cancelled"))
        }

        // When / Then
        do {
            try await scope.invokeBeforePaymentCreate(paymentMethodType: "PAYMENT_CARD")
            XCTFail("Expected error but got success")
        } catch {
            guard let primerError = error as? PrimerError else {
                XCTFail("Expected PrimerError but got \(type(of: error))")
                return
            }
            if case let .merchantError(message, _) = primerError {
                XCTAssertEqual(message, "User cancelled")
            } else {
                XCTFail("Expected merchantError but got \(primerError)")
            }
        }
    }

    @MainActor
    func test_invokeBeforePaymentCreate_withAbortNilMessage_shouldThrowDefaultMessage() async {
        // Given
        let scope = createScope()
        scope.onBeforePaymentCreate = { _, decisionHandler in
            decisionHandler(.abortPaymentCreation(withErrorMessage: nil))
        }

        // When / Then
        do {
            try await scope.invokeBeforePaymentCreate(paymentMethodType: "PAYMENT_CARD")
            XCTFail("Expected error but got success")
        } catch {
            guard let primerError = error as? PrimerError else {
                XCTFail("Expected PrimerError but got \(type(of: error))")
                return
            }
            if case let .merchantError(message, _) = primerError {
                XCTAssertEqual(message, "Payment creation aborted")
            } else {
                XCTFail("Expected merchantError but got \(primerError)")
            }
        }
    }

    @MainActor
    func test_invokeBeforePaymentCreate_shouldPassCorrectPaymentMethodType() async throws {
        // Given
        var receivedType: String?
        let scope = createScope()
        scope.onBeforePaymentCreate = { data, decisionHandler in
            receivedType = data.paymentMethodType.type
            decisionHandler(.continuePaymentCreation())
        }

        // When
        try await scope.invokeBeforePaymentCreate(paymentMethodType: "APPLE_PAY")

        // Then
        XCTAssertEqual(receivedType, "APPLE_PAY")
    }

    @MainActor
    func test_invokeBeforePaymentCreate_shouldPassCorrectPaymentMethodType_forKlarna() async throws {
        // Given
        var receivedType: String?
        let scope = createScope()
        scope.onBeforePaymentCreate = { data, decisionHandler in
            receivedType = data.paymentMethodType.type
            decisionHandler(.continuePaymentCreation())
        }

        // When
        try await scope.invokeBeforePaymentCreate(paymentMethodType: "KLARNA")

        // Then
        XCTAssertEqual(receivedType, "KLARNA")
    }

    @MainActor
    func test_invokeBeforePaymentCreate_withAbort_shouldNotStoreIdempotencyKey() async {
        // Given
        let scope = createScope()
        scope.onBeforePaymentCreate = { _, decisionHandler in
            decisionHandler(.abortPaymentCreation(withErrorMessage: "cancelled"))
        }

        // When
        do {
            try await scope.invokeBeforePaymentCreate(paymentMethodType: "PAYMENT_CARD")
        } catch {
            // Expected error
        }

        // Then
        XCTAssertNil(PrimerInternal.shared.currentIdempotencyKey)
    }

    @MainActor
    func test_invokeBeforePaymentCreate_calledTwice_shouldOverwriteKey() async throws {
        // Given
        let scope = createScope()
        scope.onBeforePaymentCreate = { _, decisionHandler in
            decisionHandler(.continuePaymentCreation(withIdempotencyKey: "first-key"))
        }
        try await scope.invokeBeforePaymentCreate(paymentMethodType: "PAYMENT_CARD")
        XCTAssertEqual(PrimerInternal.shared.currentIdempotencyKey, "first-key")

        // When — change callback and invoke again
        scope.onBeforePaymentCreate = { _, decisionHandler in
            decisionHandler(.continuePaymentCreation(withIdempotencyKey: "second-key"))
        }
        try await scope.invokeBeforePaymentCreate(paymentMethodType: "PAYMENT_CARD")

        // Then
        XCTAssertEqual(PrimerInternal.shared.currentIdempotencyKey, "second-key")
    }

    @MainActor
    func test_invokeBeforePaymentCreate_continueWithKey_thenContinueWithoutKey_shouldClearKey() async throws {
        // Given
        let scope = createScope()
        scope.onBeforePaymentCreate = { _, decisionHandler in
            decisionHandler(.continuePaymentCreation(withIdempotencyKey: "some-key"))
        }
        try await scope.invokeBeforePaymentCreate(paymentMethodType: "PAYMENT_CARD")
        XCTAssertEqual(PrimerInternal.shared.currentIdempotencyKey, "some-key")

        // When — change to no key
        scope.onBeforePaymentCreate = { _, decisionHandler in
            decisionHandler(.continuePaymentCreation())
        }
        try await scope.invokeBeforePaymentCreate(paymentMethodType: "PAYMENT_CARD")

        // Then
        XCTAssertNil(PrimerInternal.shared.currentIdempotencyKey)
    }

    // MARK: - Helper

    @MainActor
    private func createScope() -> DefaultCheckoutScope {
        DefaultCheckoutScope(
            clientToken: "mock_token",
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )
    }
}
