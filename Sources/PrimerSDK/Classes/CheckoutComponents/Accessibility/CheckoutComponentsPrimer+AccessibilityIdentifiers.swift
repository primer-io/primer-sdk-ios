//
//  CheckoutComponentsPrimer+AccessibilityIdentifiers.swift
//  PrimerSDK
//
//  Created by Claude Code on 2025-10-28.
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//

import Foundation

// MARK: - Accessibility Identifiers

@available(iOS 15.0, *)
extension CheckoutComponentsPrimer {

    /// Accessibility identifiers for UI testing automation
    ///
    /// These stable identifiers enable reliable UI test automation using tools like Appium,
    /// XCUITest, and other automation frameworks. Identifiers are guaranteed to remain
    /// consistent across SDK versions.
    ///
    /// **Usage Example (XCUITest)**:
    /// ```swift
    /// let cardNumberField = app.textFields[CheckoutComponentsPrimer.AccessibilityIdentifiers.CardForm.cardNumber]
    /// cardNumberField.tap()
    /// cardNumberField.typeText("4111111111111111")
    /// ```
    ///
    /// **Usage Example (Appium)**:
    /// ```python
    /// card_number_field = driver.find_element(
    ///     by=AppiumBy.ACCESSIBILITY_ID,
    ///     value="CheckoutComponents_cardForm_cardNumber"
    /// )
    /// card_number_field.send_keys("4111111111111111")
    /// ```
    public enum AccessibilityIdentifiers {

        /// Card form component identifiers
        public enum CardForm {
            /// Container for the entire card form
            public static let container = "CheckoutComponents_cardForm_container"

            /// Card number input field
            public static let cardNumber = "CheckoutComponents_cardForm_cardNumber"

            /// Expiry date input field
            public static let expiryDate = "CheckoutComponents_cardForm_expiryDate"

            /// CVV/CVC input field
            public static let cvv = "CheckoutComponents_cardForm_cvv"

            /// Cardholder name input field
            public static let cardholderName = "CheckoutComponents_cardForm_cardholderName"

            /// Card network selector (for co-badged cards)
            public static let networkSelector = "CheckoutComponents_cardForm_networkSelector"

            /// Submit button
            public static let submitButton = "CheckoutComponents_cardForm_submitButton"
        }

        /// Payment method selection identifiers
        public enum PaymentMethodSelection {
            /// Container for payment method selection screen
            public static let container = "CheckoutComponents_paymentSelection_container"

            /// Generate identifier for specific payment method type
            /// - Parameter type: Payment method type (e.g., "PAYMENT_CARD", "PAYPAL", "APPLE_PAY")
            /// - Returns: Identifier string (e.g., "CheckoutComponents_paymentSelection_PAYMENT_CARD")
            ///
            /// **Example**:
            /// ```swift
            /// let cardOption = app.buttons[
            ///     CheckoutComponentsPrimer.AccessibilityIdentifiers.PaymentMethodSelection.paymentMethod("PAYMENT_CARD")
            /// ]
            /// ```
            public static func paymentMethod(_ type: String) -> String {
                "CheckoutComponents_paymentSelection_\(type.uppercased())"
            }
        }

        /// Billing address component identifiers
        public enum BillingAddress {
            /// Container for billing address section
            public static let container = "CheckoutComponents_billingAddress_container"

            /// First name input field
            public static let firstName = "CheckoutComponents_billingAddress_firstName"

            /// Last name input field
            public static let lastName = "CheckoutComponents_billingAddress_lastName"

            /// Address line 1 input field
            public static let addressLine1 = "CheckoutComponents_billingAddress_addressLine1"

            /// Address line 2 input field (optional)
            public static let addressLine2 = "CheckoutComponents_billingAddress_addressLine2"

            /// City input field
            public static let city = "CheckoutComponents_billingAddress_city"

            /// State/province input field
            public static let state = "CheckoutComponents_billingAddress_state"

            /// Postal code input field
            public static let postalCode = "CheckoutComponents_billingAddress_postalCode"

            /// Country selector
            public static let country = "CheckoutComponents_billingAddress_country"
        }

        /// Error message identifiers
        public enum ErrorMessages {
            /// Error summary message (shown when multiple errors exist)
            public static let errorSummary = "CheckoutComponents_validation_errorSummary"

            /// Generic error message
            public static let errorMessage = "CheckoutComponents_validation_errorMessage"

            /// Dynamic identifier for field-specific error messages
            /// - Parameter fieldName: Name of the field (e.g., "cardNumber", "expiryDate")
            /// - Returns: Identifier string like "CheckoutComponents_error_cardNumber"
            ///
            /// **Example**:
            /// ```swift
            /// let cardNumberError = app.staticTexts[
            ///     CheckoutComponentsPrimer.AccessibilityIdentifiers.ErrorMessages.fieldError("cardNumber")
            /// ]
            /// ```
            public static func fieldError(_ fieldName: String) -> String {
                "CheckoutComponents_error_\(fieldName)"
            }
        }

        /// Screen-level identifiers
        public enum Screens {
            /// Splash/loading screen
            public static let splashScreen = "CheckoutComponents_screen_splash"

            /// Payment success screen
            public static let successScreen = "CheckoutComponents_screen_success"

            /// Payment error/failure screen
            public static let errorScreen = "CheckoutComponents_screen_error"
        }
    }
}
