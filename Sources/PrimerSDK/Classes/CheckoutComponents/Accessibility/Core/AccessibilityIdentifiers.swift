//
//  AccessibilityIdentifiers.swift
//  PrimerSDK
//
//  Created by Claude Code on 2025-10-28.
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//

import Foundation

/// Centralized accessibility identifiers for CheckoutComponents UI testing
///
/// **Naming Pattern**: `CheckoutComponents_{Component}_{Element}`
///
/// **Cross-Platform Alignment**: Identifiers match Android CheckoutComponents naming scheme
@available(iOS 15.0, *)
enum AccessibilityIdentifiers {

    /// CheckoutComponents module identifiers
    enum CheckoutComponents {

        /// Card form component identifiers
        enum CardForm {
            static let container = "CheckoutComponents_cardForm_container"
            static let cardNumber = "CheckoutComponents_cardForm_cardNumber"
            static let expiryDate = "CheckoutComponents_cardForm_expiryDate"
            static let cvv = "CheckoutComponents_cardForm_cvv"
            static let cardholderName = "CheckoutComponents_cardForm_cardholderName"
            static let networkSelector = "CheckoutComponents_cardForm_networkSelector"
            static let submitButton = "CheckoutComponents_cardForm_submitButton"
        }

        /// Payment method selection identifiers
        enum PaymentMethodSelection {
            static let container = "CheckoutComponents_paymentSelection_container"

            /// Generate identifier for specific payment method type
            /// - Parameter type: Payment method type (e.g., "PAYMENT_CARD", "PAYPAL")
            /// - Returns: Identifier string (e.g., "CheckoutComponents_paymentSelection_PAYMENT_CARD")
            static func paymentMethod(_ type: String) -> String {
                "CheckoutComponents_paymentSelection_\(type.uppercased())"
            }
        }

        /// Billing address component identifiers
        enum BillingAddress {
            static let container = "CheckoutComponents_billingAddress_container"
            static let firstName = "CheckoutComponents_billingAddress_firstName"
            static let lastName = "CheckoutComponents_billingAddress_lastName"
            static let addressLine1 = "CheckoutComponents_billingAddress_addressLine1"
            static let addressLine2 = "CheckoutComponents_billingAddress_addressLine2"
            static let city = "CheckoutComponents_billingAddress_city"
            static let state = "CheckoutComponents_billingAddress_state"
            static let postalCode = "CheckoutComponents_billingAddress_postalCode"
            static let country = "CheckoutComponents_billingAddress_country"
        }

        /// Error message identifiers
        enum ErrorMessages {
            static let errorSummary = "CheckoutComponents_validation_errorSummary"
            static let errorMessage = "CheckoutComponents_validation_errorMessage"

            /// Dynamic identifier for field-specific error messages
            /// - Parameter fieldName: Name of the field (e.g., "cardNumber", "expiryDate")
            /// - Returns: Identifier string like "CheckoutComponents_error_cardNumber"
            static func fieldError(_ fieldName: String) -> String {
                "CheckoutComponents_error_\(fieldName)"
            }
        }

        /// Screen-level identifiers
        enum Screens {
            static let splashScreen = "CheckoutComponents_screen_splash"
            static let successScreen = "CheckoutComponents_screen_success"
            static let errorScreen = "CheckoutComponents_screen_error"
        }
    }
}
