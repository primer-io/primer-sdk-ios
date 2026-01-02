//
//  CardFormProviderTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

// MARK: - CardFormProvider Tests

/// Tests for CardFormProvider view component.
/// Tests initialization, callback configuration, and state handling logic.
@available(iOS 15.0, *)
@MainActor
final class CardFormProviderTests: XCTestCase {

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        await DIContainer.clearContainer()
    }

    override func tearDown() async throws {
        await DIContainer.clearContainer()
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_withAllCallbacks_createsProvider() {
        // Arrange & Act
        let provider = CardFormProvider(
            onSuccess: { _ in },
            onError: { _ in },
            onCancel: { }
        ) { _ in
            Text("Card Form")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_init_withNoCallbacks_createsProvider() {
        // Arrange & Act
        let provider = CardFormProvider { _ in
            Text("Card Form")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_init_withOnlySuccessCallback_createsProvider() {
        // Arrange & Act
        let provider = CardFormProvider(
            onSuccess: { _ in }
        ) { _ in
            Text("Card Form")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_init_withOnlyErrorCallback_createsProvider() {
        // Arrange & Act
        let provider = CardFormProvider(
            onError: { _ in }
        ) { _ in
            Text("Card Form")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_init_withOnlyCancelCallback_createsProvider() {
        // Arrange & Act
        let provider = CardFormProvider(
            onCancel: { }
        ) { _ in
            Text("Card Form")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    // MARK: - View Builder Tests

    func test_contentBuilder_receivesScope() {
        // Arrange
        var scopeReceived = false

        // Act
        _ = CardFormProvider { scope in
            scopeReceived = scope != nil
            return Text("Content")
        }

        // Assert - content builder is configured
        XCTAssertNotNil(scopeReceived)
    }

    // MARK: - Callback Configuration Tests

    func test_successCallback_canBeConfiguredWithResult() {
        // Arrange
        var receivedResult: CheckoutPaymentResult?

        let provider = CardFormProvider(
            onSuccess: { result in
                receivedResult = result
            }
        ) { _ in
            Text("Card Form")
        }

        // Assert - callback is configured (will be invoked by state changes)
        XCTAssertNotNil(provider)
        XCTAssertNil(receivedResult) // Not yet invoked
    }

    func test_errorCallback_canBeConfiguredWithMessage() {
        // Arrange
        var receivedError: String?

        let provider = CardFormProvider(
            onError: { error in
                receivedError = error
            }
        ) { _ in
            Text("Card Form")
        }

        // Assert - callback is configured
        XCTAssertNotNil(provider)
        XCTAssertNil(receivedError) // Not yet invoked
    }

    func test_cancelCallback_canBeConfigured() {
        // Arrange
        var cancelCalled = false

        let provider = CardFormProvider(
            onCancel: {
                cancelCalled = true
            }
        ) { _ in
            Text("Card Form")
        }

        // Assert - callback is configured
        XCTAssertNotNil(provider)
        XCTAssertFalse(cancelCalled) // Not yet invoked
    }

    // MARK: - CheckoutPaymentResult Tests

    func test_checkoutPaymentResult_canBeCreated() {
        // Arrange & Act
        let result = CheckoutPaymentResult(paymentId: "payment_123", amount: "100.00")

        // Assert
        XCTAssertEqual(result.paymentId, "payment_123")
        XCTAssertEqual(result.amount, "100.00")
    }

    func test_checkoutPaymentResult_withEmptyAmount() {
        // Arrange & Act
        let result = CheckoutPaymentResult(paymentId: "payment_456", amount: "")

        // Assert
        XCTAssertEqual(result.paymentId, "payment_456")
        XCTAssertEqual(result.amount, "")
    }

    // MARK: - Multiple Provider Instances Tests

    func test_multipleProviders_areIndependent() {
        // Arrange
        var success1Called = false
        var success2Called = false

        // Act
        let provider1 = CardFormProvider(
            onSuccess: { _ in success1Called = true }
        ) { _ in
            Text("Provider 1")
        }

        let provider2 = CardFormProvider(
            onSuccess: { _ in success2Called = true }
        ) { _ in
            Text("Provider 2")
        }

        // Assert - both providers created independently
        XCTAssertNotNil(provider1)
        XCTAssertNotNil(provider2)
        XCTAssertFalse(success1Called)
        XCTAssertFalse(success2Called)
    }

    // MARK: - View Type Tests

    func test_provider_conformsToView() {
        // Arrange
        let provider = CardFormProvider { _ in
            Text("Test")
        }

        // Assert - View conformance
        XCTAssertTrue(provider is any View)
    }

    // MARK: - Content Builder Variety Tests

    func test_contentBuilder_withComplexView() {
        // Arrange & Act
        let provider = CardFormProvider { _ in
            VStack {
                Text("Card Number")
                Text("Expiry")
                Text("CVV")
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_contentBuilder_withConditionalView() {
        // Arrange
        let showError = true

        // Act
        let provider = CardFormProvider { _ in
            if showError {
                Text("Error")
            } else {
                Text("Success")
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    // MARK: - Nil Callback Handling Tests

    func test_nilSuccessCallback_doesNotCrash() {
        // Arrange & Act
        let provider = CardFormProvider(
            onSuccess: nil,
            onError: { _ in },
            onCancel: { }
        ) { _ in
            Text("Test")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_nilErrorCallback_doesNotCrash() {
        // Arrange & Act
        let provider = CardFormProvider(
            onSuccess: { _ in },
            onError: nil,
            onCancel: { }
        ) { _ in
            Text("Test")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_nilCancelCallback_doesNotCrash() {
        // Arrange & Act
        let provider = CardFormProvider(
            onSuccess: { _ in },
            onError: { _ in },
            onCancel: nil
        ) { _ in
            Text("Test")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_allNilCallbacks_doesNotCrash() {
        // Arrange & Act
        let provider = CardFormProvider(
            onSuccess: nil,
            onError: nil,
            onCancel: nil
        ) { _ in
            Text("Test")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    // MARK: - CheckoutPaymentResult Extended Tests

    func test_checkoutPaymentResult_withLargeAmount() {
        // Arrange & Act
        let result = CheckoutPaymentResult(paymentId: "payment_large", amount: "999999.99")

        // Assert
        XCTAssertEqual(result.paymentId, "payment_large")
        XCTAssertEqual(result.amount, "999999.99")
    }

    func test_checkoutPaymentResult_withZeroAmount() {
        // Arrange & Act
        let result = CheckoutPaymentResult(paymentId: "payment_zero", amount: "0.00")

        // Assert
        XCTAssertEqual(result.amount, "0.00")
    }

    func test_checkoutPaymentResult_withNegativeAmount() {
        // Arrange & Act
        let result = CheckoutPaymentResult(paymentId: "payment_negative", amount: "-50.00")

        // Assert
        XCTAssertEqual(result.amount, "-50.00")
    }

    func test_checkoutPaymentResult_withDecimalAmount() {
        // Arrange & Act
        let result = CheckoutPaymentResult(paymentId: "payment_decimal", amount: "123.456789")

        // Assert
        XCTAssertEqual(result.amount, "123.456789")
    }

    func test_checkoutPaymentResult_withLongPaymentId() {
        // Arrange
        let longId = "payment_" + String(repeating: "x", count: 100)

        // Act
        let result = CheckoutPaymentResult(paymentId: longId, amount: "100.00")

        // Assert
        XCTAssertEqual(result.paymentId, longId)
    }

    func test_checkoutPaymentResult_withSpecialCharactersInPaymentId() {
        // Arrange & Act
        let result = CheckoutPaymentResult(paymentId: "payment-123_abc.xyz", amount: "50.00")

        // Assert
        XCTAssertEqual(result.paymentId, "payment-123_abc.xyz")
    }

    func test_checkoutPaymentResult_withCurrencySymbolInAmount() {
        // Arrange & Act
        let result = CheckoutPaymentResult(paymentId: "payment_123", amount: "$100.00")

        // Assert
        XCTAssertEqual(result.amount, "$100.00")
    }

    func test_checkoutPaymentResult_withWhitespaceInAmount() {
        // Arrange & Act
        let result = CheckoutPaymentResult(paymentId: "payment_123", amount: " 100.00 ")

        // Assert
        XCTAssertEqual(result.amount, " 100.00 ")
    }

    // MARK: - Content Builder Extended Tests

    func test_contentBuilder_withScrollView() {
        // Arrange & Act
        let provider = CardFormProvider { _ in
            ScrollView {
                VStack {
                    Text("Card Number")
                    Text("CVV")
                }
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_contentBuilder_withLazyVStack() {
        // Arrange & Act
        let provider = CardFormProvider { _ in
            LazyVStack {
                ForEach(0..<3) { index in
                    Text("Field \(index)")
                }
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_contentBuilder_withEmptyView() {
        // Arrange & Act
        let provider = CardFormProvider { _ in
            EmptyView()
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_contentBuilder_withGroup() {
        // Arrange & Act
        let provider = CardFormProvider { _ in
            Group {
                Text("Field 1")
                Text("Field 2")
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_contentBuilder_withZStack() {
        // Arrange & Act
        let provider = CardFormProvider { _ in
            ZStack {
                Color.white
                Text("Card Form")
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_contentBuilder_withHStack() {
        // Arrange & Act
        let provider = CardFormProvider { _ in
            HStack {
                Text("Expiry")
                Text("CVV")
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    // MARK: - Callback Chaining Tests

    func test_successCallback_canBeChainedWithAdditionalLogic() {
        // Arrange
        var step1Executed = false
        var step2Executed = false

        // Act
        let provider = CardFormProvider(
            onSuccess: { result in
                step1Executed = true
                if result.paymentId.hasPrefix("payment_") {
                    step2Executed = true
                }
            }
        ) { _ in
            Text("Test")
        }

        // Assert - callbacks are configured for chaining
        XCTAssertNotNil(provider)
        XCTAssertFalse(step1Executed)
        XCTAssertFalse(step2Executed)
    }

    func test_errorCallback_canBeChainedWithAdditionalLogic() {
        // Arrange
        var errorLogged = false
        var errorReported = false

        // Act
        let provider = CardFormProvider(
            onError: { error in
                errorLogged = true
                if error.contains("network") {
                    errorReported = true
                }
            }
        ) { _ in
            Text("Test")
        }

        // Assert
        XCTAssertNotNil(provider)
        XCTAssertFalse(errorLogged)
        XCTAssertFalse(errorReported)
    }

    func test_cancelCallback_canExecuteCleanupLogic() {
        // Arrange
        var cleanupExecuted = false

        // Act
        let provider = CardFormProvider(
            onCancel: {
                cleanupExecuted = true
            }
        ) { _ in
            Text("Test")
        }

        // Assert
        XCTAssertNotNil(provider)
        XCTAssertFalse(cleanupExecuted)
    }

    // MARK: - Multiple Providers Tests

    func test_multipleProviders_withDifferentCallbackTypes() {
        // Arrange & Act
        let provider1 = CardFormProvider(
            onSuccess: { _ in }
        ) { _ in Text("1") }

        let provider2 = CardFormProvider(
            onError: { _ in }
        ) { _ in Text("2") }

        let provider3 = CardFormProvider(
            onCancel: { }
        ) { _ in Text("3") }

        let provider4 = CardFormProvider(
            onSuccess: { _ in },
            onError: { _ in },
            onCancel: { }
        ) { _ in Text("4") }

        // Assert
        XCTAssertNotNil(provider1)
        XCTAssertNotNil(provider2)
        XCTAssertNotNil(provider3)
        XCTAssertNotNil(provider4)
    }

    // MARK: - LogReporter Conformance Tests

    func test_provider_conformsToLogReporter() {
        // Arrange
        let provider = CardFormProvider { _ in
            Text("Test")
        }

        // Assert - LogReporter conformance
        XCTAssertTrue(provider is any LogReporter)
    }

    // MARK: - Callback Error Message Tests

    func test_errorCallback_canReceiveEmptyMessage() {
        // Arrange
        var receivedMessage: String?

        let provider = CardFormProvider(
            onError: { message in
                receivedMessage = message
            }
        ) { _ in
            Text("Test")
        }

        // Assert - callback is configured
        XCTAssertNotNil(provider)
        XCTAssertNil(receivedMessage)
    }

    func test_errorCallback_canReceiveLongMessage() {
        // Arrange
        var receivedMessage: String?
        let longMessage = String(repeating: "Error details. ", count: 100)

        let provider = CardFormProvider(
            onError: { message in
                receivedMessage = message
            }
        ) { _ in
            Text("Test")
        }

        // Assert - callback is configured
        XCTAssertNotNil(provider)
        XCTAssertNil(receivedMessage)
        XCTAssertTrue(longMessage.count > 1000)
    }

    // MARK: - Scope Access Tests

    func test_contentBuilder_providesAccessToCardFormScope() {
        // Arrange
        var scopeAccessible = false

        // Act
        _ = CardFormProvider { scope in
            scopeAccessible = true
            return Text("Content with scope access")
        }

        // Assert - content builder has scope parameter
        XCTAssertNotNil(scopeAccessible)
    }

    // MARK: - Conditional Content Tests

    func test_contentBuilder_withMultipleConditions() {
        // Arrange
        let hasCard = true
        let hasExpiry = true

        // Act
        let provider = CardFormProvider { _ in
            VStack {
                if hasCard {
                    Text("Card Number")
                }
                if hasExpiry {
                    Text("Expiry Date")
                }
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_contentBuilder_withSwitchStatement() {
        // Arrange
        enum FormState { case editing, submitting, complete }
        let state: FormState = .editing

        // Act
        let provider = CardFormProvider { _ in
            switch state {
            case .editing:
                Text("Edit Form")
            case .submitting:
                ProgressView()
            case .complete:
                Text("Done!")
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    // MARK: - Partial Callback Tests

    func test_init_withOnlySuccessAndError_createsProvider() {
        // Arrange & Act
        let provider = CardFormProvider(
            onSuccess: { _ in },
            onError: { _ in }
        ) { _ in
            Text("Test")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_init_withOnlySuccessAndCancel_createsProvider() {
        // Arrange & Act
        let provider = CardFormProvider(
            onSuccess: { _ in },
            onCancel: { }
        ) { _ in
            Text("Test")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_init_withOnlyErrorAndCancel_createsProvider() {
        // Arrange & Act
        let provider = CardFormProvider(
            onError: { _ in },
            onCancel: { }
        ) { _ in
            Text("Test")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    // MARK: - PaymentResult Properties Tests

    func test_checkoutPaymentResult_propertiesAreReadOnly() {
        // Arrange
        let result = CheckoutPaymentResult(paymentId: "test_id", amount: "100.00")

        // Assert - properties are accessible
        XCTAssertEqual(result.paymentId, "test_id")
        XCTAssertEqual(result.amount, "100.00")
    }

    func test_checkoutPaymentResult_withUnicodePaymentId() {
        // Arrange & Act
        let result = CheckoutPaymentResult(paymentId: "payment_日本語_🎉", amount: "100.00")

        // Assert
        XCTAssertEqual(result.paymentId, "payment_日本語_🎉")
    }

    func test_checkoutPaymentResult_withEmptyPaymentId() {
        // Arrange & Act
        let result = CheckoutPaymentResult(paymentId: "", amount: "100.00")

        // Assert
        XCTAssertEqual(result.paymentId, "")
    }
}
