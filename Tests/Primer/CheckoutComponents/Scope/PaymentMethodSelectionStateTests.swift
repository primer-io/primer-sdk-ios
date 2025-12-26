//
//  PaymentMethodSelectionStateTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for PrimerPaymentMethodSelectionState struct.
@available(iOS 15.0, *)
final class PaymentMethodSelectionStateTests: XCTestCase {

    // MARK: - Initialization Tests

    func test_defaultInit_hasEmptyPaymentMethods() {
        let state = PrimerPaymentMethodSelectionState()

        XCTAssertTrue(state.paymentMethods.isEmpty)
    }

    func test_defaultInit_isNotLoading() {
        let state = PrimerPaymentMethodSelectionState()

        XCTAssertFalse(state.isLoading)
    }

    func test_defaultInit_hasNoSelectedPaymentMethod() {
        let state = PrimerPaymentMethodSelectionState()

        XCTAssertNil(state.selectedPaymentMethod)
    }

    func test_defaultInit_hasEmptySearchQuery() {
        let state = PrimerPaymentMethodSelectionState()

        XCTAssertEqual(state.searchQuery, "")
    }

    func test_defaultInit_hasEmptyFilteredPaymentMethods() {
        let state = PrimerPaymentMethodSelectionState()

        XCTAssertTrue(state.filteredPaymentMethods.isEmpty)
    }

    func test_defaultInit_hasNoError() {
        let state = PrimerPaymentMethodSelectionState()

        XCTAssertNil(state.error)
    }

    func test_customInit_setsAllProperties() {
        // Given
        let paymentMethods = [
            CheckoutPaymentMethod(id: "card-1", type: "PAYMENT_CARD", name: "Credit Card"),
            CheckoutPaymentMethod(id: "paypal-1", type: "PAYPAL", name: "PayPal")
        ]
        let selectedMethod = paymentMethods[0]

        // When
        let state = PrimerPaymentMethodSelectionState(
            paymentMethods: paymentMethods,
            isLoading: true,
            selectedPaymentMethod: selectedMethod,
            searchQuery: "card",
            filteredPaymentMethods: [paymentMethods[0]],
            error: "Test error"
        )

        // Then
        XCTAssertEqual(state.paymentMethods.count, 2)
        XCTAssertTrue(state.isLoading)
        XCTAssertEqual(state.selectedPaymentMethod, selectedMethod)
        XCTAssertEqual(state.searchQuery, "card")
        XCTAssertEqual(state.filteredPaymentMethods.count, 1)
        XCTAssertEqual(state.error, "Test error")
    }

    // MARK: - Equatable Tests

    func test_equality_sameStates_areEqual() {
        let paymentMethods = [
            CheckoutPaymentMethod(id: "card-1", type: "PAYMENT_CARD", name: "Credit Card")
        ]

        let state1 = PrimerPaymentMethodSelectionState(
            paymentMethods: paymentMethods,
            isLoading: false,
            selectedPaymentMethod: paymentMethods[0],
            searchQuery: "test",
            filteredPaymentMethods: paymentMethods,
            error: nil
        )

        let state2 = PrimerPaymentMethodSelectionState(
            paymentMethods: paymentMethods,
            isLoading: false,
            selectedPaymentMethod: paymentMethods[0],
            searchQuery: "test",
            filteredPaymentMethods: paymentMethods,
            error: nil
        )

        XCTAssertEqual(state1, state2)
    }

    func test_equality_differentPaymentMethods_areNotEqual() {
        let state1 = PrimerPaymentMethodSelectionState(
            paymentMethods: [CheckoutPaymentMethod(id: "card-1", type: "PAYMENT_CARD", name: "Credit Card")]
        )
        let state2 = PrimerPaymentMethodSelectionState(
            paymentMethods: [CheckoutPaymentMethod(id: "paypal-1", type: "PAYPAL", name: "PayPal")]
        )

        XCTAssertNotEqual(state1, state2)
    }

    func test_equality_differentLoadingState_areNotEqual() {
        let state1 = PrimerPaymentMethodSelectionState(isLoading: true)
        let state2 = PrimerPaymentMethodSelectionState(isLoading: false)

        XCTAssertNotEqual(state1, state2)
    }

    func test_equality_differentSelectedMethod_areNotEqual() {
        let method1 = CheckoutPaymentMethod(id: "card-1", type: "PAYMENT_CARD", name: "Credit Card")
        let method2 = CheckoutPaymentMethod(id: "paypal-1", type: "PAYPAL", name: "PayPal")

        let state1 = PrimerPaymentMethodSelectionState(selectedPaymentMethod: method1)
        let state2 = PrimerPaymentMethodSelectionState(selectedPaymentMethod: method2)

        XCTAssertNotEqual(state1, state2)
    }

    func test_equality_differentSearchQuery_areNotEqual() {
        let state1 = PrimerPaymentMethodSelectionState(searchQuery: "card")
        let state2 = PrimerPaymentMethodSelectionState(searchQuery: "paypal")

        XCTAssertNotEqual(state1, state2)
    }

    func test_equality_differentError_areNotEqual() {
        let state1 = PrimerPaymentMethodSelectionState(error: "Error 1")
        let state2 = PrimerPaymentMethodSelectionState(error: "Error 2")

        XCTAssertNotEqual(state1, state2)
    }

    func test_equality_nilVsNonNilError_areNotEqual() {
        let state1 = PrimerPaymentMethodSelectionState(error: nil)
        let state2 = PrimerPaymentMethodSelectionState(error: "Error")

        XCTAssertNotEqual(state1, state2)
    }
}

// MARK: - CheckoutPaymentMethod Tests

@available(iOS 15.0, *)
final class CheckoutPaymentMethodTests: XCTestCase {

    // MARK: - Initialization Tests

    func test_init_setsRequiredProperties() {
        let method = CheckoutPaymentMethod(
            id: "card-1",
            type: "PAYMENT_CARD",
            name: "Credit Card"
        )

        XCTAssertEqual(method.id, "card-1")
        XCTAssertEqual(method.type, "PAYMENT_CARD")
        XCTAssertEqual(method.name, "Credit Card")
    }

    func test_init_optionalPropertiesDefaultToNil() {
        let method = CheckoutPaymentMethod(
            id: "card-1",
            type: "PAYMENT_CARD",
            name: "Credit Card"
        )

        XCTAssertNil(method.icon)
        XCTAssertNil(method.metadata)
        XCTAssertNil(method.surcharge)
        XCTAssertNil(method.formattedSurcharge)
        XCTAssertNil(method.backgroundColor)
    }

    func test_init_hasUnknownSurcharge_defaultsToFalse() {
        let method = CheckoutPaymentMethod(
            id: "card-1",
            type: "PAYMENT_CARD",
            name: "Credit Card"
        )

        XCTAssertFalse(method.hasUnknownSurcharge)
    }

    func test_init_withSurcharge_setsSurchargeProperties() {
        let method = CheckoutPaymentMethod(
            id: "card-1",
            type: "PAYMENT_CARD",
            name: "Credit Card",
            surcharge: 150,
            hasUnknownSurcharge: false,
            formattedSurcharge: "$1.50"
        )

        XCTAssertEqual(method.surcharge, 150)
        XCTAssertFalse(method.hasUnknownSurcharge)
        XCTAssertEqual(method.formattedSurcharge, "$1.50")
    }

    func test_init_withUnknownSurcharge() {
        let method = CheckoutPaymentMethod(
            id: "card-1",
            type: "PAYMENT_CARD",
            name: "Credit Card",
            hasUnknownSurcharge: true
        )

        XCTAssertTrue(method.hasUnknownSurcharge)
    }

    // MARK: - Identifiable Tests

    func test_identifiable_usesIdProperty() {
        let method = CheckoutPaymentMethod(
            id: "unique-id-123",
            type: "PAYMENT_CARD",
            name: "Credit Card"
        )

        XCTAssertEqual(method.id, "unique-id-123")
    }

    // MARK: - Equatable Tests

    func test_equality_sameIdAndType_areEqual() {
        let method1 = CheckoutPaymentMethod(id: "card-1", type: "PAYMENT_CARD", name: "Credit Card")
        let method2 = CheckoutPaymentMethod(id: "card-1", type: "PAYMENT_CARD", name: "Credit Card")

        XCTAssertEqual(method1, method2)
    }

    func test_equality_differentId_areNotEqual() {
        let method1 = CheckoutPaymentMethod(id: "card-1", type: "PAYMENT_CARD", name: "Credit Card")
        let method2 = CheckoutPaymentMethod(id: "card-2", type: "PAYMENT_CARD", name: "Credit Card")

        XCTAssertNotEqual(method1, method2)
    }

    func test_equality_differentType_areNotEqual() {
        let method1 = CheckoutPaymentMethod(id: "method-1", type: "PAYMENT_CARD", name: "Credit Card")
        let method2 = CheckoutPaymentMethod(id: "method-1", type: "PAYPAL", name: "Credit Card")

        XCTAssertNotEqual(method1, method2)
    }

    func test_equality_differentName_areNotEqual() {
        let method1 = CheckoutPaymentMethod(id: "card-1", type: "PAYMENT_CARD", name: "Visa")
        let method2 = CheckoutPaymentMethod(id: "card-1", type: "PAYMENT_CARD", name: "Mastercard")

        XCTAssertNotEqual(method1, method2)
    }

    func test_equality_differentSurcharge_areNotEqual() {
        let method1 = CheckoutPaymentMethod(id: "card-1", type: "PAYMENT_CARD", name: "Card", surcharge: 100)
        let method2 = CheckoutPaymentMethod(id: "card-1", type: "PAYMENT_CARD", name: "Card", surcharge: 200)

        XCTAssertNotEqual(method1, method2)
    }

    func test_equality_differentFormattedSurcharge_areNotEqual() {
        let method1 = CheckoutPaymentMethod(
            id: "card-1",
            type: "PAYMENT_CARD",
            name: "Card",
            formattedSurcharge: "$1.00"
        )
        let method2 = CheckoutPaymentMethod(
            id: "card-1",
            type: "PAYMENT_CARD",
            name: "Card",
            formattedSurcharge: "$2.00"
        )

        XCTAssertNotEqual(method1, method2)
    }

    func test_equality_ignoresIcon() {
        // Icon is intentionally ignored in equality (per the implementation)
        let method1 = CheckoutPaymentMethod(id: "card-1", type: "PAYMENT_CARD", name: "Card", icon: nil)
        let method2 = CheckoutPaymentMethod(id: "card-1", type: "PAYMENT_CARD", name: "Card", icon: nil)

        XCTAssertEqual(method1, method2)
    }

    // MARK: - Common Payment Method Types Tests

    func test_paymentCardType() {
        let method = CheckoutPaymentMethod(id: "1", type: "PAYMENT_CARD", name: "Credit Card")
        XCTAssertEqual(method.type, "PAYMENT_CARD")
    }

    func test_paypalType() {
        let method = CheckoutPaymentMethod(id: "1", type: "PAYPAL", name: "PayPal")
        XCTAssertEqual(method.type, "PAYPAL")
    }

    func test_applePayType() {
        let method = CheckoutPaymentMethod(id: "1", type: "APPLE_PAY", name: "Apple Pay")
        XCTAssertEqual(method.type, "APPLE_PAY")
    }

    func test_klarnaType() {
        let method = CheckoutPaymentMethod(id: "1", type: "KLARNA", name: "Klarna")
        XCTAssertEqual(method.type, "KLARNA")
    }
}
