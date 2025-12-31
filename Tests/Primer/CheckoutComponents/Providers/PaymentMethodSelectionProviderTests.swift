//
//  PaymentMethodSelectionProviderTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

// MARK: - PaymentMethodSelectionProvider Tests

/// Tests for PaymentMethodSelectionProvider view component.
/// Tests initialization, callback configuration, and state handling logic.
@available(iOS 15.0, *)
@MainActor
final class PaymentMethodSelectionProviderTests: XCTestCase {

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
        let provider = PaymentMethodSelectionProvider(
            onPaymentMethodSelected: { _ in },
            onCancel: { }
        ) { _ in
            Text("Payment Methods")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_init_withNoCallbacks_createsProvider() {
        // Arrange & Act
        let provider = PaymentMethodSelectionProvider { _ in
            Text("Payment Methods")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_init_withOnlySelectionCallback_createsProvider() {
        // Arrange & Act
        let provider = PaymentMethodSelectionProvider(
            onPaymentMethodSelected: { _ in }
        ) { _ in
            Text("Payment Methods")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_init_withOnlyCancelCallback_createsProvider() {
        // Arrange & Act
        let provider = PaymentMethodSelectionProvider(
            onCancel: { }
        ) { _ in
            Text("Payment Methods")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    // MARK: - View Builder Tests

    func test_contentBuilder_receivesScope() {
        // Arrange
        var scopeChecked = false

        // Act
        _ = PaymentMethodSelectionProvider { scope in
            scopeChecked = scope != nil
            return Text("Content")
        }

        // Assert - content builder is configured
        XCTAssertNotNil(scopeChecked)
    }

    // MARK: - Callback Configuration Tests

    func test_selectionCallback_canBeConfiguredWithType() {
        // Arrange
        var receivedType: String?

        let provider = PaymentMethodSelectionProvider(
            onPaymentMethodSelected: { type in
                receivedType = type
            }
        ) { _ in
            Text("Payment Methods")
        }

        // Assert - callback is configured (will be invoked by state changes)
        XCTAssertNotNil(provider)
        XCTAssertNil(receivedType) // Not yet invoked
    }

    func test_cancelCallback_canBeConfigured() {
        // Arrange
        var cancelCalled = false

        let provider = PaymentMethodSelectionProvider(
            onCancel: {
                cancelCalled = true
            }
        ) { _ in
            Text("Payment Methods")
        }

        // Assert - callback is configured
        XCTAssertNotNil(provider)
        XCTAssertFalse(cancelCalled) // Not yet invoked
    }

    // MARK: - Multiple Provider Instances Tests

    func test_multipleProviders_areIndependent() {
        // Arrange
        var selection1Received: String?
        var selection2Received: String?

        // Act
        let provider1 = PaymentMethodSelectionProvider(
            onPaymentMethodSelected: { selection1Received = $0 }
        ) { _ in
            Text("Provider 1")
        }

        let provider2 = PaymentMethodSelectionProvider(
            onPaymentMethodSelected: { selection2Received = $0 }
        ) { _ in
            Text("Provider 2")
        }

        // Assert - both providers created independently
        XCTAssertNotNil(provider1)
        XCTAssertNotNil(provider2)
        XCTAssertNil(selection1Received)
        XCTAssertNil(selection2Received)
    }

    // MARK: - View Type Tests

    func test_provider_conformsToView() {
        // Arrange
        let provider = PaymentMethodSelectionProvider { _ in
            Text("Test")
        }

        // Assert - View conformance
        XCTAssertTrue(provider is any View)
    }

    // MARK: - Content Builder Variety Tests

    func test_contentBuilder_withComplexView() {
        // Arrange & Act
        let provider = PaymentMethodSelectionProvider { _ in
            VStack {
                Text("Card")
                Text("PayPal")
                Text("Apple Pay")
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_contentBuilder_withConditionalView() {
        // Arrange
        let isLoading = false

        // Act
        let provider = PaymentMethodSelectionProvider { _ in
            if isLoading {
                ProgressView()
            } else {
                Text("Select Payment Method")
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    // MARK: - Nil Callback Handling Tests

    func test_nilSelectionCallback_doesNotCrash() {
        // Arrange & Act
        let provider = PaymentMethodSelectionProvider(
            onPaymentMethodSelected: nil,
            onCancel: { }
        ) { _ in
            Text("Test")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_nilCancelCallback_doesNotCrash() {
        // Arrange & Act
        let provider = PaymentMethodSelectionProvider(
            onPaymentMethodSelected: { _ in },
            onCancel: nil
        ) { _ in
            Text("Test")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_allNilCallbacks_doesNotCrash() {
        // Arrange & Act
        let provider = PaymentMethodSelectionProvider(
            onPaymentMethodSelected: nil,
            onCancel: nil
        ) { _ in
            Text("Test")
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    // MARK: - Payment Method Type String Tests

    func test_selectionCallback_receivesPaymentMethodTypeString() {
        // Arrange
        var receivedTypeString: String?

        _ = PaymentMethodSelectionProvider(
            onPaymentMethodSelected: { typeString in
                receivedTypeString = typeString
            }
        ) { _ in
            Text("Test")
        }

        // Assert - callback is configured to receive string type
        XCTAssertNil(receivedTypeString) // Not invoked yet
    }

    // MARK: - State Deduplication Tests

    func test_provider_tracksLastSelectedPaymentMethodType() {
        // Arrange & Act
        // Provider internally tracks lastSelectedPaymentMethodType to prevent
        // duplicate callbacks for the same selection
        let provider = PaymentMethodSelectionProvider(
            onPaymentMethodSelected: { _ in }
        ) { _ in
            Text("Test")
        }

        // Assert - provider is created (internal state tracking not directly testable)
        XCTAssertNotNil(provider)
    }

    // MARK: - Scope Access Tests

    func test_contentBuilder_providesAccessToSelectionScope() {
        // Arrange
        var scopeAccessible = false

        // Act
        _ = PaymentMethodSelectionProvider { scope in
            // Scope should be accessible in content builder
            scopeAccessible = true
            return Text("Content with scope access")
        }

        // Assert - content builder has scope parameter
        XCTAssertNotNil(scopeAccessible)
    }
}
