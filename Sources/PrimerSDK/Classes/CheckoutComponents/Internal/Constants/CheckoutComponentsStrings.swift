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

    static let cardPaymentTitle = NSLocalizedString(
        "checkout-components-card-payment-title",
        bundle: Bundle.primerResources,
        value: "Card Payment",
        comment: "Card Payment screen title"
    )

    static let billingAddressTitle = NSLocalizedString(
        "checkout-components-billing-address-title",
        bundle: Bundle.primerResources,
        value: "Billing Address",
        comment: "Billing Address section title"
    )

    // MARK: - Buttons

    static let payButton = NSLocalizedString(
        "primer-card-form-pay",
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

    // MARK: - Error Messages

    static let somethingWentWrong = NSLocalizedString(
        "primer-error-screen",
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

    // MARK: - Android Parity: Form Validation Errors

    /// Form validation error with field name placeholder (matches Android pattern)
    static let formErrorRequired = NSLocalizedString(
        "checkout-components-form-error-required",
        bundle: Bundle.primerResources,
        value: "%@ is required",
        comment: "Field required validation error"
    )

    /// Form validation error for invalid field values
    static let formErrorInvalid = NSLocalizedString(
        "checkout-components-form-error-invalid",
        bundle: Bundle.primerResources,
        value: "%@ is invalid",
        comment: "Field invalid validation error"
    )

    /// Card type not supported error
    static let formErrorCardTypeNotSupported = NSLocalizedString(
        "checkout-components-form-error-card-type-not-supported",
        bundle: Bundle.primerResources,
        value: "Unsupported card type",
        comment: "Card type not supported error"
    )

    /// Card holder name length validation error
    static let formErrorCardHolderNameLength = NSLocalizedString(
        "checkout-components-form-error-card-holder-name-length",
        bundle: Bundle.primerResources,
        value: "Name must have between 2 and 45 characters",
        comment: "Card holder name length validation error"
    )

    /// Card expired validation error
    static let formErrorCardExpired = NSLocalizedString(
        "checkout-components-form-error-card-expired",
        bundle: Bundle.primerResources,
        value: "Card has expired",
        comment: "Card expired validation error"
    )

    // MARK: - Android Parity: Field Names for Error Messages

    /// Field names used in error message formatting
    static let cardNumberFieldName = NSLocalizedString(
        "checkout-components-card-number-field",
        bundle: Bundle.primerResources,
        value: "Card number",
        comment: "Card number field name for error messages"
    )

    static let cvvFieldName = NSLocalizedString(
        "checkout-components-cvv-field",
        bundle: Bundle.primerResources,
        value: "CVV",
        comment: "CVV field name for error messages"
    )

    static let expiryDateFieldName = NSLocalizedString(
        "checkout-components-expiry-date-field",
        bundle: Bundle.primerResources,
        value: "Expiry date",
        comment: "Expiry date field name for error messages"
    )

    static let cardholderNameFieldName = NSLocalizedString(
        "checkout-components-cardholder-name-field",
        bundle: Bundle.primerResources,
        value: "Cardholder name",
        comment: "Cardholder name field name for error messages"
    )

    static let firstNameFieldName = NSLocalizedString(
        "checkout-components-first-name-field",
        bundle: Bundle.primerResources,
        value: "First name",
        comment: "First name field name for error messages"
    )

    static let lastNameFieldName = NSLocalizedString(
        "checkout-components-last-name-field",
        bundle: Bundle.primerResources,
        value: "Last name",
        comment: "Last name field name for error messages"
    )

    static let emailFieldName = NSLocalizedString(
        "checkout-components-email-field",
        bundle: Bundle.primerResources,
        value: "Email",
        comment: "Email field name for error messages"
    )

    static let phoneNumberFieldName = NSLocalizedString(
        "checkout-components-phone-number-field",
        bundle: Bundle.primerResources,
        value: "Phone number",
        comment: "Phone number field name for error messages"
    )

    static let countryFieldName = NSLocalizedString(
        "checkout-components-country-field",
        bundle: Bundle.primerResources,
        value: "Country",
        comment: "Country field name for error messages"
    )

    static let addressLine1FieldName = NSLocalizedString(
        "checkout-components-address-line-1-field",
        bundle: Bundle.primerResources,
        value: "Address line 1",
        comment: "Address line 1 field name for error messages"
    )

    static let addressLine2FieldName = NSLocalizedString(
        "checkout-components-address-line-2-field",
        bundle: Bundle.primerResources,
        value: "Address line 2",
        comment: "Address line 2 field name for error messages"
    )

    static let cityFieldName = NSLocalizedString(
        "checkout-components-city-field",
        bundle: Bundle.primerResources,
        value: "City",
        comment: "City field name for error messages"
    )

    static let stateFieldName = NSLocalizedString(
        "checkout-components-state-field",
        bundle: Bundle.primerResources,
        value: "State",
        comment: "State field name for error messages"
    )

    static let postalCodeFieldName = NSLocalizedString(
        "checkout-components-postal-code-field",
        bundle: Bundle.primerResources,
        value: "Postal code",
        comment: "Postal code field name for error messages"
    )

    static let otpCodeFieldName = NSLocalizedString(
        "checkout-components-otp-code-field",
        bundle: Bundle.primerResources,
        value: "OTP code",
        comment: "OTP code field name for error messages"
    )

    // MARK: - Android Parity: Result Screen Messages

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

    // MARK: - Empty State Messages

    static let noPaymentMethodsAvailable = NSLocalizedString(
        "checkout-components-no-payment-methods",
        bundle: Bundle.primerResources,
        value: "No payment methods available",
        comment: "Empty state message when no payment methods are available"
    )

    // MARK: - Form Labels

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
        "countryCodeLabel",
        bundle: Bundle.primerResources,
        value: "Country",
        comment: "Country field label"
    )

    // MARK: - Placeholders

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

    // MARK: - Address Labels

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

    // MARK: - Country Selector

    static let countrySelectorPlaceholder = NSLocalizedString(
        "checkout-components-country-selector-placeholder",
        bundle: Bundle.primerResources,
        value: "Country Selector",
        comment: "Country selector placeholder"
    )

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

    // MARK: - Success Screen Details

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
}
