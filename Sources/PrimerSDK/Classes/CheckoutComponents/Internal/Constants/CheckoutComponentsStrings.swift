//
//  CheckoutComponentsStrings.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Centralized strings for CheckoutComponents to make localization easier
struct CheckoutComponentsStrings {

    // MARK: - Screen Titles (REUSING EXISTING KEYS)

    static let checkoutTitle = NSLocalizedString(
        "primer-card-form-checkout",
        bundle: Bundle.primerResources,
        value: "Checkout",
        comment: "Main checkout screen title"
    )

    static let cardPaymentTitle = NSLocalizedString(
        "payment-method-type-card-not-vaulted",
        bundle: Bundle.primerResources,
        value: "Pay with card",
        comment: "Card Payment screen title"
    )

    static let billingAddressTitle = NSLocalizedString(
        "primer-iban-form-add-bank-account",
        bundle: Bundle.primerResources,
        value: "Billing Address",
        comment: "Billing Address section title"
    )

    // MARK: - Buttons (REUSING EXISTING KEYS)

    static let payButton = NSLocalizedString(
        "primer-card-form-pay",
        bundle: Bundle.primerResources,
        value: "Pay",
        comment: "Pay button text"
    )

    static let addCardButton = NSLocalizedString(
        "primer-card-form-add-card",
        bundle: Bundle.primerResources,
        value: "Add card",
        comment: "Add card button text when storing a new card"
    )

    static let cancelButton = NSLocalizedString(
        "primer-alert-button-cancel",
        bundle: Bundle.primerResources,
        value: "Cancel",
        comment: "Cancel button text"
    )

    static let retryButton = NSLocalizedString(
        "retry_button",
        bundle: Bundle.primerResources,
        value: "Retry",
        comment: "Retry button text"
    )

    static let backButton = NSLocalizedString(
        "back_button_label",
        bundle: Bundle.primerResources,
        value: "Back",
        comment: "Back navigation button text"
    )

    // MARK: - Payment Method Selection (REUSING EXISTING KEYS)

    static let choosePaymentMethod = NSLocalizedString(
        "primer-checkout-nav-bar-title",
        bundle: Bundle.primerResources,
        value: "Choose payment method",
        comment: "Payment method selection screen subtitle"
    )

    static let additionalFeeMayApply = NSLocalizedString(
        "surcharge-additional-fee",
        bundle: Bundle.primerResources,
        value: "Additional fee may apply",
        comment: "Message shown when a surcharge might be applied"
    )

    static func paymentAmountTitle(_ amount: String) -> String {
        let format = NSLocalizedString(
            "pay_with_payment_method",
            bundle: Bundle.primerResources,
            value: "Pay %@",
            comment: "Payment amount title with formatted amount"
        )
        return String(format: format, amount)
    }

    // MARK: - Card Form Labels (REUSING EXISTING KEYS)

    static let cardNumberLabel = NSLocalizedString(
        "primer-form-text-field-title-card-number",
        bundle: Bundle.primerResources,
        value: "Card Number",
        comment: "Card number field label"
    )

    static let expiryDateLabel = NSLocalizedString(
        "primer-form-text-field-title-expiry-date",
        bundle: Bundle.primerResources,
        value: "Expiry (MM/YY)",
        comment: "Expiry date field label"
    )

    static let cvvLabel = NSLocalizedString(
        "primer-card-form-cvv",
        bundle: Bundle.primerResources,
        value: "CVV",
        comment: "CVV field label"
    )

    static let cardholderNameLabel = NSLocalizedString(
        "primer-card-form-name",
        bundle: Bundle.primerResources,
        value: "Name on card",
        comment: "Cardholder name field label"
    )

    // MARK: - Card Form Placeholders (REUSING EXISTING KEYS)

    static let cardNumberPlaceholder = NSLocalizedString(
        "primer-form-text-field-title-card-number",
        bundle: Bundle.primerResources,
        value: "1234 1234 1234 1234",
        comment: "Card number input placeholder"
    )

    static let expiryDatePlaceholder = NSLocalizedString(
        "card_expiry_date",
        bundle: Bundle.primerResources,
        value: "MM/YY",
        comment: "Expiry date input placeholder"
    )

    static let cvvPlaceholder = NSLocalizedString(
        "primer-card-form-cvv",
        bundle: Bundle.primerResources,
        value: "CVV",
        comment: "CVV input placeholder"
    )

    static let cardholderNamePlaceholder = NSLocalizedString(
        "primer-form-text-field-placeholder-cardholder",
        bundle: Bundle.primerResources,
        value: "John Doe",
        comment: "Cardholder name input placeholder"
    )

    // MARK: - Billing Address Labels (REUSING EXISTING KEYS)

    static let firstNameLabel = NSLocalizedString(
        "firstNameLabel",
        bundle: Bundle.primerResources,
        value: "First Name",
        comment: "First name field label"
    )

    static let lastNameLabel = NSLocalizedString(
        "lastNameLabel",
        bundle: Bundle.primerResources,
        value: "Last Name",
        comment: "Last name field label"
    )

    static let countryLabel = NSLocalizedString(
        "countryCodeLabel",
        bundle: Bundle.primerResources,
        value: "Country",
        comment: "Country field label"
    )

    static let addressLine1Label = NSLocalizedString(
        "addressLine1Label",
        bundle: Bundle.primerResources,
        value: "Address Line 1",
        comment: "Address line 1 label"
    )

    static let addressLine2Label = NSLocalizedString(
        "addressLine2Label",
        bundle: Bundle.primerResources,
        value: "Address Line 2 (Optional)",
        comment: "Address line 2 label"
    )

    static let cityLabel = NSLocalizedString(
        "cityLabel",
        bundle: Bundle.primerResources,
        value: "City",
        comment: "City label"
    )

    static let stateLabel = NSLocalizedString(
        "stateLabel",
        bundle: Bundle.primerResources,
        value: "State",
        comment: "State label"
    )

    static let postalCodeLabel = NSLocalizedString(
        "postalCodeLabel",
        bundle: Bundle.primerResources,
        value: "Postal Code",
        comment: "Postal code label"
    )

    // MARK: - Billing Address Placeholders (REUSING EXISTING KEYS)

    static let firstNamePlaceholder = NSLocalizedString(
        "firstNamePlaceholder",
        bundle: Bundle.primerResources,
        value: "John",
        comment: "First name placeholder"
    )

    static let lastNamePlaceholder = NSLocalizedString(
        "lastNamePlaceholder",
        bundle: Bundle.primerResources,
        value: "Doe",
        comment: "Last name placeholder"
    )

    static let selectCountryPlaceholder = NSLocalizedString(
        "countrySelectPlaceholder",
        bundle: Bundle.primerResources,
        value: "Select Country",
        comment: "Select country placeholder"
    )

    static let addressLine1Placeholder = NSLocalizedString(
        "addressLine1Placeholder",
        bundle: Bundle.primerResources,
        value: "123 Main Street",
        comment: "Address line 1 placeholder"
    )

    static let addressLine2Placeholder = NSLocalizedString(
        "addressLine2Placeholder",
        bundle: Bundle.primerResources,
        value: "Apartment, suite, etc.",
        comment: "Address line 2 placeholder"
    )

    static let cityPlaceholder = NSLocalizedString(
        "cityPlaceholder",
        bundle: Bundle.primerResources,
        value: "New York",
        comment: "City placeholder"
    )

    static let statePlaceholder = NSLocalizedString(
        "statePlaceholder",
        bundle: Bundle.primerResources,
        value: "NY",
        comment: "State placeholder"
    )

    static let postalCodePlaceholder = NSLocalizedString(
        "postalCodePlaceholder",
        bundle: Bundle.primerResources,
        value: "12345",
        comment: "Postal code placeholder"
    )

    // MARK: - Specialized Placeholders (REUSING EXISTING KEYS)

    static let searchCountriesPlaceholder = NSLocalizedString(
        "search-country-placeholder",
        bundle: Bundle.primerResources,
        value: "Search countries...",
        comment: "Search countries input placeholder"
    )

    // MARK: - Validation Errors - General (REUSING EXISTING KEYS)

    static let enterValidCardNumber = NSLocalizedString(
        "primer-error-card-form-card-number",
        bundle: Bundle.primerResources,
        value: "Enter a valid card number",
        comment: "Card number validation error message"
    )

    static let enterValidExpiryDate = NSLocalizedString(
        "primer-error-card-form-card-expiration-date",
        bundle: Bundle.primerResources,
        value: "Enter a valid expiry date",
        comment: "Expiry date validation error message"
    )

    static let enterValidCVV = NSLocalizedString(
        "primer-error-card-form-card-cvv",
        bundle: Bundle.primerResources,
        value: "Enter a valid CVV",
        comment: "CVV validation error message"
    )

    static let enterValidCardholderName = NSLocalizedString(
        "cardholderErrorInvalid",
        bundle: Bundle.primerResources,
        value: "Enter a valid name",
        comment: "Cardholder name validation error message"
    )

    // MARK: - Validation Errors - Form Specific (REUSING EXISTING KEYS)

    static let formErrorCardTypeNotSupported = NSLocalizedString(
        "form_error_card_type_not_supported",
        bundle: Bundle.primerResources,
        value: "Unsupported card type",
        comment: "Card type not supported error"
    )

    static let formErrorCardHolderNameLength = NSLocalizedString(
        "form_error_card_holder_name_length",
        bundle: Bundle.primerResources,
        value: "Name must have between 2 and 45 characters",
        comment: "Card holder name length validation error"
    )

    // MARK: - Validation Errors - Required Fields (REUSING EXISTING KEYS)

    static let firstNameErrorRequired = NSLocalizedString(
        "firstNameErrorRequired",
        bundle: Bundle.primerResources,
        value: "First name is required",
        comment: "First name required validation error"
    )

    static let lastNameErrorRequired = NSLocalizedString(
        "lastNameErrorRequired",
        bundle: Bundle.primerResources,
        value: "Last name is required",
        comment: "Last name required validation error"
    )

    static let countryCodeErrorRequired = NSLocalizedString(
        "countryCodeErrorRequired",
        bundle: Bundle.primerResources,
        value: "Country is required",
        comment: "Country required validation error"
    )

    static let addressLine1ErrorRequired = NSLocalizedString(
        "addressLine1ErrorRequired",
        bundle: Bundle.primerResources,
        value: "Address line 1 is required",
        comment: "Address line 1 required validation error"
    )

    static let addressLine2ErrorRequired = NSLocalizedString(
        "addressLine2ErrorRequired",
        bundle: Bundle.primerResources,
        value: "Address line 2 is required",
        comment: "Address line 2 required validation error"
    )

    static let cityErrorRequired = NSLocalizedString(
        "cityErrorRequired",
        bundle: Bundle.primerResources,
        value: "City is required",
        comment: "City required validation error"
    )

    static let stateErrorRequired = NSLocalizedString(
        "stateErrorRequired",
        bundle: Bundle.primerResources,
        value: "State, Region or County is required",
        comment: "State required validation error"
    )

    static let postalCodeErrorRequired = NSLocalizedString(
        "postalCodeErrorRequired",
        bundle: Bundle.primerResources,
        value: "Postal code is required",
        comment: "Postal code required validation error"
    )

    // MARK: - Validation Errors - Invalid Fields (REUSING EXISTING KEYS)

    static let firstNameErrorInvalid = NSLocalizedString(
        "firstNameErrorInvalid",
        bundle: Bundle.primerResources,
        value: "Invalid First Name",
        comment: "First name invalid validation error"
    )

    static let lastNameErrorInvalid = NSLocalizedString(
        "lastNameErrorInvalid",
        bundle: Bundle.primerResources,
        value: "Invalid Last Name",
        comment: "Last name invalid validation error"
    )

    static let countryCodeErrorInvalid = NSLocalizedString(
        "countryCodeErrorInvalid",
        bundle: Bundle.primerResources,
        value: "Invalid Country",
        comment: "Country invalid validation error"
    )

    static let addressLine1ErrorInvalid = NSLocalizedString(
        "addressLine1ErrorInvalid",
        bundle: Bundle.primerResources,
        value: "Invalid Address Line 1",
        comment: "Address line 1 invalid validation error"
    )

    static let addressLine2ErrorInvalid = NSLocalizedString(
        "addressLine2ErrorInvalid",
        bundle: Bundle.primerResources,
        value: "Invalid Address Line 2",
        comment: "Address line 2 invalid validation error"
    )

    static let cityErrorInvalid = NSLocalizedString(
        "cityErrorInvalid",
        bundle: Bundle.primerResources,
        value: "Invalid city",
        comment: "City invalid validation error"
    )

    static let stateErrorInvalid = NSLocalizedString(
        "stateErrorInvalid",
        bundle: Bundle.primerResources,
        value: "Invalid State, Region or County",
        comment: "State invalid validation error"
    )

    static let postalCodeErrorInvalid = NSLocalizedString(
        "postalCodeErrorInvalid",
        bundle: Bundle.primerResources,
        value: "Invalid postal code",
        comment: "Postal code invalid validation error"
    )

    // MARK: - System Messages (REUSING EXISTING KEYS)

    static let somethingWentWrong = NSLocalizedString(
        "primer-error-screen",
        bundle: Bundle.primerResources,
        value: "Something went wrong",
        comment: "Generic error message"
    )

    // MARK: - Empty State Messages (REUSING EXISTING KEYS)

    static let noAdditionalFee = NSLocalizedString(
        "no_additional_fee",
        bundle: Bundle.primerResources,
        value: "No additional fee",
        comment: "Message shown when no surcharge applies"
    )

    // MARK: - Success Screen Details (REUSING EXISTING KEYS)

    static let paymentSuccessful = NSLocalizedString(
        "session_complete_payment_success_title",
        bundle: Bundle.primerResources,
        value: "Payment Successful",
        comment: "Success screen title"
    )

    static let paymentFailed = NSLocalizedString(
        "session_complete_payment_failure_title",
        bundle: Bundle.primerResources,
        value: "Payment Failed",
        comment: "Error screen title for payment failures"
    )

    static func paymentMethodDisplayName(_ displayName: String) -> String {
        let format = NSLocalizedString(
            "pay_with_payment_method",
            bundle: Bundle.primerResources,
            value: "Payment Method: %@",
            comment: "Payment method display format with method name"
        )
        return String(format: format, displayName)
    }

    // MARK: - ⚠️ CHECKOUTCOMPONENTS-SPECIFIC STRINGS (PHASE 2 - TO BE EXPORTED) ⚠️
    // These strings are unique to CheckoutComponents and need to be added to all .lproj files

    static let selectNetworkTitle = NSLocalizedString(
        "checkout-components-select-network-title",
        bundle: Bundle.primerResources,
        value: "Select Network",
        comment: "Card network selection title"
    )

    static let selectCountryTitle = NSLocalizedString(
        "checkout-components-select-country-title",
        bundle: Bundle.primerResources,
        value: "Select Country",
        comment: "Country selection screen title"
    )

    static let expiryDateAlternativePlaceholder = NSLocalizedString(
        "checkout-components-expiry-date-alternative-placeholder",
        bundle: Bundle.primerResources,
        value: "12/25",
        comment: "Alternative expiry date input placeholder"
    )

    static let cvvAmexPlaceholder = NSLocalizedString(
        "checkout-components-cvv-amex-placeholder",
        bundle: Bundle.primerResources,
        value: "1234",
        comment: "CVV input placeholder for American Express"
    )

    static let cvvStandardPlaceholder = NSLocalizedString(
        "checkout-components-cvv-standard-placeholder",
        bundle: Bundle.primerResources,
        value: "123",
        comment: "CVV input placeholder for standard cards"
    )

    static let fullNamePlaceholder = NSLocalizedString(
        "checkout-components-full-name-placeholder",
        bundle: Bundle.primerResources,
        value: "Full name",
        comment: "Full name input placeholder"
    )

    static let emailLabel = NSLocalizedString(
        "checkout-components-email-label",
        bundle: Bundle.primerResources,
        value: "Email",
        comment: "Email field label"
    )

    static let phoneNumberLabel = NSLocalizedString(
        "checkout-components-phone-number-label",
        bundle: Bundle.primerResources,
        value: "Phone Number",
        comment: "Phone number field label"
    )

    static let emailPlaceholder = NSLocalizedString(
        "checkout-components-email-placeholder",
        bundle: Bundle.primerResources,
        value: "john.doe@example.com",
        comment: "Email placeholder"
    )

    static let phoneNumberPlaceholder = NSLocalizedString(
        "checkout-components-phone-placeholder",
        bundle: Bundle.primerResources,
        value: "+1 (555) 123-4567",
        comment: "Phone number placeholder"
    )

    static let countrySelectorPlaceholder = NSLocalizedString(
        "checkout-components-country-selector-placeholder",
        bundle: Bundle.primerResources,
        value: "Country Selector",
        comment: "Country selector placeholder"
    )

    static let retailOutletPlaceholder = NSLocalizedString(
        "checkout-components-retail-outlet-placeholder",
        bundle: Bundle.primerResources,
        value: "Retail Outlet",
        comment: "Retail outlet input placeholder"
    )

    static let otpCodePlaceholder = NSLocalizedString(
        "checkout-components-otp-code-placeholder",
        bundle: Bundle.primerResources,
        value: "OTP Code",
        comment: "OTP code input placeholder"
    )

    static let otpCodeNumericPlaceholder = NSLocalizedString(
        "checkout-components-otp-code-numeric-placeholder",
        bundle: Bundle.primerResources,
        value: "123456",
        comment: "Numeric OTP code input placeholder"
    )

    static let enterValidPhoneNumber = NSLocalizedString(
        "checkout-components-enter-valid-phone-number",
        bundle: Bundle.primerResources,
        value: "Enter a valid phone number",
        comment: "Phone number validation error message"
    )

    static let emailErrorRequired = NSLocalizedString(
        "checkout-components-email-required",
        bundle: Bundle.primerResources,
        value: "Email is required",
        comment: "Email required validation error"
    )

    static let emailErrorInvalid = NSLocalizedString(
        "checkout-components-email-invalid",
        bundle: Bundle.primerResources,
        value: "Invalid email",
        comment: "Email invalid validation error"
    )

    static let formErrorCardExpired = NSLocalizedString(
        "checkout-components-card-expired",
        bundle: Bundle.primerResources,
        value: "Card has expired",
        comment: "Card expired validation error"
    )

    static let loadingSecureCheckout = NSLocalizedString(
        "checkout-components-loading-secure-checkout",
        bundle: Bundle.primerResources,
        value: "Loading your secure checkout",
        comment: "Main loading message for secure checkout"
    )

    static let loadingWontTakeLong = NSLocalizedString(
        "checkout-components-loading-wont-take-long",
        bundle: Bundle.primerResources,
        value: "This won't take long",
        comment: "Secondary loading message indicating quick loading time"
    )

    static let dismissingMessage = NSLocalizedString(
        "checkout-components-dismissing",
        bundle: Bundle.primerResources,
        value: "Dismissing...",
        comment: "Message shown while dismissing checkout"
    )

    static let unexpectedError = NSLocalizedString(
        "checkout-components-unexpected-error",
        bundle: Bundle.primerResources,
        value: "An unexpected error occurred.",
        comment: "Unexpected error message"
    )

    static let paymentSystemError = NSLocalizedString(
        "checkout-components-payment-system-error",
        bundle: Bundle.primerResources,
        value: "Payment System Error",
        comment: "Error title when payment system initialization fails"
    )

    static let checkoutScopeNotAvailable = NSLocalizedString(
        "checkout-components-checkout-scope-not-available",
        bundle: Bundle.primerResources,
        value: "Checkout scope not available",
        comment: "Error when checkout scope is not accessible"
    )

    static let noPaymentMethodsAvailable = NSLocalizedString(
        "checkout-components-no-payment-methods",
        bundle: Bundle.primerResources,
        value: "No payment methods available",
        comment: "Empty state message when no payment methods are available"
    )

    static let noCountriesFound = NSLocalizedString(
        "checkout-components-no-countries-found",
        bundle: Bundle.primerResources,
        value: "No countries found",
        comment: "Message when country search returns no results"
    )

    static let autoDismissMessage = NSLocalizedString(
        "checkout-components-auto-dismiss",
        bundle: Bundle.primerResources,
        value: "This screen will close automatically in 3 seconds",
        comment: "Auto-dismiss message on success and error screens"
    )

    static let redirectConfirmationMessage = NSLocalizedString(
        "checkout-components-redirect-confirmation",
        bundle: Bundle.primerResources,
        value: "You'll be redirected to the order confirmation page soon.",
        comment: "Message shown on success screen about upcoming redirect"
    )

    static let implementationComingSoon = NSLocalizedString(
        "checkout-components-implementation-coming-soon",
        bundle: Bundle.primerResources,
        value: "Implementation coming soon",
        comment: "Placeholder message for features under development"
    )

    static let retailOutletNotImplemented = NSLocalizedString(
        "checkout-components-retail-outlet-not-implemented",
        bundle: Bundle.primerResources,
        value: "Retail outlet selection not yet implemented",
        comment: "Message for retail outlet feature not yet available"
    )
}
