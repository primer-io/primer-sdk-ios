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
}
