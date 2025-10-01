//
//  CheckoutComponentsStrings.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Centralized strings for CheckoutComponents to make localization easier
internal struct CheckoutComponentsStrings {

    // MARK: - Screen Titles

    static let checkoutTitle = NSLocalizedString(
        "checkout-components-checkout-title",
        bundle: Bundle.primerResources,
        value: "Checkout",
        comment: "Main checkout screen title"
    )

    static let cardPaymentTitle = NSLocalizedString(
        "checkout-components-card-payment-title",
        bundle: Bundle.primerResources,
        value: "Pay with card",
        comment: "Card Payment screen title"
    )

    static let billingAddressTitle = NSLocalizedString(
        "checkout-components-billing-address-title",
        bundle: Bundle.primerResources,
        value: "Billing Address",
        comment: "Billing Address section title"
    )

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

    // MARK: - Buttons

    static let payButton = NSLocalizedString(
        "checkout-components-pay-button",
        bundle: Bundle.primerResources,
        value: "Pay",
        comment: "Pay button text"
    )

    static let cancelButton = NSLocalizedString(
        "checkout-components-cancel-button",
        bundle: Bundle.primerResources,
        value: "Cancel",
        comment: "Cancel button text"
    )

    static let retryButton = NSLocalizedString(
        "checkout-components-retry-button",
        bundle: Bundle.primerResources,
        value: "Retry",
        comment: "Retry button text"
    )

    static let backButton = NSLocalizedString(
        "checkout-components-back-button",
        bundle: Bundle.primerResources,
        value: "Back",
        comment: "Back navigation button text"
    )

    // MARK: - Payment Method Selection

    static let choosePaymentMethod = NSLocalizedString(
        "checkout-components-choose-payment-method",
        bundle: Bundle.primerResources,
        value: "Choose payment method",
        comment: "Payment method selection screen subtitle"
    )

    static let surchargeFeeSectionTitle = NSLocalizedString(
        "checkout-components-surcharge-fee",
        bundle: Bundle.primerResources,
        value: "Surcharge fee",
        comment: "Surcharge fee section title"
    )

    static func paymentAmountTitle(_ amount: String) -> String {
        let format = NSLocalizedString(
            "checkout-components-pay-amount",
            bundle: Bundle.primerResources,
            value: "Pay %@",
            comment: "Payment amount title with formatted amount"
        )
        return String(format: format, amount)
    }

    // MARK: - Payment Method Names

    static let payPalMethodName = NSLocalizedString(
        "checkout-components-paypal-name",
        bundle: Bundle.primerResources,
        value: "PayPal",
        comment: "PayPal payment method name"
    )

    static let klarnaMethodName = NSLocalizedString(
        "checkout-components-klarna-name",
        bundle: Bundle.primerResources,
        value: "Klarna",
        comment: "Klarna payment method name"
    )

    static let idealMethodName = NSLocalizedString(
        "checkout-components-ideal-name",
        bundle: Bundle.primerResources,
        value: "iDeal",
        comment: "iDeal payment method name"
    )

    // MARK: - Card Form Labels

    static let cardNumberLabel = NSLocalizedString(
        "checkout-components-card-number-label",
        bundle: Bundle.primerResources,
        value: "Card Number",
        comment: "Card number field label"
    )

    static let expiryDateLabel = NSLocalizedString(
        "checkout-components-expiry-date-label",
        bundle: Bundle.primerResources,
        value: "Expiry Date",
        comment: "Expiry date field label"
    )

    static let cvvLabel = NSLocalizedString(
        "checkout-components-cvv-label",
        bundle: Bundle.primerResources,
        value: "CVV",
        comment: "CVV field label"
    )

    static let cardholderNameLabel = NSLocalizedString(
        "checkout-components-cardholder-name-label",
        bundle: Bundle.primerResources,
        value: "Cardholder Name",
        comment: "Cardholder name field label"
    )

    // MARK: - Card Form Placeholders

    static let cardNumberPlaceholder = NSLocalizedString(
        "checkout-components-card-number-placeholder",
        bundle: Bundle.primerResources,
        value: "1234 1234 1234 1234",
        comment: "Card number input placeholder"
    )

    static let expiryDatePlaceholder = NSLocalizedString(
        "checkout-components-expiry-date-placeholder",
        bundle: Bundle.primerResources,
        value: "MM/YY",
        comment: "Expiry date input placeholder"
    )

    static let expiryDateAlternativePlaceholder = NSLocalizedString(
        "checkout-components-expiry-date-alternative-placeholder",
        bundle: Bundle.primerResources,
        value: "12/25",
        comment: "Alternative expiry date input placeholder"
    )

    static let cvvPlaceholder = NSLocalizedString(
        "checkout-components-cvv-placeholder",
        bundle: Bundle.primerResources,
        value: "CVV",
        comment: "CVV input placeholder"
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

    static let cardholderNamePlaceholder = NSLocalizedString(
        "checkout-components-cardholder-name-placeholder",
        bundle: Bundle.primerResources,
        value: "John Doe",
        comment: "Cardholder name input placeholder"
    )

    // MARK: - Billing Address Labels

    static let firstNameLabel = NSLocalizedString(
        "checkout-components-first-name-label",
        bundle: Bundle.primerResources,
        value: "First Name",
        comment: "First name field label"
    )

    static let lastNameLabel = NSLocalizedString(
        "checkout-components-last-name-label",
        bundle: Bundle.primerResources,
        value: "Last Name",
        comment: "Last name field label"
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

    static let countryLabel = NSLocalizedString(
        "checkout-components-country-label",
        bundle: Bundle.primerResources,
        value: "Country",
        comment: "Country field label"
    )

    static let addressLine1Label = NSLocalizedString(
        "checkout-components-address-line-1-label",
        bundle: Bundle.primerResources,
        value: "Address Line 1",
        comment: "Address line 1 label"
    )

    static let addressLine2Label = NSLocalizedString(
        "checkout-components-address-line-2-label",
        bundle: Bundle.primerResources,
        value: "Address Line 2 (Optional)",
        comment: "Address line 2 label"
    )

    static let cityLabel = NSLocalizedString(
        "checkout-components-city-label",
        bundle: Bundle.primerResources,
        value: "City",
        comment: "City label"
    )

    static let stateLabel = NSLocalizedString(
        "checkout-components-state-label",
        bundle: Bundle.primerResources,
        value: "State",
        comment: "State label"
    )

    static let postalCodeLabel = NSLocalizedString(
        "checkout-components-postal-code-label",
        bundle: Bundle.primerResources,
        value: "Postal Code",
        comment: "Postal code label"
    )

    // MARK: - Billing Address Placeholders

    static let firstNamePlaceholder = NSLocalizedString(
        "checkout-components-first-name-placeholder",
        bundle: Bundle.primerResources,
        value: "John",
        comment: "First name placeholder"
    )

    static let lastNamePlaceholder = NSLocalizedString(
        "checkout-components-last-name-placeholder",
        bundle: Bundle.primerResources,
        value: "Doe",
        comment: "Last name placeholder"
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

    static let selectCountryPlaceholder = NSLocalizedString(
        "checkout-components-select-country-placeholder",
        bundle: Bundle.primerResources,
        value: "Select Country",
        comment: "Select country placeholder"
    )

    static let addressLine1Placeholder = NSLocalizedString(
        "checkout-components-address-line-1-placeholder",
        bundle: Bundle.primerResources,
        value: "123 Main Street",
        comment: "Address line 1 placeholder"
    )

    static let addressLine2Placeholder = NSLocalizedString(
        "checkout-components-address-line-2-placeholder",
        bundle: Bundle.primerResources,
        value: "Apartment, suite, etc.",
        comment: "Address line 2 placeholder"
    )

    static let cityPlaceholder = NSLocalizedString(
        "checkout-components-city-placeholder",
        bundle: Bundle.primerResources,
        value: "New York",
        comment: "City placeholder"
    )

    static let statePlaceholder = NSLocalizedString(
        "checkout-components-state-placeholder",
        bundle: Bundle.primerResources,
        value: "NY",
        comment: "State placeholder"
    )

    static let postalCodePlaceholder = NSLocalizedString(
        "checkout-components-postal-code-placeholder",
        bundle: Bundle.primerResources,
        value: "12345",
        comment: "Postal code placeholder"
    )

    // MARK: - Specialized Placeholders

    static let countrySelectorPlaceholder = NSLocalizedString(
        "checkout-components-country-selector-placeholder",
        bundle: Bundle.primerResources,
        value: "Country Selector",
        comment: "Country selector placeholder"
    )

    static let searchCountriesPlaceholder = NSLocalizedString(
        "checkout-components-search-countries-placeholder",
        bundle: Bundle.primerResources,
        value: "Search countries...",
        comment: "Search countries input placeholder"
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

    // MARK: - Validation Errors - General

    static let enterValidCardNumber = NSLocalizedString(
        "checkout-components-enter-valid-card-number",
        bundle: Bundle.primerResources,
        value: "Enter a valid card number",
        comment: "Card number validation error message"
    )

    static let enterValidExpiryDate = NSLocalizedString(
        "checkout-components-enter-valid-expiry-date",
        bundle: Bundle.primerResources,
        value: "Enter a valid expiry date",
        comment: "Expiry date validation error message"
    )

    static let enterValidCVV = NSLocalizedString(
        "checkout-components-enter-valid-cvv",
        bundle: Bundle.primerResources,
        value: "Enter a valid CVV",
        comment: "CVV validation error message"
    )

    static let enterValidCardholderName = NSLocalizedString(
        "checkout-components-enter-valid-cardholder-name",
        bundle: Bundle.primerResources,
        value: "Enter a valid cardholder name",
        comment: "Cardholder name validation error message"
    )

    static let enterValidPostalCode = NSLocalizedString(
        "checkout-components-enter-valid-postal-code",
        bundle: Bundle.primerResources,
        value: "Enter a valid postal code",
        comment: "Postal code validation error message"
    )

    static let enterValidCity = NSLocalizedString(
        "checkout-components-enter-valid-city",
        bundle: Bundle.primerResources,
        value: "Enter a valid city",
        comment: "City validation error message"
    )

    static let enterValidState = NSLocalizedString(
        "checkout-components-enter-valid-state",
        bundle: Bundle.primerResources,
        value: "Enter a valid state",
        comment: "State validation error message"
    )

    static let enterValidAddress = NSLocalizedString(
        "checkout-components-enter-valid-address",
        bundle: Bundle.primerResources,
        value: "Enter a valid address",
        comment: "Address validation error message"
    )

    static let enterValidEmail = NSLocalizedString(
        "checkout-components-enter-valid-email",
        bundle: Bundle.primerResources,
        value: "Enter a valid email",
        comment: "Email validation error message"
    )

    static let enterValidPhoneNumber = NSLocalizedString(
        "checkout-components-enter-valid-phone-number",
        bundle: Bundle.primerResources,
        value: "Enter a valid phone number",
        comment: "Phone number validation error message"
    )

    static let selectValidCountry = NSLocalizedString(
        "checkout-components-select-valid-country",
        bundle: Bundle.primerResources,
        value: "Select a valid country",
        comment: "Country selection validation error message"
    )

    // MARK: - Validation Errors - Form Specific

    static let formErrorCardTypeNotSupported = NSLocalizedString(
        "checkout-components-card-type-not-supported",
        bundle: Bundle.primerResources,
        value: "Unsupported card type",
        comment: "Card type not supported error"
    )

    static let formErrorCardHolderNameLength = NSLocalizedString(
        "checkout-components-card-holder-name-length",
        bundle: Bundle.primerResources,
        value: "Name must have between 2 and 45 characters",
        comment: "Card holder name length validation error"
    )

    static let formErrorCardExpired = NSLocalizedString(
        "checkout-components-card-expired",
        bundle: Bundle.primerResources,
        value: "Card has expired",
        comment: "Card expired validation error"
    )

    // MARK: - Validation Errors - Required Fields

    static let firstNameErrorRequired = NSLocalizedString(
        "checkout-components-first-name-required",
        bundle: Bundle.primerResources,
        value: "First name is required",
        comment: "First name required validation error"
    )

    static let lastNameErrorRequired = NSLocalizedString(
        "checkout-components-last-name-required",
        bundle: Bundle.primerResources,
        value: "Last name is required",
        comment: "Last name required validation error"
    )

    static let emailErrorRequired = NSLocalizedString(
        "checkout-components-email-required",
        bundle: Bundle.primerResources,
        value: "Email is required",
        comment: "Email required validation error"
    )

    static let countryCodeErrorRequired = NSLocalizedString(
        "checkout-components-country-required",
        bundle: Bundle.primerResources,
        value: "Country is required",
        comment: "Country required validation error"
    )

    static let addressLine1ErrorRequired = NSLocalizedString(
        "checkout-components-address-line-1-required",
        bundle: Bundle.primerResources,
        value: "Address line 1 is required",
        comment: "Address line 1 required validation error"
    )

    static let addressLine2ErrorRequired = NSLocalizedString(
        "checkout-components-address-line-2-required",
        bundle: Bundle.primerResources,
        value: "Address line 2 is required",
        comment: "Address line 2 required validation error"
    )

    static let cityErrorRequired = NSLocalizedString(
        "checkout-components-city-required",
        bundle: Bundle.primerResources,
        value: "City is required",
        comment: "City required validation error"
    )

    static let stateErrorRequired = NSLocalizedString(
        "checkout-components-state-required",
        bundle: Bundle.primerResources,
        value: "State, Region or County is required",
        comment: "State required validation error"
    )

    static let postalCodeErrorRequired = NSLocalizedString(
        "checkout-components-postal-code-required",
        bundle: Bundle.primerResources,
        value: "Postal code is required",
        comment: "Postal code required validation error"
    )

    // MARK: - Validation Errors - Invalid Fields

    static let firstNameErrorInvalid = NSLocalizedString(
        "checkout-components-first-name-invalid",
        bundle: Bundle.primerResources,
        value: "Invalid First Name",
        comment: "First name invalid validation error"
    )

    static let lastNameErrorInvalid = NSLocalizedString(
        "checkout-components-last-name-invalid",
        bundle: Bundle.primerResources,
        value: "Invalid Last Name",
        comment: "Last name invalid validation error"
    )

    static let emailErrorInvalid = NSLocalizedString(
        "checkout-components-email-invalid",
        bundle: Bundle.primerResources,
        value: "Invalid email",
        comment: "Email invalid validation error"
    )

    static let countryCodeErrorInvalid = NSLocalizedString(
        "checkout-components-country-invalid",
        bundle: Bundle.primerResources,
        value: "Invalid Country",
        comment: "Country invalid validation error"
    )

    static let addressLine1ErrorInvalid = NSLocalizedString(
        "checkout-components-address-line-1-invalid",
        bundle: Bundle.primerResources,
        value: "Invalid Address Line 1",
        comment: "Address line 1 invalid validation error"
    )

    static let addressLine2ErrorInvalid = NSLocalizedString(
        "checkout-components-address-line-2-invalid",
        bundle: Bundle.primerResources,
        value: "Invalid Address Line 2",
        comment: "Address line 2 invalid validation error"
    )

    static let cityErrorInvalid = NSLocalizedString(
        "checkout-components-city-invalid",
        bundle: Bundle.primerResources,
        value: "Invalid city",
        comment: "City invalid validation error"
    )

    static let stateErrorInvalid = NSLocalizedString(
        "checkout-components-state-invalid",
        bundle: Bundle.primerResources,
        value: "Invalid State, Region or County",
        comment: "State invalid validation error"
    )

    static let postalCodeErrorInvalid = NSLocalizedString(
        "checkout-components-postal-code-invalid",
        bundle: Bundle.primerResources,
        value: "Invalid postal code",
        comment: "Postal code invalid validation error"
    )

    // MARK: - System Messages

    static let initializingPaymentSystem = NSLocalizedString(
        "checkout-components-initializing-payment-system",
        bundle: Bundle.primerResources,
        value: "Initializing payment system...",
        comment: "Loading message during payment system initialization"
    )

    static let loadingPaymentMethods = NSLocalizedString(
        "checkout-components-loading-payment-methods",
        bundle: Bundle.primerResources,
        value: "Loading payment methods...",
        comment: "Loading message for payment methods"
    )

    static let dismissingMessage = NSLocalizedString(
        "checkout-components-dismissing",
        bundle: Bundle.primerResources,
        value: "Dismissing...",
        comment: "Message shown while dismissing checkout"
    )

    // MARK: - General Error Messages

    static let somethingWentWrong = NSLocalizedString(
        "checkout-components-something-went-wrong",
        bundle: Bundle.primerResources,
        value: "Something went wrong",
        comment: "Generic error message"
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

    // MARK: - Empty State Messages

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

    // MARK: - Surcharge Display Messages

    static let noAdditionalFee = NSLocalizedString(
        "checkout-components-no-additional-fee",
        bundle: Bundle.primerResources,
        value: "No additional fee",
        comment: "Message shown when no surcharge applies"
    )

    static let feeMayApply = NSLocalizedString(
        "checkout-components-fee-may-apply",
        bundle: Bundle.primerResources,
        value: "Fee may apply",
        comment: "Message shown when surcharge amount is unknown"
    )

    // MARK: - Success Screen Details

    static let paymentSuccessful = NSLocalizedString(
        "checkout-components-payment-successful",
        bundle: Bundle.primerResources,
        value: "Payment Successful",
        comment: "Success screen title"
    )

    static let paymentFailed = NSLocalizedString(
        "checkout-components-payment-failed",
        bundle: Bundle.primerResources,
        value: "Payment Failed",
        comment: "Error screen title for payment failures"
    )

    static let paymentId = NSLocalizedString(
        "checkout-components-payment-id",
        bundle: Bundle.primerResources,
        value: "Payment ID",
        comment: "Payment ID label on success screen"
    )

    static let amount = NSLocalizedString(
        "checkout-components-amount",
        bundle: Bundle.primerResources,
        value: "Amount",
        comment: "Amount label on success screen"
    )

    static let paymentMethod = NSLocalizedString(
        "checkout-components-payment-method",
        bundle: Bundle.primerResources,
        value: "Payment Method",
        comment: "Payment method label on success screen"
    )

    static let autoDismissMessage = NSLocalizedString(
        "checkout-components-auto-dismiss",
        bundle: Bundle.primerResources,
        value: "This screen will close automatically in 3 seconds",
        comment: "Auto-dismiss message on success and error screens"
    )

    // MARK: - Brand and Company

    static let primerBrandName = NSLocalizedString(
        "checkout-components-primer-brand",
        bundle: Bundle.primerResources,
        value: "Primer",
        comment: "Primer brand name"
    )

    static let secureCheckout = NSLocalizedString(
        "checkout-components-secure-checkout",
        bundle: Bundle.primerResources,
        value: "Secure Checkout",
        comment: "Secure checkout branding text"
    )

    // MARK: - Development Messages

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

    static func paymentMethodDisplayName(_ displayName: String) -> String {
        let format = NSLocalizedString(
            "checkout-components-payment-method-display",
            bundle: Bundle.primerResources,
            value: "Payment Method: %@",
            comment: "Payment method display format with method name"
        )
        return String(format: format, displayName)
    }

    // MARK: - 3DS Error Messages

    static let threeDSAuthenticationTimeout = NSLocalizedString(
        "checkout-components-3ds-timeout",
        bundle: Bundle.primerResources,
        value: "3D Secure authentication timed out. Please try again.",
        comment: "3DS authentication timeout error message"
    )

    static let threeDSAuthenticationCancelled = NSLocalizedString(
        "checkout-components-3ds-cancelled",
        bundle: Bundle.primerResources,
        value: "3D Secure authentication was cancelled.",
        comment: "3DS authentication cancelled error message"
    )

    static let threeDSNetworkError = NSLocalizedString(
        "checkout-components-3ds-network-error",
        bundle: Bundle.primerResources,
        value: "Network error during 3D Secure authentication.",
        comment: "3DS network error message"
    )

    static let threeDSConfigurationError = NSLocalizedString(
        "checkout-components-3ds-configuration-error",
        bundle: Bundle.primerResources,
        value: "3D Secure authentication configuration is missing.",
        comment: "3DS configuration error message"
    )

    static let threeDSNotAvailable = NSLocalizedString(
        "checkout-components-3ds-not-available",
        bundle: Bundle.primerResources,
        value: "3D Secure authentication is not available.",
        comment: "3DS not available error message"
    )

    static let threeDSInvalidData = NSLocalizedString(
        "checkout-components-3ds-invalid-data",
        bundle: Bundle.primerResources,
        value: "Invalid payment data for 3D Secure authentication.",
        comment: "3DS invalid data error message"
    )

    static let threeDSGenericError = NSLocalizedString(
        "checkout-components-3ds-generic-error",
        bundle: Bundle.primerResources,
        value: "3D Secure authentication failed.",
        comment: "3DS generic error message"
    )

    static let threeDSSessionExpired = NSLocalizedString(
        "checkout-components-3ds-session-expired",
        bundle: Bundle.primerResources,
        value: "Session expired during 3D Secure authentication.",
        comment: "3DS session expired error message"
    )

    // MARK: - 3DS Recovery Messages

    static let threeDSRetryMessage = NSLocalizedString(
        "checkout-components-3ds-retry",
        bundle: Bundle.primerResources,
        value: "Please try again or use a different payment method.",
        comment: "3DS retry recovery message"
    )

    static let threeDSCheckConnectionMessage = NSLocalizedString(
        "checkout-components-3ds-check-connection",
        bundle: Bundle.primerResources,
        value: "Please check your internet connection and try again.",
        comment: "3DS check connection recovery message"
    )

    static let threeDSContactSupportMessage = NSLocalizedString(
        "checkout-components-3ds-contact-support",
        bundle: Bundle.primerResources,
        value: "Please try again or contact support.",
        comment: "3DS contact support recovery message"
    )

    static let threeDSCompleteAuthMessage = NSLocalizedString(
        "checkout-components-3ds-complete-auth",
        bundle: Bundle.primerResources,
        value: "Please try again and complete the authentication process.",
        comment: "3DS complete authentication recovery message"
    )
}