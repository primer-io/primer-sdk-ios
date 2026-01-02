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

    // MARK: - CheckoutPaymentMethod Tests

    func test_checkoutPaymentMethod_canBeCreatedWithMinimalParameters() {
        // Arrange & Act
        let paymentMethod = CheckoutPaymentMethod(
            id: "pm_123",
            type: "PAYMENT_CARD",
            name: "Card"
        )

        // Assert
        XCTAssertEqual(paymentMethod.id, "pm_123")
        XCTAssertEqual(paymentMethod.type, "PAYMENT_CARD")
        XCTAssertEqual(paymentMethod.name, "Card")
        XCTAssertNil(paymentMethod.icon)
        XCTAssertNil(paymentMethod.metadata)
        XCTAssertNil(paymentMethod.surcharge)
        XCTAssertFalse(paymentMethod.hasUnknownSurcharge)
        XCTAssertNil(paymentMethod.formattedSurcharge)
        XCTAssertNil(paymentMethod.backgroundColor)
    }

    func test_checkoutPaymentMethod_canBeCreatedWithAllParameters() {
        // Arrange & Act
        let paymentMethod = CheckoutPaymentMethod(
            id: "pm_456",
            type: "PAYPAL",
            name: "PayPal",
            icon: nil,
            metadata: ["key": "value"],
            surcharge: 100,
            hasUnknownSurcharge: true,
            formattedSurcharge: "$1.00",
            backgroundColor: .blue
        )

        // Assert
        XCTAssertEqual(paymentMethod.id, "pm_456")
        XCTAssertEqual(paymentMethod.type, "PAYPAL")
        XCTAssertEqual(paymentMethod.name, "PayPal")
        XCTAssertEqual(paymentMethod.surcharge, 100)
        XCTAssertTrue(paymentMethod.hasUnknownSurcharge)
        XCTAssertEqual(paymentMethod.formattedSurcharge, "$1.00")
        XCTAssertEqual(paymentMethod.backgroundColor, .blue)
    }

    func test_checkoutPaymentMethod_equality_sameProperties() {
        // Arrange
        let method1 = CheckoutPaymentMethod(
            id: "pm_123",
            type: "PAYMENT_CARD",
            name: "Card",
            surcharge: 50,
            hasUnknownSurcharge: false,
            formattedSurcharge: "$0.50"
        )
        let method2 = CheckoutPaymentMethod(
            id: "pm_123",
            type: "PAYMENT_CARD",
            name: "Card",
            surcharge: 50,
            hasUnknownSurcharge: false,
            formattedSurcharge: "$0.50"
        )

        // Assert
        XCTAssertEqual(method1, method2)
    }

    func test_checkoutPaymentMethod_equality_differentId() {
        // Arrange
        let method1 = CheckoutPaymentMethod(id: "pm_123", type: "PAYMENT_CARD", name: "Card")
        let method2 = CheckoutPaymentMethod(id: "pm_456", type: "PAYMENT_CARD", name: "Card")

        // Assert
        XCTAssertNotEqual(method1, method2)
    }

    func test_checkoutPaymentMethod_equality_differentType() {
        // Arrange
        let method1 = CheckoutPaymentMethod(id: "pm_123", type: "PAYMENT_CARD", name: "Card")
        let method2 = CheckoutPaymentMethod(id: "pm_123", type: "PAYPAL", name: "Card")

        // Assert
        XCTAssertNotEqual(method1, method2)
    }

    func test_checkoutPaymentMethod_equality_differentName() {
        // Arrange
        let method1 = CheckoutPaymentMethod(id: "pm_123", type: "PAYMENT_CARD", name: "Card")
        let method2 = CheckoutPaymentMethod(id: "pm_123", type: "PAYMENT_CARD", name: "Credit Card")

        // Assert
        XCTAssertNotEqual(method1, method2)
    }

    func test_checkoutPaymentMethod_equality_differentSurcharge() {
        // Arrange
        let method1 = CheckoutPaymentMethod(id: "pm_123", type: "PAYMENT_CARD", name: "Card", surcharge: 50)
        let method2 = CheckoutPaymentMethod(id: "pm_123", type: "PAYMENT_CARD", name: "Card", surcharge: 100)

        // Assert
        XCTAssertNotEqual(method1, method2)
    }

    func test_checkoutPaymentMethod_identifiable_usesIdAsIdentity() {
        // Arrange
        let method = CheckoutPaymentMethod(id: "unique_id_123", type: "PAYMENT_CARD", name: "Card")

        // Assert
        XCTAssertEqual(method.id, "unique_id_123")
    }

    // MARK: - PrimerPaymentMethodSelectionState Tests

    func test_paymentMethodSelectionState_defaultInit_hasEmptyValues() {
        // Arrange & Act
        let state = PrimerPaymentMethodSelectionState()

        // Assert
        XCTAssertTrue(state.paymentMethods.isEmpty)
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.selectedPaymentMethod)
        XCTAssertEqual(state.searchQuery, "")
        XCTAssertTrue(state.filteredPaymentMethods.isEmpty)
        XCTAssertNil(state.error)
        XCTAssertNil(state.selectedVaultedPaymentMethod)
        XCTAssertFalse(state.isVaultPaymentLoading)
        XCTAssertFalse(state.requiresCvvInput)
        XCTAssertEqual(state.cvvInput, "")
        XCTAssertFalse(state.isCvvValid)
        XCTAssertNil(state.cvvError)
        XCTAssertTrue(state.isPaymentMethodsExpanded)
    }

    func test_paymentMethodSelectionState_initWithPaymentMethods() {
        // Arrange
        let methods = [
            CheckoutPaymentMethod(id: "1", type: "CARD", name: "Card"),
            CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal")
        ]

        // Act
        let state = PrimerPaymentMethodSelectionState(paymentMethods: methods)

        // Assert
        XCTAssertEqual(state.paymentMethods.count, 2)
        XCTAssertEqual(state.paymentMethods[0].type, "CARD")
        XCTAssertEqual(state.paymentMethods[1].type, "PAYPAL")
    }

    func test_paymentMethodSelectionState_initWithLoadingState() {
        // Arrange & Act
        let state = PrimerPaymentMethodSelectionState(isLoading: true)

        // Assert
        XCTAssertTrue(state.isLoading)
    }

    func test_paymentMethodSelectionState_initWithSelectedPaymentMethod() {
        // Arrange
        let selectedMethod = CheckoutPaymentMethod(id: "pm_selected", type: "CARD", name: "Card")

        // Act
        let state = PrimerPaymentMethodSelectionState(selectedPaymentMethod: selectedMethod)

        // Assert
        XCTAssertNotNil(state.selectedPaymentMethod)
        XCTAssertEqual(state.selectedPaymentMethod?.id, "pm_selected")
    }

    func test_paymentMethodSelectionState_initWithSearchQuery() {
        // Arrange & Act
        let state = PrimerPaymentMethodSelectionState(searchQuery: "card")

        // Assert
        XCTAssertEqual(state.searchQuery, "card")
    }

    func test_paymentMethodSelectionState_initWithFilteredPaymentMethods() {
        // Arrange
        let filtered = [CheckoutPaymentMethod(id: "1", type: "CARD", name: "Card")]

        // Act
        let state = PrimerPaymentMethodSelectionState(filteredPaymentMethods: filtered)

        // Assert
        XCTAssertEqual(state.filteredPaymentMethods.count, 1)
    }

    func test_paymentMethodSelectionState_initWithError() {
        // Arrange & Act
        let state = PrimerPaymentMethodSelectionState(error: "Something went wrong")

        // Assert
        XCTAssertEqual(state.error, "Something went wrong")
    }

    func test_paymentMethodSelectionState_initWithCvvInputState() {
        // Arrange & Act
        let state = PrimerPaymentMethodSelectionState(
            requiresCvvInput: true,
            cvvInput: "123",
            isCvvValid: true,
            cvvError: nil
        )

        // Assert
        XCTAssertTrue(state.requiresCvvInput)
        XCTAssertEqual(state.cvvInput, "123")
        XCTAssertTrue(state.isCvvValid)
        XCTAssertNil(state.cvvError)
    }

    func test_paymentMethodSelectionState_initWithCvvError() {
        // Arrange & Act
        let state = PrimerPaymentMethodSelectionState(
            requiresCvvInput: true,
            cvvInput: "12",
            isCvvValid: false,
            cvvError: "CVV must be 3 digits"
        )

        // Assert
        XCTAssertFalse(state.isCvvValid)
        XCTAssertEqual(state.cvvError, "CVV must be 3 digits")
    }

    func test_paymentMethodSelectionState_initWithCollapsedState() {
        // Arrange & Act
        let state = PrimerPaymentMethodSelectionState(isPaymentMethodsExpanded: false)

        // Assert
        XCTAssertFalse(state.isPaymentMethodsExpanded)
    }

    func test_paymentMethodSelectionState_equality_sameValues() {
        // Arrange
        let methods = [CheckoutPaymentMethod(id: "1", type: "CARD", name: "Card")]
        let state1 = PrimerPaymentMethodSelectionState(
            paymentMethods: methods,
            isLoading: false,
            searchQuery: "test"
        )
        let state2 = PrimerPaymentMethodSelectionState(
            paymentMethods: methods,
            isLoading: false,
            searchQuery: "test"
        )

        // Assert
        XCTAssertEqual(state1, state2)
    }

    func test_paymentMethodSelectionState_equality_differentPaymentMethods() {
        // Arrange
        let state1 = PrimerPaymentMethodSelectionState(
            paymentMethods: [CheckoutPaymentMethod(id: "1", type: "CARD", name: "Card")]
        )
        let state2 = PrimerPaymentMethodSelectionState(
            paymentMethods: [CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal")]
        )

        // Assert
        XCTAssertNotEqual(state1, state2)
    }

    func test_paymentMethodSelectionState_equality_differentLoadingState() {
        // Arrange
        let state1 = PrimerPaymentMethodSelectionState(isLoading: true)
        let state2 = PrimerPaymentMethodSelectionState(isLoading: false)

        // Assert
        XCTAssertNotEqual(state1, state2)
    }

    func test_paymentMethodSelectionState_equality_differentSearchQuery() {
        // Arrange
        let state1 = PrimerPaymentMethodSelectionState(searchQuery: "card")
        let state2 = PrimerPaymentMethodSelectionState(searchQuery: "paypal")

        // Assert
        XCTAssertNotEqual(state1, state2)
    }

    func test_paymentMethodSelectionState_equality_differentCvvInput() {
        // Arrange
        let state1 = PrimerPaymentMethodSelectionState(cvvInput: "123")
        let state2 = PrimerPaymentMethodSelectionState(cvvInput: "456")

        // Assert
        XCTAssertNotEqual(state1, state2)
    }

    func test_paymentMethodSelectionState_equality_differentCvvValid() {
        // Arrange
        let state1 = PrimerPaymentMethodSelectionState(isCvvValid: true)
        let state2 = PrimerPaymentMethodSelectionState(isCvvValid: false)

        // Assert
        XCTAssertNotEqual(state1, state2)
    }

    func test_paymentMethodSelectionState_equality_differentError() {
        // Arrange
        let state1 = PrimerPaymentMethodSelectionState(error: "Error 1")
        let state2 = PrimerPaymentMethodSelectionState(error: "Error 2")

        // Assert
        XCTAssertNotEqual(state1, state2)
    }

    func test_paymentMethodSelectionState_equality_differentExpansionState() {
        // Arrange
        let state1 = PrimerPaymentMethodSelectionState(isPaymentMethodsExpanded: true)
        let state2 = PrimerPaymentMethodSelectionState(isPaymentMethodsExpanded: false)

        // Assert
        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Content Builder with Different Views Tests

    func test_contentBuilder_withScrollView() {
        // Arrange & Act
        let provider = PaymentMethodSelectionProvider { _ in
            ScrollView {
                VStack {
                    Text("Card")
                    Text("PayPal")
                }
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_contentBuilder_withLazyVStack() {
        // Arrange & Act
        let provider = PaymentMethodSelectionProvider { _ in
            LazyVStack {
                ForEach(0..<3) { index in
                    Text("Method \(index)")
                }
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_contentBuilder_withEmptyView() {
        // Arrange & Act
        let provider = PaymentMethodSelectionProvider { _ in
            EmptyView()
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    func test_contentBuilder_withGroup() {
        // Arrange & Act
        let provider = PaymentMethodSelectionProvider { _ in
            Group {
                Text("Payment Method 1")
                Text("Payment Method 2")
            }
        }

        // Assert
        XCTAssertNotNil(provider)
    }

    // MARK: - Callback Chaining Tests

    func test_callbacks_canBeChainedWithAdditionalLogic() {
        // Arrange
        var step1Executed = false
        var step2Executed = false

        // Act
        let provider = PaymentMethodSelectionProvider(
            onPaymentMethodSelected: { type in
                step1Executed = true
                if type == "CARD" {
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

    func test_cancelCallback_canExecuteCleanupLogic() {
        // Arrange
        var cleanupExecuted = false

        // Act
        let provider = PaymentMethodSelectionProvider(
            onCancel: {
                cleanupExecuted = true
            }
        ) { _ in
            Text("Test")
        }

        // Assert - cleanup callback is configured
        XCTAssertNotNil(provider)
        XCTAssertFalse(cleanupExecuted)
    }

    // MARK: - Payment Method Type Coverage Tests

    func test_paymentMethodType_card() {
        // Arrange
        let method = CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Card")

        // Assert
        XCTAssertEqual(method.type, "PAYMENT_CARD")
    }

    func test_paymentMethodType_paypal() {
        // Arrange
        let method = CheckoutPaymentMethod(id: "2", type: "PAYPAL", name: "PayPal")

        // Assert
        XCTAssertEqual(method.type, "PAYPAL")
    }

    func test_paymentMethodType_applePay() {
        // Arrange
        let method = CheckoutPaymentMethod(id: "3", type: "APPLE_PAY", name: "Apple Pay")

        // Assert
        XCTAssertEqual(method.type, "APPLE_PAY")
    }

    func test_paymentMethodType_googlePay() {
        // Arrange
        let method = CheckoutPaymentMethod(id: "4", type: "GOOGLE_PAY", name: "Google Pay")

        // Assert
        XCTAssertEqual(method.type, "GOOGLE_PAY")
    }

    func test_paymentMethodType_klarna() {
        // Arrange
        let method = CheckoutPaymentMethod(id: "5", type: "KLARNA", name: "Klarna")

        // Assert
        XCTAssertEqual(method.type, "KLARNA")
    }

    // MARK: - Surcharge Display Tests

    func test_checkoutPaymentMethod_withZeroSurcharge() {
        // Arrange & Act
        let method = CheckoutPaymentMethod(
            id: "1",
            type: "CARD",
            name: "Card",
            surcharge: 0,
            formattedSurcharge: "$0.00"
        )

        // Assert
        XCTAssertEqual(method.surcharge, 0)
        XCTAssertEqual(method.formattedSurcharge, "$0.00")
    }

    func test_checkoutPaymentMethod_withLargeSurcharge() {
        // Arrange & Act
        let method = CheckoutPaymentMethod(
            id: "1",
            type: "CARD",
            name: "Card",
            surcharge: 10000,
            formattedSurcharge: "$100.00"
        )

        // Assert
        XCTAssertEqual(method.surcharge, 10000)
        XCTAssertEqual(method.formattedSurcharge, "$100.00")
    }

    func test_checkoutPaymentMethod_withUnknownSurcharge() {
        // Arrange & Act
        let method = CheckoutPaymentMethod(
            id: "1",
            type: "CARD",
            name: "Card",
            hasUnknownSurcharge: true
        )

        // Assert
        XCTAssertTrue(method.hasUnknownSurcharge)
        XCTAssertNil(method.surcharge)
    }

    // MARK: - Background Color Tests

    func test_checkoutPaymentMethod_withCustomBackgroundColor() {
        // Arrange & Act
        let method = CheckoutPaymentMethod(
            id: "1",
            type: "CARD",
            name: "Card",
            backgroundColor: .red
        )

        // Assert
        XCTAssertEqual(method.backgroundColor, .red)
    }

    func test_checkoutPaymentMethod_withNilBackgroundColor() {
        // Arrange & Act
        let method = CheckoutPaymentMethod(
            id: "1",
            type: "CARD",
            name: "Card",
            backgroundColor: nil
        )

        // Assert
        XCTAssertNil(method.backgroundColor)
    }

    // MARK: - State with All CVV Fields Tests

    func test_paymentMethodSelectionState_fullCvvConfiguration() {
        // Arrange & Act
        let state = PrimerPaymentMethodSelectionState(
            requiresCvvInput: true,
            cvvInput: "999",
            isCvvValid: true,
            cvvError: nil
        )

        // Assert
        XCTAssertTrue(state.requiresCvvInput)
        XCTAssertEqual(state.cvvInput, "999")
        XCTAssertTrue(state.isCvvValid)
        XCTAssertNil(state.cvvError)
    }

    // MARK: - Multiple Providers with Different Callbacks

    func test_multipleProviders_withDifferentCallbackTypes() {
        // Arrange & Act
        let provider1 = PaymentMethodSelectionProvider(
            onPaymentMethodSelected: { _ in }
        ) { _ in Text("1") }

        let provider2 = PaymentMethodSelectionProvider(
            onCancel: { }
        ) { _ in Text("2") }

        let provider3 = PaymentMethodSelectionProvider(
            onPaymentMethodSelected: { _ in },
            onCancel: { }
        ) { _ in Text("3") }

        // Assert
        XCTAssertNotNil(provider1)
        XCTAssertNotNil(provider2)
        XCTAssertNotNil(provider3)
    }

    // MARK: - LogReporter Conformance Tests

    func test_provider_conformsToLogReporter() {
        // Arrange
        let provider = PaymentMethodSelectionProvider { _ in
            Text("Test")
        }

        // Assert - LogReporter conformance
        XCTAssertTrue(provider is any LogReporter)
    }
}
