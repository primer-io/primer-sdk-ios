//
//  AccessibilityIdentifiers.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Centralized type-safe accessibility identifiers for CheckoutComponents
///
/// ## Naming Convention
/// All identifiers follow the pattern: `checkout_components_{screen}_{component}_{element}`
/// Snake_case maintains compatibility with Appium/XCUITest conventions
///
/// ## Stability Guarantee
/// These identifiers are considered API contract. Changes require SDK major version bump.
enum AccessibilityIdentifiers {

    /// Card form accessibility identifiers
    enum CardForm {
        /// Container for entire card form
        static let container = "checkout_components_card_form_container"

        /// Card number input field
        static let cardNumberField = "checkout_components_card_form_card_number_field"

        /// Expiry date input field
        static let expiryField = "checkout_components_card_form_expiry_field"

        /// CVC/CVV security code input field
        static let cvcField = "checkout_components_card_form_cvc_field"

        /// Cardholder name input field
        static let cardholderNameField = "checkout_components_card_form_cardholder_name_field"

        /// Save card button
        static let saveButton = "checkout_components_card_form_save_button"

        /// Dynamic identifier for billing address fields
        /// - Parameter field: Field name (e.g., "line1", "city", "postal_code")
        /// - Returns: Unique identifier for this billing field
        static func billingAddressField(_ field: String) -> String {
            "checkout_components_card_form_billing_\(field)_field"
        }

        /// Dynamic identifier for card network badges
        /// - Parameter network: Card network name (e.g., "visa", "mastercard")
        /// - Returns: Unique identifier for network badge
        static func cardNetworkBadge(_ network: String) -> String {
            "checkout_components_card_form_\(network.lowercased())_badge"
        }
    }

    /// Payment method selection accessibility identifiers
    enum PaymentSelection {
        /// Container for payment method list
        static let container = "checkout_components_payment_selection_container"

        /// Header/title for payment method selection screen
        static let header = "checkout_components_payment_selection_header"

        /// Dynamic identifier for saved card items
        /// - Parameter lastFour: Last 4 digits of card number
        /// - Returns: Unique identifier for this saved card
        static func cardItem(_ lastFour: String) -> String {
            "checkout_components_payment_selection_card_\(lastFour)_item"
        }

        /// Dynamic identifier for generic payment method items
        /// - Parameters:
        ///   - type: Payment method type (e.g., "card", "bank_transfer")
        ///   - uniqueId: Optional unique identifier for multiple instances
        /// - Returns: Unique identifier for this payment method
        static func paymentMethodItem(_ type: String, uniqueId: String?) -> String {
            if let uniqueId = uniqueId {
                return "checkout_components_payment_selection_\(type)_\(uniqueId)_item"
            }
            return "checkout_components_payment_selection_\(type)_item"
        }
    }

    /// Common/shared UI element identifiers
    enum Common {
        /// Primary submit button (e.g., "Pay $49.99")
        static let submitButton = "checkout_components_submit_button"

        /// Close/dismiss button
        static let closeButton = "checkout_components_close_button"

        /// Back navigation button
        static let backButton = "checkout_components_back_button"

        /// Loading/progress indicator
        static let loadingIndicator = "checkout_components_loading_indicator"
    }

    /// Error state accessibility identifiers
    enum Error {
        /// Container for error messages
        static let messageContainer = "checkout_components_error_message_container"

        /// Dismiss error button
        static let dismissButton = "checkout_components_error_dismiss_button"
    }
}
