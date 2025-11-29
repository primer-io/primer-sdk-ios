//
//  AccessibilityIdentifiers.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

enum AccessibilityIdentifiers {
    enum CardForm {
        static let container = "checkout_components_card_form_container"
        static let cardNumberField = "checkout_components_card_form_card_number_field"
        static let expiryField = "checkout_components_card_form_expiry_field"
        static let cvcField = "checkout_components_card_form_cvc_field"
        static let cardholderNameField = "checkout_components_card_form_cardholder_name_field"
        static let saveButton = "checkout_components_card_form_save_button"

        static func billingAddressField(_ field: String) -> String {
            "checkout_components_card_form_billing_\(field)_field"
        }

        static func cardNetworkBadge(_ network: String) -> String {
            "checkout_components_card_form_\(network.lowercased())_badge"
        }

        static let inlineNetworkSelectorContainer = "checkout_components_card_form_inline_network_selector"

        static func inlineNetworkSelectorButton(forNetwork network: String) -> String {
            "checkout_components_card_form_inline_network_selector_\(network.lowercased())_button"
        }

        static let dropdownNetworkSelectorButton = "checkout_components_card_form_dropdown_network_selector_button"
    }

    enum PaymentSelection {
        static let header = "checkout_components_payment_selection_header"

        static func cardItem(_ lastFour: String) -> String {
            "checkout_components_payment_selection_card_\(lastFour)_item"
        }

        static func paymentMethodItem(_ type: String, uniqueId: String?) -> String {
            if let uniqueId = uniqueId {
                return "checkout_components_payment_selection_\(type)_\(uniqueId)_item"
            }
            return "checkout_components_payment_selection_\(type)_item"
        }
    }

    enum Common {
        static let submitButton = "checkout_components_submit_button"
        static let closeButton = "checkout_components_close_button"
        static let backButton = "checkout_components_back_button"
        static let loadingIndicator = "checkout_components_loading_indicator"
    }

    enum Error {
        static let messageContainer = "checkout_components_error_message_container"
        static let dismissButton = "checkout_components_error_dismiss_button"
    }
}
