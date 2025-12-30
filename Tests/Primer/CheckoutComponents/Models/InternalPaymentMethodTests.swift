//
//  InternalPaymentMethodTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit
import XCTest
@testable import PrimerSDK

/// Tests for InternalPaymentMethod covering initialization and Equatable conformance.
final class InternalPaymentMethodTests: XCTestCase {

    // MARK: - Initialization Tests

    func test_init_withRequiredParameters_setsRequiredProperties() {
        // When
        let method = InternalPaymentMethod(
            id: "pm-123",
            type: "PAYMENT_CARD",
            name: "Card"
        )

        // Then
        XCTAssertEqual(method.id, "pm-123")
        XCTAssertEqual(method.type, "PAYMENT_CARD")
        XCTAssertEqual(method.name, "Card")
    }

    func test_init_withRequiredParameters_hasDefaultValues() {
        // When
        let method = InternalPaymentMethod(
            id: "pm-123",
            type: "PAYMENT_CARD",
            name: "Card"
        )

        // Then - verify defaults
        XCTAssertNil(method.icon)
        XCTAssertNil(method.configId)
        XCTAssertTrue(method.isEnabled)
        XCTAssertNil(method.supportedCurrencies)
        XCTAssertTrue(method.requiredInputElements.isEmpty)
        XCTAssertNil(method.metadata)
        XCTAssertNil(method.surcharge)
        XCTAssertFalse(method.hasUnknownSurcharge)
        XCTAssertNil(method.networkSurcharges)
        XCTAssertNil(method.backgroundColor)
    }

    func test_init_withAllParameters_setsAllProperties() {
        // Given
        let icon = UIImage()
        let backgroundColor = UIColor.red
        let metadata: [String: Any] = ["key": "value"]
        let networkSurcharges = ["VISA": 100, "MASTERCARD": 150]
        let currencies = ["USD", "EUR"]
        let inputElements: [PrimerInputElementType] = [.cardNumber, .cvv]

        // When
        let method = InternalPaymentMethod(
            id: "pm-456",
            type: "APPLE_PAY",
            name: "Apple Pay",
            icon: icon,
            configId: "config-789",
            isEnabled: false,
            supportedCurrencies: currencies,
            requiredInputElements: inputElements,
            metadata: metadata,
            surcharge: 250,
            hasUnknownSurcharge: true,
            networkSurcharges: networkSurcharges,
            backgroundColor: backgroundColor
        )

        // Then
        XCTAssertEqual(method.id, "pm-456")
        XCTAssertEqual(method.type, "APPLE_PAY")
        XCTAssertEqual(method.name, "Apple Pay")
        XCTAssertNotNil(method.icon)
        XCTAssertEqual(method.configId, "config-789")
        XCTAssertFalse(method.isEnabled)
        XCTAssertEqual(method.supportedCurrencies, currencies)
        XCTAssertEqual(method.requiredInputElements, inputElements)
        XCTAssertEqual(method.surcharge, 250)
        XCTAssertTrue(method.hasUnknownSurcharge)
        XCTAssertEqual(method.networkSurcharges, networkSurcharges)
        XCTAssertEqual(method.backgroundColor, backgroundColor)
    }

    // MARK: - Equatable Tests - Same Values

    func test_equals_withIdenticalValues_returnsTrue() {
        // Given
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card")
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card")

        // Then
        XCTAssertEqual(method1, method2)
    }

    func test_equals_withAllEquatableFieldsSame_returnsTrue() {
        // Given
        let method1 = InternalPaymentMethod(
            id: "pm-1",
            type: "CARD",
            name: "Card",
            isEnabled: true,
            surcharge: 100,
            hasUnknownSurcharge: true,
            backgroundColor: .blue
        )
        let method2 = InternalPaymentMethod(
            id: "pm-1",
            type: "CARD",
            name: "Card",
            isEnabled: true,
            surcharge: 100,
            hasUnknownSurcharge: true,
            backgroundColor: .blue
        )

        // Then
        XCTAssertEqual(method1, method2)
    }

    // MARK: - Equatable Tests - Different Values

    func test_equals_withDifferentId_returnsFalse() {
        // Given
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card")
        let method2 = InternalPaymentMethod(id: "pm-2", type: "CARD", name: "Card")

        // Then
        XCTAssertNotEqual(method1, method2)
    }

    func test_equals_withDifferentType_returnsFalse() {
        // Given
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card")
        let method2 = InternalPaymentMethod(id: "pm-1", type: "PAYPAL", name: "Card")

        // Then
        XCTAssertNotEqual(method1, method2)
    }

    func test_equals_withDifferentName_returnsFalse() {
        // Given
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card")
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Credit Card")

        // Then
        XCTAssertNotEqual(method1, method2)
    }

    func test_equals_withDifferentIsEnabled_returnsFalse() {
        // Given
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", isEnabled: true)
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", isEnabled: false)

        // Then
        XCTAssertNotEqual(method1, method2)
    }

    func test_equals_withDifferentSurcharge_returnsFalse() {
        // Given
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", surcharge: 100)
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", surcharge: 200)

        // Then
        XCTAssertNotEqual(method1, method2)
    }

    func test_equals_withDifferentHasUnknownSurcharge_returnsFalse() {
        // Given
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", hasUnknownSurcharge: true)
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", hasUnknownSurcharge: false)

        // Then
        XCTAssertNotEqual(method1, method2)
    }

    func test_equals_withDifferentBackgroundColor_returnsFalse() {
        // Given
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", backgroundColor: .red)
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", backgroundColor: .blue)

        // Then
        XCTAssertNotEqual(method1, method2)
    }

    // MARK: - Equatable Tests - Non-Compared Properties

    func test_equals_withDifferentIcon_returnsTrue() {
        // Given - icon is NOT part of the equality comparison
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", icon: UIImage())
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", icon: nil)

        // Then - should be equal because icon is not compared
        XCTAssertEqual(method1, method2)
    }

    func test_equals_withDifferentConfigId_returnsTrue() {
        // Given - configId is NOT part of the equality comparison
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", configId: "config-1")
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", configId: "config-2")

        // Then - should be equal because configId is not compared
        XCTAssertEqual(method1, method2)
    }

    func test_equals_withDifferentSupportedCurrencies_returnsTrue() {
        // Given - supportedCurrencies is NOT part of the equality comparison
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", supportedCurrencies: ["USD"])
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", supportedCurrencies: ["EUR", "GBP"])

        // Then - should be equal because supportedCurrencies is not compared
        XCTAssertEqual(method1, method2)
    }

    func test_equals_withDifferentRequiredInputElements_returnsTrue() {
        // Given - requiredInputElements is NOT part of the equality comparison
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", requiredInputElements: [.cardNumber])
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", requiredInputElements: [.cvv, .expiryDate])

        // Then - should be equal because requiredInputElements is not compared
        XCTAssertEqual(method1, method2)
    }

    func test_equals_withDifferentNetworkSurcharges_returnsTrue() {
        // Given - networkSurcharges is NOT part of the equality comparison
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", networkSurcharges: ["VISA": 100])
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", networkSurcharges: ["MASTERCARD": 200])

        // Then - should be equal because networkSurcharges is not compared
        XCTAssertEqual(method1, method2)
    }

    // MARK: - Edge Cases

    func test_equals_withNilSurchargeVsZero_returnsFalse() {
        // Given
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", surcharge: nil)
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", surcharge: 0)

        // Then - nil vs 0 are different
        XCTAssertNotEqual(method1, method2)
    }

    func test_equals_withNilBackgroundColorVsColor_returnsFalse() {
        // Given
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", backgroundColor: nil)
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", backgroundColor: .clear)

        // Then - nil vs color are different
        XCTAssertNotEqual(method1, method2)
    }

    func test_init_withEmptyStrings_preservesEmptyStrings() {
        // When
        let method = InternalPaymentMethod(id: "", type: "", name: "")

        // Then
        XCTAssertEqual(method.id, "")
        XCTAssertEqual(method.type, "")
        XCTAssertEqual(method.name, "")
    }

    func test_init_withSpecialCharactersInName_preservesCharacters() {
        // Given
        let name = "Apple Pay - 信用卡 💳"

        // When
        let method = InternalPaymentMethod(id: "pm-1", type: "APPLE_PAY", name: name)

        // Then
        XCTAssertEqual(method.name, name)
    }

    func test_supportedCurrencies_preservesOrder() {
        // Given
        let currencies = ["GBP", "USD", "EUR", "JPY"]

        // When
        let method = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", supportedCurrencies: currencies)

        // Then
        XCTAssertEqual(method.supportedCurrencies, currencies)
    }

    func test_requiredInputElements_preservesOrder() {
        // Given
        let elements: [PrimerInputElementType] = [.expiryDate, .cardNumber, .cvv]

        // When
        let method = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", requiredInputElements: elements)

        // Then
        XCTAssertEqual(method.requiredInputElements, elements)
    }
}
