//
//  InternalPaymentMethodTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import UIKit
import XCTest

@available(iOS 15.0, *)
final class InternalPaymentMethodTests: XCTestCase {

    // MARK: - Default Init Tests

    func test_init_withRequiredParams_hasExpectedDefaults() {
        // When
        let method = InternalPaymentMethod(id: "test-id", type: "PAYMENT_CARD", name: "Card")

        // Then
        XCTAssertEqual(method.id, "test-id")
        XCTAssertEqual(method.type, "PAYMENT_CARD")
        XCTAssertEqual(method.name, "Card")
        XCTAssertNil(method.icon)
        XCTAssertNil(method.configId)
        XCTAssertTrue(method.isEnabled)
        XCTAssertNil(method.supportedCurrencies)
        XCTAssertTrue(method.requiredInputElements.isEmpty)
        XCTAssertNil(method.surcharge)
        XCTAssertFalse(method.hasUnknownSurcharge)
        XCTAssertNil(method.networkSurcharges)
        XCTAssertNil(method.backgroundColor)
        XCTAssertNil(method.buttonText)
        XCTAssertNil(method.textColor)
        XCTAssertNil(method.borderColor)
        XCTAssertNil(method.borderWidth)
        XCTAssertNil(method.cornerRadius)
    }

    func test_init_withAllParams_setsAllProperties() {
        // When
        let method = InternalPaymentMethod(
            id: "pm-1",
            type: "PAYPAL",
            name: "PayPal",
            icon: UIImage(),
            configId: "config-1",
            isEnabled: false,
            supportedCurrencies: ["USD", "EUR"],
            requiredInputElements: [.cardNumber],
            surcharge: 50,
            hasUnknownSurcharge: true,
            networkSurcharges: ["VISA": 25],
            backgroundColor: .blue,
            buttonText: "Pay with PayPal",
            textColor: .white,
            borderColor: .gray,
            borderWidth: 1.0,
            cornerRadius: 8.0
        )

        // Then
        XCTAssertEqual(method.id, "pm-1")
        XCTAssertFalse(method.isEnabled)
        XCTAssertEqual(method.supportedCurrencies, ["USD", "EUR"])
        XCTAssertEqual(method.surcharge, 50)
        XCTAssertTrue(method.hasUnknownSurcharge)
        XCTAssertEqual(method.buttonText, "Pay with PayPal")
        XCTAssertEqual(method.borderWidth, 1.0)
        XCTAssertEqual(method.cornerRadius, 8.0)
    }

    // MARK: - Equality Tests

    func test_equality_sameIdAndType_areEqual() {
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card")
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card")

        XCTAssertEqual(method1, method2)
    }

    func test_equality_differentId_areNotEqual() {
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card")
        let method2 = InternalPaymentMethod(id: "pm-2", type: "CARD", name: "Card")

        XCTAssertNotEqual(method1, method2)
    }

    func test_equality_differentType_areNotEqual() {
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card")
        let method2 = InternalPaymentMethod(id: "pm-1", type: "PAYPAL", name: "Card")

        XCTAssertNotEqual(method1, method2)
    }

    func test_equality_differentSurcharge_areNotEqual() {
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", surcharge: 50)
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", surcharge: 100)

        XCTAssertNotEqual(method1, method2)
    }

    func test_equality_differentUnknownSurcharge_areNotEqual() {
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", hasUnknownSurcharge: false)
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", hasUnknownSurcharge: true)

        XCTAssertNotEqual(method1, method2)
    }

    func test_equality_differentBackgroundColor_areNotEqual() {
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", backgroundColor: .red)
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", backgroundColor: .blue)

        XCTAssertNotEqual(method1, method2)
    }

    func test_equality_differentConfigId_areNotEqual() {
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", configId: "config-1")
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", configId: "config-2")

        XCTAssertNotEqual(method1, method2)
    }

    func test_equality_differentSupportedCurrencies_areNotEqual() {
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", supportedCurrencies: ["USD"])
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", supportedCurrencies: ["EUR"])

        XCTAssertNotEqual(method1, method2)
    }

    func test_equality_differentNetworkSurcharges_areNotEqual() {
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", networkSurcharges: ["VISA": 25])
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", networkSurcharges: ["VISA": 50])

        XCTAssertNotEqual(method1, method2)
    }

    func test_equality_differentStyling_areNotEqual() {
        let method1 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", borderWidth: 1.0, cornerRadius: 8.0)
        let method2 = InternalPaymentMethod(id: "pm-1", type: "CARD", name: "Card", borderWidth: 2.0, cornerRadius: 8.0)

        XCTAssertNotEqual(method1, method2)
    }
}
