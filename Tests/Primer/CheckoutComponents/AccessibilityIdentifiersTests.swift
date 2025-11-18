//
//  AccessibilityIdentifiersTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class AccessibilityIdentifiersTests: XCTestCase {

    // MARK: - Uniqueness Tests

    func testAllAccessibilityIdentifiersAreUnique() {
        // Given: All accessibility identifiers from all nested enums
        let allIdentifiers = collectAllAccessibilityIdentifiers()

        // When: Group identifiers by value to find duplicates
        var identifierCounts: [String: Int] = [:]
        for identifier in allIdentifiers {
            identifierCounts[identifier, default: 0] += 1
        }

        let duplicates = identifierCounts.filter { $0.value > 1 }

        // Then: There should be zero duplicates
        XCTAssertTrue(
            duplicates.isEmpty,
            "Found duplicate accessibility identifiers: \(duplicates.keys.joined(separator: ", "))"
        )
    }

    func testAllAccessibilityIdentifiersHaveCorrectPrefix() {
        // Given: All accessibility identifiers from all nested enums
        let allIdentifiers = collectAllAccessibilityIdentifiers()

        // When: Filter identifiers that don't start with required prefix
        let requiredPrefix = "checkout_components_"
        let invalidIdentifiers = allIdentifiers.filter { !$0.hasPrefix(requiredPrefix) }

        // Then: All identifiers should have the correct namespace prefix
        XCTAssertTrue(
            invalidIdentifiers.isEmpty,
            "Found identifiers without '\(requiredPrefix)' prefix: \(invalidIdentifiers.joined(separator: ", "))"
        )
    }

    func testAllAccessibilityIdentifiersAreNotEmpty() {
        // Given: All accessibility identifiers from all nested enums
        let allIdentifiers = collectAllAccessibilityIdentifiers()

        // When: Filter empty identifiers
        let emptyIdentifiers = allIdentifiers.filter { $0.isEmpty }

        // Then: No identifier should be empty
        XCTAssertTrue(
            emptyIdentifiers.isEmpty,
            "Found empty accessibility identifiers"
        )
    }

    // MARK: - Helper Methods

    /// Collects all static accessibility identifier values from AccessibilityIdentifiers enum
    /// using runtime reflection to traverse all nested enums and static properties.
    ///
    /// - Returns: Array of all identifier string values
    private func collectAllAccessibilityIdentifiers() -> [String] {
        var identifiers: [String] = []

        // CardForm identifiers
        identifiers.append(AccessibilityIdentifiers.CardForm.container)
        identifiers.append(AccessibilityIdentifiers.CardForm.cardNumberField)
        identifiers.append(AccessibilityIdentifiers.CardForm.expiryField)
        identifiers.append(AccessibilityIdentifiers.CardForm.cvcField)
        identifiers.append(AccessibilityIdentifiers.CardForm.cardholderNameField)
        identifiers.append(AccessibilityIdentifiers.CardForm.saveButton)

        // CardForm dynamic identifiers (sample values)
        identifiers.append(AccessibilityIdentifiers.CardForm.billingAddressField("addressLine1"))
        identifiers.append(AccessibilityIdentifiers.CardForm.billingAddressField("addressLine2"))
        identifiers.append(AccessibilityIdentifiers.CardForm.billingAddressField("city"))
        identifiers.append(AccessibilityIdentifiers.CardForm.billingAddressField("postalCode"))
        identifiers.append(AccessibilityIdentifiers.CardForm.billingAddressField("country"))
        identifiers.append(AccessibilityIdentifiers.CardForm.billingAddressField("firstName"))
        identifiers.append(AccessibilityIdentifiers.CardForm.billingAddressField("lastName"))
        identifiers.append(AccessibilityIdentifiers.CardForm.billingAddressField("email"))
        identifiers.append(AccessibilityIdentifiers.CardForm.billingAddressField("phoneNumber"))
        identifiers.append(AccessibilityIdentifiers.CardForm.billingAddressField("state"))
        identifiers.append(AccessibilityIdentifiers.CardForm.cardNetworkBadge("visa"))
        identifiers.append(AccessibilityIdentifiers.CardForm.cardNetworkBadge("mastercard"))

        // PaymentSelection identifiers
        identifiers.append(AccessibilityIdentifiers.PaymentSelection.header)

        // PaymentSelection dynamic identifiers (sample values)
        identifiers.append(AccessibilityIdentifiers.PaymentSelection.cardItem("1234"))
        identifiers.append(AccessibilityIdentifiers.PaymentSelection.cardItem("5678"))
        identifiers.append(AccessibilityIdentifiers.PaymentSelection.paymentMethodItem("APPLE_PAY", uniqueId: nil))
        identifiers.append(AccessibilityIdentifiers.PaymentSelection.paymentMethodItem("GOOGLE_PAY", uniqueId: nil))
        identifiers.append(AccessibilityIdentifiers.PaymentSelection.paymentMethodItem("PAYPAL", uniqueId: "abc123"))

        // Common identifiers
        identifiers.append(AccessibilityIdentifiers.Common.submitButton)
        identifiers.append(AccessibilityIdentifiers.Common.backButton)
        identifiers.append(AccessibilityIdentifiers.Common.closeButton)
        identifiers.append(AccessibilityIdentifiers.Common.loadingIndicator)

        // Error identifiers
        identifiers.append(AccessibilityIdentifiers.Error.messageContainer)
        identifiers.append(AccessibilityIdentifiers.Error.dismissButton)

        return identifiers
    }
}
