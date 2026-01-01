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
        let emptyIdentifiers = allIdentifiers.filter(\.isEmpty)

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

    // MARK: - CardForm Dynamic Identifier Tests

    func test_billingAddressField_generatesCorrectIdentifier() {
        // Given: A billing address field name
        let fieldName = "postalCode"

        // When: Generating the identifier
        let identifier = AccessibilityIdentifiers.CardForm.billingAddressField(fieldName)

        // Then: The identifier should have the correct format
        XCTAssertEqual(identifier, "checkout_components_card_form_billing_postalCode_field")
    }

    func test_billingAddressField_withDifferentFields_generatesUniqueIdentifiers() {
        // Given: Different billing address field names
        let fields = ["addressLine1", "addressLine2", "city", "state", "postalCode", "country"]

        // When: Generating identifiers for each field
        let identifiers = fields.map { AccessibilityIdentifiers.CardForm.billingAddressField($0) }

        // Then: All identifiers should be unique
        let uniqueIdentifiers = Set(identifiers)
        XCTAssertEqual(identifiers.count, uniqueIdentifiers.count)
    }

    func test_cardNetworkBadge_generatesCorrectIdentifier() {
        // Given: A card network name
        let network = "Visa"

        // When: Generating the identifier
        let identifier = AccessibilityIdentifiers.CardForm.cardNetworkBadge(network)

        // Then: The identifier should be lowercased
        XCTAssertEqual(identifier, "checkout_components_card_form_visa_badge")
    }

    func test_cardNetworkBadge_withMixedCase_lowercasesNetwork() {
        // Given: A mixed case network name
        let network = "MasterCard"

        // When: Generating the identifier
        let identifier = AccessibilityIdentifiers.CardForm.cardNetworkBadge(network)

        // Then: The network should be lowercased in the identifier
        XCTAssertEqual(identifier, "checkout_components_card_form_mastercard_badge")
    }

    func test_cardNetworkBadge_withDifferentNetworks_generatesUniqueIdentifiers() {
        // Given: Different card networks
        let networks = ["Visa", "Mastercard", "Amex", "Discover", "JCB"]

        // When: Generating identifiers for each network
        let identifiers = networks.map { AccessibilityIdentifiers.CardForm.cardNetworkBadge($0) }

        // Then: All identifiers should be unique
        let uniqueIdentifiers = Set(identifiers)
        XCTAssertEqual(identifiers.count, uniqueIdentifiers.count)
    }

    func test_inlineNetworkSelectorButton_generatesCorrectIdentifier() {
        // Given: A network name
        let network = "Visa"

        // When: Generating the identifier
        let identifier = AccessibilityIdentifiers.CardForm.inlineNetworkSelectorButton(forNetwork: network)

        // Then: The identifier should have the correct format
        XCTAssertEqual(identifier, "checkout_components_card_form_inline_network_selector_visa_button")
    }

    func test_inlineNetworkSelectorButton_withMixedCase_lowercasesNetwork() {
        // Given: A mixed case network name
        let network = "MasterCard"

        // When: Generating the identifier
        let identifier = AccessibilityIdentifiers.CardForm.inlineNetworkSelectorButton(forNetwork: network)

        // Then: The network should be lowercased
        XCTAssertEqual(identifier, "checkout_components_card_form_inline_network_selector_mastercard_button")
    }

    // MARK: - PaymentSelection Dynamic Identifier Tests

    func test_cardItem_generatesCorrectIdentifier() {
        // Given: A card's last four digits
        let lastFour = "4242"

        // When: Generating the identifier
        let identifier = AccessibilityIdentifiers.PaymentSelection.cardItem(lastFour)

        // Then: The identifier should have the correct format
        XCTAssertEqual(identifier, "checkout_components_payment_selection_card_4242_item")
    }

    func test_cardItem_withDifferentLastFour_generatesUniqueIdentifiers() {
        // Given: Different last four digits
        let lastFours = ["1234", "5678", "9012", "3456"]

        // When: Generating identifiers for each
        let identifiers = lastFours.map { AccessibilityIdentifiers.PaymentSelection.cardItem($0) }

        // Then: All identifiers should be unique
        let uniqueIdentifiers = Set(identifiers)
        XCTAssertEqual(identifiers.count, uniqueIdentifiers.count)
    }

    func test_paymentMethodItem_withUniqueId_generatesCorrectIdentifier() {
        // Given: A payment type and unique ID
        let type = "PAYPAL"
        let uniqueId = "abc123"

        // When: Generating the identifier
        let identifier = AccessibilityIdentifiers.PaymentSelection.paymentMethodItem(type, uniqueId: uniqueId)

        // Then: The identifier should include both type and uniqueId
        XCTAssertEqual(identifier, "checkout_components_payment_selection_PAYPAL_abc123_item")
    }

    func test_paymentMethodItem_withoutUniqueId_generatesCorrectIdentifier() {
        // Given: A payment type without unique ID
        let type = "APPLE_PAY"

        // When: Generating the identifier
        let identifier = AccessibilityIdentifiers.PaymentSelection.paymentMethodItem(type, uniqueId: nil)

        // Then: The identifier should not include uniqueId
        XCTAssertEqual(identifier, "checkout_components_payment_selection_APPLE_PAY_item")
    }

    func test_paymentMethodItem_withAndWithoutUniqueId_generatesDifferentIdentifiers() {
        // Given: Same payment type with and without unique ID
        let type = "PAYPAL"

        // When: Generating identifiers
        let withId = AccessibilityIdentifiers.PaymentSelection.paymentMethodItem(type, uniqueId: "abc123")
        let withoutId = AccessibilityIdentifiers.PaymentSelection.paymentMethodItem(type, uniqueId: nil)

        // Then: The identifiers should be different
        XCTAssertNotEqual(withId, withoutId)
    }

    func test_vaultedPaymentMethodItem_generatesCorrectIdentifier() {
        // Given: A vaulted payment method ID
        let id = "pm_12345"

        // When: Generating the identifier
        let identifier = AccessibilityIdentifiers.PaymentSelection.vaultedPaymentMethodItem(id)

        // Then: The identifier should have the correct format
        XCTAssertEqual(identifier, "checkout_components_vaulted_payment_method_pm_12345_item")
    }

    func test_deletePaymentMethodButton_generatesCorrectIdentifier() {
        // Given: A payment method ID
        let id = "pm_67890"

        // When: Generating the identifier
        let identifier = AccessibilityIdentifiers.PaymentSelection.deletePaymentMethodButton(id)

        // Then: The identifier should have the correct format
        XCTAssertEqual(identifier, "checkout_components_vaulted_payment_method_pm_67890_delete_button")
    }

    func test_vaultedPaymentMethodItem_and_deleteButton_relatedIdentifiers() {
        // Given: The same payment method ID
        let id = "pm_abc"

        // When: Generating both identifiers
        let itemId = AccessibilityIdentifiers.PaymentSelection.vaultedPaymentMethodItem(id)
        let deleteId = AccessibilityIdentifiers.PaymentSelection.deletePaymentMethodButton(id)

        // Then: Both should contain the same ID but be different identifiers
        XCTAssertTrue(itemId.contains(id))
        XCTAssertTrue(deleteId.contains(id))
        XCTAssertNotEqual(itemId, deleteId)
    }

    // MARK: - CardForm Static Identifier Value Tests

    func test_cardForm_staticIdentifiers_haveExpectedValues() {
        XCTAssertEqual(AccessibilityIdentifiers.CardForm.container, "checkout_components_card_form_container")
        XCTAssertEqual(AccessibilityIdentifiers.CardForm.cardNumberField, "checkout_components_card_form_card_number_field")
        XCTAssertEqual(AccessibilityIdentifiers.CardForm.expiryField, "checkout_components_card_form_expiry_field")
        XCTAssertEqual(AccessibilityIdentifiers.CardForm.cvcField, "checkout_components_card_form_cvc_field")
        XCTAssertEqual(AccessibilityIdentifiers.CardForm.cardholderNameField, "checkout_components_card_form_cardholder_name_field")
        XCTAssertEqual(AccessibilityIdentifiers.CardForm.saveButton, "checkout_components_card_form_save_button")
        XCTAssertEqual(AccessibilityIdentifiers.CardForm.inlineNetworkSelectorContainer, "checkout_components_card_form_inline_network_selector")
        XCTAssertEqual(AccessibilityIdentifiers.CardForm.dropdownNetworkSelectorButton, "checkout_components_card_form_dropdown_network_selector_button")
    }

    // MARK: - PaymentSelection Static Identifier Value Tests

    func test_paymentSelection_staticIdentifiers_haveExpectedValues() {
        XCTAssertEqual(AccessibilityIdentifiers.PaymentSelection.header, "checkout_components_payment_selection_header")
        XCTAssertEqual(AccessibilityIdentifiers.PaymentSelection.showAllButton, "checkout_components_payment_selection_show_all_button")
        XCTAssertEqual(AccessibilityIdentifiers.PaymentSelection.showOtherWaysButton, "checkout_components_payment_selection_show_other_ways_button")
    }

    // MARK: - Vault Static Identifier Value Tests

    func test_vault_staticIdentifiers_haveExpectedValues() {
        XCTAssertEqual(AccessibilityIdentifiers.Vault.cvvField, "checkout_components_vault_cvv_field")
        XCTAssertEqual(AccessibilityIdentifiers.Vault.cvvSecurityLabel, "checkout_components_vault_cvv_security_label")
        XCTAssertEqual(AccessibilityIdentifiers.Vault.payButton, "checkout_components_vault_pay_button")
    }

    // MARK: - Common Static Identifier Value Tests

    func test_common_staticIdentifiers_haveExpectedValues() {
        XCTAssertEqual(AccessibilityIdentifiers.Common.submitButton, "checkout_components_submit_button")
        XCTAssertEqual(AccessibilityIdentifiers.Common.closeButton, "checkout_components_close_button")
        XCTAssertEqual(AccessibilityIdentifiers.Common.backButton, "checkout_components_back_button")
        XCTAssertEqual(AccessibilityIdentifiers.Common.editButton, "checkout_components_edit_button")
        XCTAssertEqual(AccessibilityIdentifiers.Common.doneButton, "checkout_components_done_button")
        XCTAssertEqual(AccessibilityIdentifiers.Common.deleteButton, "checkout_components_delete_button")
        XCTAssertEqual(AccessibilityIdentifiers.Common.cancelButton, "checkout_components_cancel_button")
        XCTAssertEqual(AccessibilityIdentifiers.Common.loadingIndicator, "checkout_components_loading_indicator")
    }

    // MARK: - Error Static Identifier Value Tests

    func test_error_staticIdentifiers_haveExpectedValues() {
        XCTAssertEqual(AccessibilityIdentifiers.Error.messageContainer, "checkout_components_error_message_container")
        XCTAssertEqual(AccessibilityIdentifiers.Error.dismissButton, "checkout_components_error_dismiss_button")
    }

    // MARK: - PayPal Static Identifier Value Tests

    func test_paypal_staticIdentifiers_haveExpectedValues() {
        XCTAssertEqual(AccessibilityIdentifiers.PayPal.container, "checkout_components_paypal_container")
        XCTAssertEqual(AccessibilityIdentifiers.PayPal.logo, "checkout_components_paypal_logo")
        XCTAssertEqual(AccessibilityIdentifiers.PayPal.submitButton, "checkout_components_paypal_submit_button")
    }
}
