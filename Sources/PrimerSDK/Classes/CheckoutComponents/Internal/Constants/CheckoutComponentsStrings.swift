//
//  CheckoutComponentsStrings.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length

import Foundation

/// Centralized strings for CheckoutComponents to make localization easier
/// Keys use underscore_case format to match Android SDK for cross-platform consistency
enum CheckoutComponentsStrings {
  /// The localization table name for CheckoutComponents strings
  private static let tableName = "CheckoutComponentsStrings"

  // MARK: - Screen Titles

  static let checkoutTitle = NSLocalizedString(
    "primer_checkout_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "Checkout",
    comment: "Main checkout screen title"
  )

  static let cardPaymentTitle = NSLocalizedString(
    "primer_card_form_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "Pay with card",
    comment: "Card Payment screen title"
  )

  static let billingAddressTitle = NSLocalizedString(
    "primer_card_form_billing_address_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "Billing address",
    comment: "Billing address section title - Card Form"
  )

  // MARK: - Buttons

  static let payButton = NSLocalizedString(
    "primer_common_button_pay",
    tableName: tableName,
    bundle: .primerResources,
    value: "Pay",
    comment: "Pay button text"
  )

  static let addCardButton = NSLocalizedString(
    "primer_card_form_add_card",
    tableName: tableName,
    bundle: .primerResources,
    value: "Add card",
    comment: "Add card button text when storing a new card"
  )

  static let cancelButton = NSLocalizedString(
    "primer_common_button_cancel",
    tableName: tableName,
    bundle: .primerResources,
    value: "Cancel",
    comment: "Cancel button text"
  )

  static let retryButton = NSLocalizedString(
    "primer_common_button_retry",
    tableName: tableName,
    bundle: .primerResources,
    value: "Retry",
    comment: "Retry button text"
  )

  static let chooseOtherPaymentMethod = NSLocalizedString(
    "primer_checkout_error_button_other_methods",
    tableName: tableName,
    bundle: .primerResources,
    value: "Choose other payment method",
    comment: "Button text to select a different payment method after error"
  )

  static let backButton = NSLocalizedString(
    "primer_common_back",
    tableName: tableName,
    bundle: .primerResources,
    value: "Back",
    comment: "Back navigation button text"
  )

  // MARK: - Payment Method Selection

  static let choosePaymentMethod = NSLocalizedString(
    "primer_payment_selection_header",
    tableName: tableName,
    bundle: .primerResources,
    value: "Choose payment method",
    comment: "Payment method selection screen subtitle"
  )

  static let additionalFeeMayApply = NSLocalizedString(
    "primer_payment_selection_surcharge_may_apply",
    tableName: tableName,
    bundle: .primerResources,
    value: "Additional fee may apply",
    comment: "Message shown when a surcharge might be applied"
  )

  static func paymentAmountTitle(_ amount: String) -> String {
    let format = NSLocalizedString(
      "primer_common_button_pay_amount",
      tableName: tableName,
      bundle: .primerResources,
      value: "Pay %@",
      comment: "Payment amount title with formatted amount"
    )
    return String(format: format, amount)
  }

  // MARK: - Card Form Labels

  static let cardNumberLabel = NSLocalizedString(
    "primer_card_form_label_number",
    tableName: tableName,
    bundle: .primerResources,
    value: "Card Number",
    comment: "Card number field label"
  )

  static let expiryDateLabel = NSLocalizedString(
    "primer_card_form_label_expiry",
    tableName: tableName,
    bundle: .primerResources,
    value: "Expiry Date",
    comment: "Expiry date field label"
  )

  static let cvvLabel = NSLocalizedString(
    "primer_card_form_label_cvv",
    tableName: tableName,
    bundle: .primerResources,
    value: "CVV",
    comment: "CVV field label"
  )

  static let cardholderNameLabel = NSLocalizedString(
    "primer_card_form_label_name",
    tableName: tableName,
    bundle: .primerResources,
    value: "Name on card",
    comment: "Cardholder name field label"
  )

  // MARK: - Card Form Placeholders

  static let cardNumberPlaceholder = NSLocalizedString(
    "primer_card_form_placeholder_number",
    tableName: tableName,
    bundle: .primerResources,
    value: "1234 1234 1234 1234",
    comment: "Card number input placeholder"
  )

  static let expiryDatePlaceholder = NSLocalizedString(
    "primer_card_form_placeholder_expiry",
    tableName: tableName,
    bundle: .primerResources,
    value: "MM/YY",
    comment: "Expiry date input placeholder"
  )

  static let cvvPlaceholder = NSLocalizedString(
    "primer_card_form_placeholder_cvv",
    tableName: tableName,
    bundle: .primerResources,
    value: "CVV",
    comment: "CVV input placeholder"
  )

  static let cardholderNamePlaceholder = NSLocalizedString(
    "primer_card_form_placeholder_name",
    tableName: tableName,
    bundle: .primerResources,
    value: "Full name",
    comment: "Cardholder name input placeholder"
  )

  // MARK: - Billing Address Labels

  static let firstNameLabel = NSLocalizedString(
    "primer_card_form_label_first_name",
    tableName: tableName,
    bundle: .primerResources,
    value: "First Name",
    comment: "First name field label"
  )

  static let lastNameLabel = NSLocalizedString(
    "primer_card_form_label_last_name",
    tableName: tableName,
    bundle: .primerResources,
    value: "Last Name",
    comment: "Last name field label"
  )

  static let countryLabel = NSLocalizedString(
    "primer_card_form_label_country",
    tableName: tableName,
    bundle: .primerResources,
    value: "Country",
    comment: "Country field label"
  )

  static let addressLine1Label = NSLocalizedString(
    "primer_card_form_label_address1",
    tableName: tableName,
    bundle: .primerResources,
    value: "Address Line 1",
    comment: "Address line 1 label"
  )

  static let addressLine2Label = NSLocalizedString(
    "primer_card_form_label_address2",
    tableName: tableName,
    bundle: .primerResources,
    value: "Address Line 2",
    comment: "Address line 2 label"
  )

  static let cityLabel = NSLocalizedString(
    "primer_card_form_label_city",
    tableName: tableName,
    bundle: .primerResources,
    value: "City",
    comment: "City label"
  )

  static let stateLabel = NSLocalizedString(
    "primer_card_form_label_state",
    tableName: tableName,
    bundle: .primerResources,
    value: "State",
    comment: "State label"
  )

  static let postalCodeLabel = NSLocalizedString(
    "primer_card_form_label_postal",
    tableName: tableName,
    bundle: .primerResources,
    value: "Postal Code",
    comment: "Postal code label"
  )

  static let otpLabel = NSLocalizedString(
    "primer_card_form_label_otp",
    tableName: tableName,
    bundle: .primerResources,
    value: "OTP Code",
    comment: "OTP code field label"
  )

  static let retailLabel = NSLocalizedString(
    "primer_card_form_label_retail",
    tableName: tableName,
    bundle: .primerResources,
    value: "Retail Outlet",
    comment: "Retail outlet field label"
  )

  // MARK: - Billing Address Placeholders

  static let firstNamePlaceholder = NSLocalizedString(
    "primer_card_form_placeholder_first_name",
    tableName: tableName,
    bundle: .primerResources,
    value: "John",
    comment: "First name placeholder"
  )

  static let lastNamePlaceholder = NSLocalizedString(
    "primer_card_form_placeholder_last_name",
    tableName: tableName,
    bundle: .primerResources,
    value: "Doe",
    comment: "Last name placeholder"
  )

  static let selectCountryPlaceholder = NSLocalizedString(
    "primer_card_form_placeholder_country_code",
    tableName: tableName,
    bundle: .primerResources,
    value: "Select country",
    comment: "Select country placeholder"
  )

  static let addressLine1Placeholder = NSLocalizedString(
    "primer_card_form_placeholder_address1",
    tableName: tableName,
    bundle: .primerResources,
    value: "123 Main Street",
    comment: "Address line 1 placeholder"
  )

  static let addressLine2Placeholder = NSLocalizedString(
    "primer_card_form_placeholder_address2",
    tableName: tableName,
    bundle: .primerResources,
    value: "Apt 4B",
    comment: "Address line 2 placeholder"
  )

  static let cityPlaceholder = NSLocalizedString(
    "primer_card_form_placeholder_city",
    tableName: tableName,
    bundle: .primerResources,
    value: "New York",
    comment: "City placeholder"
  )

  static let statePlaceholder = NSLocalizedString(
    "primer_card_form_placeholder_state",
    tableName: tableName,
    bundle: .primerResources,
    value: "NY",
    comment: "State placeholder"
  )

  static let postalCodePlaceholder = NSLocalizedString(
    "primer_card_form_placeholder_postal",
    tableName: tableName,
    bundle: .primerResources,
    value: "12345",
    comment: "Postal code placeholder"
  )

  // MARK: - Specialized Placeholders

  static let searchCountriesPlaceholder = NSLocalizedString(
    "primer_country_placeholder_search",
    tableName: tableName,
    bundle: .primerResources,
    value: "Search",
    comment: "Search countries input placeholder"
  )

  // MARK: - Validation Errors - General

  static let enterValidCardNumber = NSLocalizedString(
    "primer_card_form_error_number_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Invalid card number",
    comment: "Card number validation error message"
  )

  static let enterValidExpiryDate = NSLocalizedString(
    "primer_card_form_error_expiry_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Invalid date",
    comment: "Expiry date validation error message"
  )

  static let enterValidCVV = NSLocalizedString(
    "primer_card_form_error_cvv_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Invalid CVV",
    comment: "CVV validation error message"
  )

  static let enterValidCardholderName = NSLocalizedString(
    "primer_card_form_error_name_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Invalid Cardholder name",
    comment: "Cardholder name validation error message"
  )

  // MARK: - Validation Errors - Form Specific

  static let formErrorCardTypeNotSupported = NSLocalizedString(
    "primer_card_form_error_card_type_unsupported",
    tableName: tableName,
    bundle: .primerResources,
    value: "Unsupported card type",
    comment: "Card type not supported error"
  )

  static let formErrorCardHolderNameLength = NSLocalizedString(
    "primer_card_form_error_name_length",
    tableName: tableName,
    bundle: .primerResources,
    value: "Name must have between 2 and 45 characters",
    comment: "Card holder name length validation error"
  )

  // MARK: - Validation Errors - Required Fields

  static let firstNameErrorRequired = NSLocalizedString(
    "primer_card_form_error_first_name_required",
    tableName: tableName,
    bundle: .primerResources,
    value: "First Name is required",
    comment: "First name required validation error"
  )

  static let lastNameErrorRequired = NSLocalizedString(
    "primer_card_form_error_last_name_required",
    tableName: tableName,
    bundle: .primerResources,
    value: "Last Name is required",
    comment: "Last name required validation error"
  )

  static let countryCodeErrorRequired = NSLocalizedString(
    "primer_card_form_error_country_required",
    tableName: tableName,
    bundle: .primerResources,
    value: "Country is required",
    comment: "Country required validation error"
  )

  static let addressLine1ErrorRequired = NSLocalizedString(
    "primer_card_form_error_address1_required",
    tableName: tableName,
    bundle: .primerResources,
    value: "Address line 1 is required",
    comment: "Address line 1 required validation error"
  )

  static let addressLine2ErrorRequired = NSLocalizedString(
    "primer_card_form_error_address2_required",
    tableName: tableName,
    bundle: .primerResources,
    value: "Address line 2 is required",
    comment: "Address line 2 required validation error"
  )

  static let cityErrorRequired = NSLocalizedString(
    "primer_card_form_error_city_required",
    tableName: tableName,
    bundle: .primerResources,
    value: "City is required",
    comment: "City required validation error"
  )

  static let stateErrorRequired = NSLocalizedString(
    "primer_card_form_error_state_required",
    tableName: tableName,
    bundle: .primerResources,
    value: "State, Region or County is required",
    comment: "State required validation error"
  )

  static let postalCodeErrorRequired = NSLocalizedString(
    "primer_card_form_error_postal_required",
    tableName: tableName,
    bundle: .primerResources,
    value: "Postal code is required",
    comment: "Postal code required validation error"
  )

  // MARK: - Validation Errors - Invalid Fields

  static let firstNameErrorInvalid = NSLocalizedString(
    "primer_card_form_error_first_name_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Invalid First Name",
    comment: "First name invalid validation error"
  )

  static let lastNameErrorInvalid = NSLocalizedString(
    "primer_card_form_error_last_name_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Invalid Last Name",
    comment: "Last name invalid validation error"
  )

  static let countryCodeErrorInvalid = NSLocalizedString(
    "primer_card_form_error_country_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Invalid Country",
    comment: "Country invalid validation error"
  )

  static let addressLine1ErrorInvalid = NSLocalizedString(
    "primer_card_form_error_address1_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Invalid Address Line 1",
    comment: "Address line 1 invalid validation error"
  )

  static let addressLine2ErrorInvalid = NSLocalizedString(
    "primer_card_form_error_address2_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Invalid Address Line 2",
    comment: "Address line 2 invalid validation error"
  )

  static let cityErrorInvalid = NSLocalizedString(
    "primer_card_form_error_city_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Invalid city",
    comment: "City invalid validation error"
  )

  static let stateErrorInvalid = NSLocalizedString(
    "primer_card_form_error_state_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Invalid State, Region or County",
    comment: "State invalid validation error"
  )

  static let postalCodeErrorInvalid = NSLocalizedString(
    "primer_card_form_error_postal_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Invalid postal code",
    comment: "Postal code invalid validation error"
  )

  // MARK: - System Messages

  static let somethingWentWrong = NSLocalizedString(
    "primer_common_error_generic",
    tableName: tableName,
    bundle: .primerResources,
    value: "An unknown error occurred.",
    comment: "Generic error message"
  )

  // MARK: - Empty State Messages

  static let noAdditionalFee = NSLocalizedString(
    "primer_payment_selection_surcharge_none",
    tableName: tableName,
    bundle: .primerResources,
    value: "No additional fee",
    comment: "Message shown when no surcharge applies"
  )

  // MARK: - Success Screen Details

  static let paymentSuccessful = NSLocalizedString(
    "primer_checkout_success_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "Payment successful",
    comment: "Success screen title"
  )

  static let paymentFailed = NSLocalizedString(
    "primer_checkout_error_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "Payment failed",
    comment: "Error screen title for payment failures"
  )

  static func paymentMethodDisplayName(_ displayName: String) -> String {
    let format = NSLocalizedString(
      "primer_common_button_pay_amount",
      tableName: tableName,
      bundle: .primerResources,
      value: "Pay %@",
      comment: "Payment method display format with method name"
    )
    return String(format: format, displayName)
  }

  // MARK: - CheckoutComponents-Specific Strings

  static let selectNetworkTitle = NSLocalizedString(
    "primer_card_form_network_selector_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "Select Network",
    comment: "Card network selection title"
  )

  static let selectCountryTitle = NSLocalizedString(
    "primer_country_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "Select Country",
    comment: "Country selection screen title"
  )

  static let expiryDateAlternativePlaceholder = NSLocalizedString(
    "primer_card_form_placeholder_expiry_alt",
    tableName: tableName,
    bundle: .primerResources,
    value: "12/25",
    comment: "Alternative expiry date input placeholder"
  )

  static let cvvAmexPlaceholder = NSLocalizedString(
    "primer_card_form_placeholder_cvv_amex",
    tableName: tableName,
    bundle: .primerResources,
    value: "1234",
    comment: "CVV input placeholder for American Express"
  )

  static let cvvStandardPlaceholder = NSLocalizedString(
    "primer_card_form_placeholder_cvv",
    tableName: tableName,
    bundle: .primerResources,
    value: "123",
    comment: "CVV input placeholder for standard cards"
  )

  static let fullNamePlaceholder = NSLocalizedString(
    "primer_card_form_placeholder_name",
    tableName: tableName,
    bundle: .primerResources,
    value: "Full name",
    comment: "Full name input placeholder"
  )

  static let emailLabel = NSLocalizedString(
    "primer_card_form_label_email",
    tableName: tableName,
    bundle: .primerResources,
    value: "Email",
    comment: "Email field label"
  )

  static let phoneNumberLabel = NSLocalizedString(
    "primer_card_form_label_phone",
    tableName: tableName,
    bundle: .primerResources,
    value: "Phone Number",
    comment: "Phone number field label"
  )

  static let emailPlaceholder = NSLocalizedString(
    "primer_card_form_placeholder_email",
    tableName: tableName,
    bundle: .primerResources,
    value: "john.doe@example.com",
    comment: "Email placeholder"
  )

  static let phoneNumberPlaceholder = NSLocalizedString(
    "primer_card_form_placeholder_phone",
    tableName: tableName,
    bundle: .primerResources,
    value: "+1 (555) 123–4567",
    comment: "Phone number placeholder"
  )

  static let countrySelectorPlaceholder = NSLocalizedString(
    "primer_country_selector_placeholder",
    tableName: tableName,
    bundle: .primerResources,
    value: "Country Selector",
    comment: "Country selector placeholder"
  )

  static let retailOutletPlaceholder = NSLocalizedString(
    "primer_card_form_placeholder_retail",
    tableName: tableName,
    bundle: .primerResources,
    value: "Select outlet",
    comment: "Retail outlet input placeholder"
  )

  static let otpCodePlaceholder = NSLocalizedString(
    "primer_card_form_label_otp",
    tableName: tableName,
    bundle: .primerResources,
    value: "OTP Code",
    comment: "OTP code input placeholder"
  )

  static let otpCodeNumericPlaceholder = NSLocalizedString(
    "primer_card_form_placeholder_otp",
    tableName: tableName,
    bundle: .primerResources,
    value: "123456",
    comment: "Numeric OTP code input placeholder"
  )

  static let enterValidPhoneNumber = NSLocalizedString(
    "primer_card_form_error_phone_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Enter a valid phone number",
    comment: "Phone number validation error message"
  )

  static let emailErrorRequired = NSLocalizedString(
    "primer_card_form_error_email_required",
    tableName: tableName,
    bundle: .primerResources,
    value: "Email is required",
    comment: "Email required validation error"
  )

  static let emailErrorInvalid = NSLocalizedString(
    "primer_card_form_error_email_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Invalid email",
    comment: "Email invalid validation error"
  )

  static let formErrorCardExpired = NSLocalizedString(
    "primer_card_form_error_card_expired",
    tableName: tableName,
    bundle: .primerResources,
    value: "Card has expired",
    comment: "Card expired validation error"
  )

  static let loadingSecureCheckout = NSLocalizedString(
    "primer_checkout_splash_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "Loading your secure checkout",
    comment: "Main loading message for secure checkout"
  )

  static let loadingWontTakeLong = NSLocalizedString(
    "primer_checkout_splash_subtitle",
    tableName: tableName,
    bundle: .primerResources,
    value: "This won't take long",
    comment: "Secondary loading message indicating quick loading time"
  )

  /// Simple "Loading" text shown in the default loading screen during payment processing.
  /// Matches Android SDK naming convention.
  static let loading = NSLocalizedString(
    "primer_checkout_loading_indicator",
    tableName: tableName,
    bundle: .primerResources,
    value: "Loading",
    comment: "Simple loading text shown during payment processing"
  )

  static let processingPayment = NSLocalizedString(
    "primer_checkout_processing_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "Processing your payment",
    comment: "Main message shown while payment is being processed"
  )

  static let processingPleaseWait = NSLocalizedString(
    "primer_checkout_processing_subtitle",
    tableName: tableName,
    bundle: .primerResources,
    value: "Please wait...",
    comment: "Secondary message shown while payment is being processed"
  )

  static let dismissingMessage = NSLocalizedString(
    "primer_checkout_dismissing",
    tableName: tableName,
    bundle: .primerResources,
    value: "Dismissing...",
    comment: "Message shown while dismissing checkout"
  )

  static let unexpectedError = NSLocalizedString(
    "primer_common_error_unexpected",
    tableName: tableName,
    bundle: .primerResources,
    value: "An unexpected error occurred.",
    comment: "Unexpected error message"
  )

  static let paymentSystemError = NSLocalizedString(
    "primer_checkout_system_error_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "Payment System Error",
    comment: "Error title when payment system initialization fails"
  )

  static let checkoutScopeNotAvailable = NSLocalizedString(
    "primer_checkout_scope_unavailable",
    tableName: tableName,
    bundle: .primerResources,
    value: "Checkout scope not available",
    comment: "Error when checkout scope is not accessible"
  )

  static let noPaymentMethodsAvailable = NSLocalizedString(
    "primer_payment_selection_empty",
    tableName: tableName,
    bundle: .primerResources,
    value: "No payment methods available",
    comment: "Empty state message when no payment methods are available"
  )

  // MARK: - Saved Payment Methods Section

  static let savedPaymentMethods = NSLocalizedString(
    "primer_vault_section_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "Saved payment methods",
    comment: "Section title for saved/vaulted payment methods"
  )

  static let showAll = NSLocalizedString(
    "primer_vault_button_show_all",
    tableName: tableName,
    bundle: .primerResources,
    value: "Show all",
    comment: "Button text to show all saved payment methods"
  )

  static let showOtherWaysToPay = NSLocalizedString(
    "primer_vault_selected_button_other",
    tableName: tableName,
    bundle: .primerResources,
    value: "Show other ways to pay",
    comment: "Button text to expand and show all available payment methods"
  )

  static let a11yShowOtherWaysToPay = NSLocalizedString(
    "accessibility_payment_selection_show_other_ways_to_pay",
    tableName: tableName,
    bundle: .primerResources,
    value: "Show other ways to pay",
    comment: "VoiceOver label for button to expand payment methods"
  )

  static let allSavedPaymentMethods = NSLocalizedString(
    "primer_vault_manage_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "All saved payment methods",
    comment: "Title for the vaulted payment methods list screen"
  )

  static let editButton = NSLocalizedString(
    "primer_vault_manage_button_edit",
    tableName: tableName,
    bundle: .primerResources,
    value: "Edit",
    comment: "Edit button placeholder text"
  )

  static let doneButton = NSLocalizedString(
    "primer_vault_manage_button_done",
    tableName: tableName,
    bundle: .primerResources,
    value: "Done",
    comment: "Done button text for finishing edit mode"
  )

  static let deleteButton = NSLocalizedString(
    "primer_vault_delete_button_confirm",
    tableName: tableName,
    bundle: .primerResources,
    value: "Delete",
    comment: "Delete button text for confirming deletion"
  )

  static let deletePaymentMethodConfirmation = NSLocalizedString(
    "primer_vault_delete_message",
    tableName: tableName,
    bundle: .primerResources,
    value: "Are you sure you want to delete this payment method?",
    comment: "Confirmation message shown when deleting a saved payment method"
  )

  static let cardHolder = NSLocalizedString(
    "primer_vault_default_cardholder",
    tableName: tableName,
    bundle: .primerResources,
    value: "Cardholder",
    comment: "Default placeholder text when cardholder name is not available"
  )

  static func expiresDate(month: String, year: String) -> String {
    let format = NSLocalizedString(
      "primer_vault_format_expires",
      tableName: tableName,
      bundle: .primerResources,
      value: "Expires %1$@/%2$@",
      comment:
        "Expiry date text for saved card. First parameter is month, second is year (e.g., '12/26')"
    )
    return String(format: format, month, year)
  }

  // MARK: - Vaulted Payment Method Brand Names

  static let paypalBrandName = NSLocalizedString(
    "primer_vault_default_paypal",
    tableName: tableName,
    bundle: .primerResources,
    value: "PayPal account",
    comment: "PayPal brand name for vaulted payment methods"
  )

  static let achSuffix = NSLocalizedString(
    "primer_vault_default_bank",
    tableName: tableName,
    bundle: .primerResources,
    value: "Bank account",
    comment: "Default text for vaulted bank account payment methods"
  )

  static let maskedCardNumber = NSLocalizedString(
    "primer_vault_format_masked",
    tableName: tableName,
    bundle: .primerResources,
    value: "•••• %@",
    comment: "Masked card number format. Parameter is the last 4 digits."
  )

  static func maskedCardNumberFormatted(_ last4: String) -> String {
    let format = NSLocalizedString(
      "primer_vault_format_masked",
      tableName: tableName,
      bundle: .primerResources,
      value: "•••• %@",
      comment: "Masked card number format. Parameter is the last 4 digits."
    )
    return String(format: format, last4)
  }

  // MARK: - Vaulted Card CVV Recapture

  static let cvvPlaceholderDigit = NSLocalizedString(
    "primer_vault_cvv_placeholder_digit",
    tableName: tableName,
    bundle: .primerResources,
    value: "0",
    comment: "Single digit used to build CVV placeholder (e.g., '000' for 3-digit CVV)"
  )

  static let cvvRecaptureInstruction = NSLocalizedString(
    "primer_vault_cvv_hint",
    tableName: tableName,
    bundle: .primerResources,
    value: "Input the card CVV for a secure payment.",
    comment: "Instruction text shown when CVV is required for vaulted card payment"
  )

  static let cvvInvalidError = NSLocalizedString(
    "primer_vault_cvv_error_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Please enter a valid CVV.",
    comment: "Error message when CVV is invalid"
  )

  static let a11yVaultCVVLabel = NSLocalizedString(
    "accessibility_vault_cvv_label",
    tableName: tableName,
    bundle: .primerResources,
    value: "CVV input field",
    comment: "VoiceOver label for CVV input field in vault payment flow"
  )

  static func a11yVaultCVVHint(length: Int) -> String {
    let format = NSLocalizedString(
      "accessibility_vault_cvv_hint",
      tableName: tableName,
      bundle: .primerResources,
      value: "Enter %d digit security code",
      comment:
        "VoiceOver hint for CVV field with expected length. Parameter is the number of digits (3 or 4)"
    )
    return String(format: format, length)
  }

  static let noCountriesFound = NSLocalizedString(
    "primer_country_no_results",
    tableName: tableName,
    bundle: .primerResources,
    value: "No countries found",
    comment: "Message when country search returns no results"
  )

  static let autoDismissMessage = NSLocalizedString(
    "primer_checkout_auto_dismiss_message",
    tableName: tableName,
    bundle: .primerResources,
    value: "This screen will close automatically in 3 seconds",
    comment: "Auto-dismiss message on success and error screens"
  )

  static let redirectConfirmationMessage = NSLocalizedString(
    "primer_checkout_success_subtitle",
    tableName: tableName,
    bundle: .primerResources,
    value: "You'll be redirected to the order confirmation page soon.",
    comment: "Message shown on success screen about upcoming redirect"
  )

  static let implementationComingSoon = NSLocalizedString(
    "primer_misc_coming_soon",
    tableName: tableName,
    bundle: .primerResources,
    value: "Implementation coming soon",
    comment: "Placeholder message for features under development"
  )

  static let retailOutletNotImplemented = NSLocalizedString(
    "primer_card_form_retail_not_implemented",
    tableName: tableName,
    bundle: .primerResources,
    value: "Retail outlet selection not yet implemented",
    comment: "Message for retail outlet feature not yet available"
  )

  // MARK: - Vaulted Payment Method Accessibility

  static func a11yVaultedCard(network: String, last4: String, expiry: String, name: String?)
    -> String
  {
    if let name {
      let format = NSLocalizedString(
        "accessibility_vaulted_card_full",
        tableName: tableName,
        bundle: .primerResources,
        value: "%@ card ending in %@, expires %@, %@",
        comment:
          "Full VoiceOver label for vaulted card with name. Parameters: network, last4, expiry, name"
      )
      return String(format: format, network, last4, expiry, name)
    } else {
      let format = NSLocalizedString(
        "accessibility_vaulted_card_no_name",
        tableName: tableName,
        bundle: .primerResources,
        value: "%@ card ending in %@, expires %@",
        comment: "VoiceOver label for vaulted card without name. Parameters: network, last4, expiry"
      )
      return String(format: format, network, last4, expiry)
    }
  }

  static func a11yVaultedPayPal(email: String?, name: String?) -> String {
    if let email {
      let format = NSLocalizedString(
        "accessibility_vaulted_paypal_email",
        tableName: tableName,
        bundle: .primerResources,
        value: "PayPal, %@",
        comment: "VoiceOver label for vaulted PayPal with email"
      )
      return String(format: format, email)
    } else {
      return NSLocalizedString(
        "accessibility_vaulted_paypal",
        tableName: tableName,
        bundle: .primerResources,
        value: "PayPal",
        comment: "VoiceOver label for vaulted PayPal without email"
      )
    }
  }

  static func a11yVaultedKlarna(email: String?) -> String {
    if let email {
      let format = NSLocalizedString(
        "accessibility_vaulted_klarna_email",
        tableName: tableName,
        bundle: .primerResources,
        value: "Klarna, %@",
        comment: "VoiceOver label for vaulted Klarna with email"
      )
      return String(format: format, email)
    } else {
      return NSLocalizedString(
        "accessibility_vaulted_klarna",
        tableName: tableName,
        bundle: .primerResources,
        value: "Klarna",
        comment: "VoiceOver label for vaulted Klarna without email"
      )
    }
  }

  static func a11yVaultedACH(bankName: String, last4: String?) -> String {
    if let last4 {
      let format = NSLocalizedString(
        "accessibility_vaulted_ach_full",
        tableName: tableName,
        bundle: .primerResources,
        value: "%@ bank account ending in %@",
        comment: "VoiceOver label for vaulted ACH with last4. Parameters: bank name, last4"
      )
      return String(format: format, bankName, last4)
    } else {
      let format = NSLocalizedString(
        "accessibility_vaulted_ach",
        tableName: tableName,
        bundle: .primerResources,
        value: "%@ bank account",
        comment: "VoiceOver label for vaulted ACH without last4. Parameter: bank name"
      )
      return String(format: format, bankName)
    }
  }

  // MARK: - PayPal Strings

  static let payPalTitle = NSLocalizedString(
    "primer_paypal_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "PayPal",
    comment: "PayPal payment screen title"
  )

  static let payPalContinueButton = NSLocalizedString(
    "primer_paypal_button_continue",
    tableName: tableName,
    bundle: .primerResources,
    value: "Continue with PayPal",
    comment: "PayPal continue button text"
  )

  static let payPalRedirectDescription = NSLocalizedString(
    "primer_paypal_redirect_description",
    tableName: tableName,
    bundle: .primerResources,
    value: "You will be redirected to PayPal to complete your payment securely.",
    comment: "PayPal redirect description text"
  )

  // MARK: - Klarna Strings

  static let klarnaBrandName = NSLocalizedString(
    "primer_vault_default_klarna",
    tableName: tableName,
    bundle: .primerResources,
    value: "Klarna",
    comment: "Klarna brand name"
  )

  static let klarnaAuthorizeButton = NSLocalizedString(
    "primer_klarna_button_authorize",
    tableName: tableName,
    bundle: .primerResources,
    value: "Continue",
    comment: "Klarna authorize button text"
  )

  static let klarnaFinalizeButton = NSLocalizedString(
    "primer_klarna_button_finalize",
    tableName: tableName,
    bundle: .primerResources,
    value: "Pay",
    comment: "Klarna finalize button text"
  )

  static let klarnaSelectCategoryDescription = NSLocalizedString(
    "primer_klarna_select_category_description",
    tableName: tableName,
    bundle: .primerResources,
    value: "Choose how you'd like to pay",
    comment: "Klarna category selection hint text"
  )

  static let klarnaLoadingTitle = NSLocalizedString(
    "primer_klarna_loading_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "Loading",
    comment: "Klarna loading spinner title"
  )

  static let klarnaLoadingSubtitle = NSLocalizedString(
    "primer_klarna_loading_subtitle",
    tableName: tableName,
    bundle: .primerResources,
    value: "This may take a few seconds.",
    comment: "Klarna loading subtitle text"
  )

  // MARK: Klarna Accessibility Strings

  static func a11yKlarnaCategory(_ categoryName: String) -> String {
    let format = NSLocalizedString(
      "accessibility_klarna_category",
      tableName: tableName,
      bundle: .primerResources,
      value: "%@ payment option",
      comment: "VoiceOver label for Klarna payment category. Parameter is category name."
    )
    return String(format: format, categoryName)
  }

  static func a11yKlarnaCategorySelected(_ categoryName: String) -> String {
    let format = NSLocalizedString(
      "accessibility_klarna_category_selected",
      tableName: tableName,
      bundle: .primerResources,
      value: "%@ payment option, selected",
      comment: "VoiceOver label for selected Klarna payment category. Parameter is category name."
    )
    return String(format: format, categoryName)
  }

  static let a11yKlarnaPaymentView = NSLocalizedString(
    "accessibility_klarna_payment_view",
    tableName: tableName,
    bundle: .primerResources,
    value: "Klarna payment form",
    comment: "VoiceOver label for Klarna SDK payment view"
  )

  static let a11yKlarnaAuthorizeHint = NSLocalizedString(
    "accessibility_klarna_authorize_hint",
    tableName: tableName,
    bundle: .primerResources,
    value: "Double tap to continue with Klarna",
    comment: "VoiceOver hint for Klarna authorize button"
  )

  static let a11yKlarnaFinalizeHint = NSLocalizedString(
    "accessibility_klarna_finalize_hint",
    tableName: tableName,
    bundle: .primerResources,
    value: "Double tap to complete payment",
    comment: "VoiceOver hint for Klarna finalize button"
  )

  // MARK: - Form Redirect Strings (BLIK, MBWay)

  static let blikOtpLabel = NSLocalizedString(
    "primer_form_redirect_blik_otp_label",
    tableName: tableName,
    bundle: .primerResources,
    value: "6 digit code",
    comment: "BLIK OTP field label"
  )

  static let blikOtpPlaceholder = NSLocalizedString(
    "primer_form_redirect_blik_otp_placeholder",
    tableName: tableName,
    bundle: .primerResources,
    value: "000000",
    comment: "BLIK OTP field placeholder"
  )

  static let blikOtpHelper = NSLocalizedString(
    "primer_form_redirect_blik_otp_helper",
    tableName: tableName,
    bundle: .primerResources,
    value: "Open your banking app and generate a BLIK code.",
    comment: "BLIK OTP field helper text"
  )

  static let formRedirectPendingTitle = NSLocalizedString(
    "primer_form_redirect_pending_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "Complete your payment",
    comment: "Form redirect pending screen title"
  )

  static let formRedirectPendingMessage = NSLocalizedString(
    "primer_form_redirect_pending_message",
    tableName: tableName,
    bundle: .primerResources,
    value: "Complete your payment in the app",
    comment: "Form redirect pending screen message"
  )

  static let formRedirectBlikPendingMessage = NSLocalizedString(
    "primer_form_redirect_blik_pending_message",
    tableName: tableName,
    bundle: .primerResources,
    value: "Complete your payment in Blik app",
    comment: "BLIK pending screen message"
  )

  static let formRedirectMBWayPendingMessage = NSLocalizedString(
    "primer_form_redirect_mbway_pending_message",
    tableName: tableName,
    bundle: .primerResources,
    value: "Complete your payment in the MB WAY app",
    comment: "MBWay pending screen message"
  )

  static let otpCodeRequired = NSLocalizedString(
    "primer_form_redirect_otp_code_required",
    tableName: tableName,
    bundle: .primerResources,
    value: "OTP code is required",
    comment: "OTP code required error message"
  )

  static let otpCodeInvalid = NSLocalizedString(
    "primer_form_redirect_otp_code_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Enter a valid 6-digit code",
    comment: "OTP code invalid error message"
  )

  // MARK: Form Redirect Accessibility Strings

  static let a11yFormRedirectOtpLabel = NSLocalizedString(
    "accessibility_form_redirect_otp_label",
    tableName: tableName,
    bundle: .primerResources,
    value: "6 digit BLIK code, required",
    comment: "VoiceOver label for BLIK OTP field"
  )

  static let a11yFormRedirectOtpHint = NSLocalizedString(
    "accessibility_form_redirect_otp_hint",
    tableName: tableName,
    bundle: .primerResources,
    value: "Enter the 6-digit code from your banking app",
    comment: "VoiceOver hint for BLIK OTP field"
  )

  static let a11yFormRedirectPhoneLabel = NSLocalizedString(
    "accessibility_form_redirect_phone_label",
    tableName: tableName,
    bundle: .primerResources,
    value: "Phone number, required",
    comment: "VoiceOver label for MBWay phone number field"
  )

  static let a11yFormRedirectPhoneHint = NSLocalizedString(
    "accessibility_form_redirect_phone_hint",
    tableName: tableName,
    bundle: .primerResources,
    value: "Enter your phone number registered with MBWay",
    comment: "VoiceOver hint for MBWay phone number field"
  )

  static let payWithBlik = NSLocalizedString(
    "primer_form_redirect_blik_submit_button",
    tableName: tableName,
    bundle: .primerResources,
    value: "Pay with BLIK",
    comment: "BLIK submit button text"
  )

  static let payWithMBWay = NSLocalizedString(
    "primer_form_redirect_mbway_submit_button",
    tableName: tableName,
    bundle: .primerResources,
    value: "Pay with MB WAY",
    comment: "MBWay submit button text"
  )

  // MARK: - Accessibility Strings

  // VoiceOver labels, hints, and announcements for CheckoutComponents accessibility support
  // Keys use underscore_case format to match Android SDK for cross-platform consistency

  // MARK: Card Form Accessibility Labels

  static let a11yCardNumberLabel = NSLocalizedString(
    "accessibility_card_form_card_number_label",
    tableName: tableName,
    bundle: .primerResources,
    value: "Card number, required",
    comment: "VoiceOver label for card number field (includes required indicator)"
  )

  static let a11yExpiryLabel = NSLocalizedString(
    "accessibility_card_form_expiry_label",
    tableName: tableName,
    bundle: .primerResources,
    value: "Expiry date, required",
    comment: "VoiceOver label for expiry date field (includes required indicator)"
  )

  static let a11yCVCLabel = NSLocalizedString(
    "accessibility_card_form_cvc_label",
    tableName: tableName,
    bundle: .primerResources,
    value: "Security code, required",
    comment: "VoiceOver label for CVC/CVV field (includes required indicator)"
  )

  static let a11yCardholderNameLabel = NSLocalizedString(
    "accessibility_card_form_cardholder_name_label",
    tableName: tableName,
    bundle: .primerResources,
    value: "Cardholder name",
    comment: "VoiceOver label for cardholder name field"
  )

  // MARK: Card Form Accessibility Hints

  static let a11yCardNumberHint = NSLocalizedString(
    "accessibility_card_form_card_number_hint",
    tableName: tableName,
    bundle: .primerResources,
    value: "Enter your card number",
    comment: "VoiceOver hint for card number field"
  )

  static let a11yExpiryHint = NSLocalizedString(
    "accessibility_card_form_expiry_hint",
    tableName: tableName,
    bundle: .primerResources,
    value: "Enter expiry date in MM/YY format",
    comment: "VoiceOver hint for expiry date field"
  )

  static let a11yCVCHint = NSLocalizedString(
    "accessibility_card_form_cvc_hint",
    tableName: tableName,
    bundle: .primerResources,
    value: "3 or 4 digit code on back of card",
    comment: "VoiceOver hint for CVC/CVV field"
  )

  static let a11yCardholderNameHint = NSLocalizedString(
    "accessibility_card_form_cardholder_name_hint",
    tableName: tableName,
    bundle: .primerResources,
    value: "Enter name as shown on card",
    comment: "VoiceOver hint for cardholder name field"
  )

  // MARK: Billing Address Accessibility Hints

  static let a11yBillingAddressCityHint = NSLocalizedString(
    "accessibility_card_form_billing_address_city_hint",
    tableName: tableName,
    bundle: .primerResources,
    value: "Enter city name",
    comment: "VoiceOver hint for billing address city field"
  )

  static let a11yBillingAddressPostalCodeHint = NSLocalizedString(
    "accessibility_card_form_billing_address_postal_code_hint",
    tableName: tableName,
    bundle: .primerResources,
    value: "Enter postal or ZIP code",
    comment: "VoiceOver hint for billing address postal code field"
  )

  // MARK: Inline Network Selector Accessibility

  static let a11yInlineNetworkButtonHint = NSLocalizedString(
    "accessibility_card_form_network_selector_inline_hint",
    tableName: tableName,
    bundle: .primerResources,
    value: "Double tap to select this network",
    comment: "VoiceOver hint for inline network selector button"
  )

  // MARK: Dropdown Network Selector Accessibility

  static let a11yDropdownNetworkSelectorLabel = NSLocalizedString(
    "accessibility_card_form_network_selector_label",
    tableName: tableName,
    bundle: .primerResources,
    value: "Card network selector",
    comment: "VoiceOver label for dropdown network selector"
  )

  static let a11yDropdownNetworkSelectorHint = NSLocalizedString(
    "accessibility_card_form_network_selector_hint",
    tableName: tableName,
    bundle: .primerResources,
    value: "Double tap to select a different card network",
    comment: "VoiceOver hint for dropdown network selector"
  )

  // MARK: Card Form Accessibility Error Messages

  static let a11yCardNumberErrorInvalid = NSLocalizedString(
    "accessibility_card_form_card_number_error_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Invalid card number. Please check and try again.",
    comment: "VoiceOver error announcement for invalid card number"
  )

  static let a11yCardNumberErrorEmpty = NSLocalizedString(
    "accessibility_card_form_card_number_error_empty",
    tableName: tableName,
    bundle: .primerResources,
    value: "Card number is required.",
    comment: "VoiceOver error announcement for empty card number"
  )

  static let a11yExpiryErrorInvalid = NSLocalizedString(
    "accessibility_card_form_expiry_error_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Invalid expiry date.",
    comment: "VoiceOver error announcement for invalid expiry"
  )

  static let a11yCVCErrorInvalid = NSLocalizedString(
    "accessibility_card_form_cvc_error_invalid",
    tableName: tableName,
    bundle: .primerResources,
    value: "Invalid security code.",
    comment: "VoiceOver error announcement for invalid CVC"
  )

  // MARK: Submit Button Accessibility

  static let a11ySubmitButtonLabel = NSLocalizedString(
    "accessibility_card_form_submit_label",
    tableName: tableName,
    bundle: .primerResources,
    value: "Submit payment",
    comment: "VoiceOver label for submit payment button"
  )

  static let a11ySubmitButtonHint = NSLocalizedString(
    "accessibility_card_form_submit_hint",
    tableName: tableName,
    bundle: .primerResources,
    value: "Double-tap to submit payment",
    comment: "VoiceOver hint for submit payment button"
  )

  static let a11ySubmitButtonLoading = NSLocalizedString(
    "accessibility_card_form_submit_loading",
    tableName: tableName,
    bundle: .primerResources,
    value: "Processing payment, please wait",
    comment: "VoiceOver announcement during payment processing"
  )

  static let a11ySubmitButtonDisabled = NSLocalizedString(
    "accessibility_card_form_submit_disabled",
    tableName: tableName,
    bundle: .primerResources,
    value: "Button disabled. Complete all required fields to enable payment",
    comment: "VoiceOver hint when submit button is disabled due to validation errors"
  )

  // MARK: Payment Selection Accessibility

  static let a11ySavedCardMasked = NSLocalizedString(
    "accessibility_payment_selection_card_masked",
    tableName: tableName,
    bundle: .primerResources,
    value: "card ending in masked digits",
    comment: "VoiceOver label for saved card with masked last 4 digits (privacy protection)"
  )

  static func a11ySavedCardLabel(cardType: String, expiry: String) -> String {
    let format = NSLocalizedString(
      "accessibility_payment_selection_card_full",
      tableName: tableName,
      bundle: .primerResources,
      value: "%@ card ending in %@, expires %@",
      comment: "VoiceOver full saved card announcement with card type, last 4 digits, and expiry"
    )
    return String(format: format, cardType, expiry)
  }

  // MARK: PayPal Accessibility

  static let a11yPayPalLogo = NSLocalizedString(
    "accessibility_paypal_logo",
    tableName: tableName,
    bundle: .primerResources,
    value: "PayPal",
    comment: "VoiceOver label for PayPal logo"
  )

  // MARK: Custom Actions for VoiceOver Rotor

  static let a11yActionEdit = NSLocalizedString(
    "accessibility_action_edit",
    tableName: tableName,
    bundle: .primerResources,
    value: "Edit card details",
    comment: "VoiceOver custom action to edit saved card"
  )

  static let a11yActionDelete = NSLocalizedString(
    "accessibility_action_delete",
    tableName: tableName,
    bundle: .primerResources,
    value: "Delete payment method",
    comment: "VoiceOver custom action to delete saved card"
  )

  static let a11yActionSetDefault = NSLocalizedString(
    "accessibility_action_set_default",
    tableName: tableName,
    bundle: .primerResources,
    value: "Set as default payment method",
    comment: "VoiceOver custom action to set default payment method"
  )

  // MARK: Common Accessibility Strings

  static let a11yRequired = NSLocalizedString(
    "accessibility_common_required",
    tableName: tableName,
    bundle: .primerResources,
    value: "required",
    comment: "VoiceOver indicator that field is required"
  )

  static let a11yOptional = NSLocalizedString(
    "accessibility_common_optional",
    tableName: tableName,
    bundle: .primerResources,
    value: "optional",
    comment: "VoiceOver indicator that field is optional"
  )

  static let a11yLoading = NSLocalizedString(
    "accessibility_common_loading",
    tableName: tableName,
    bundle: .primerResources,
    value: "Loading, please wait",
    comment: "VoiceOver loading announcement"
  )

  static let a11yProcessingPayment = NSLocalizedString(
    "accessibility_common_processing_payment",
    tableName: tableName,
    bundle: .primerResources,
    value: "Processing payment, please wait",
    comment: "VoiceOver announcement during payment processing"
  )

  static let a11yClose = NSLocalizedString(
    "accessibility_common_close",
    tableName: tableName,
    bundle: .primerResources,
    value: "Close",
    comment: "VoiceOver label for close button"
  )

  static let a11yCancel = NSLocalizedString(
    "accessibility_common_cancel",
    tableName: tableName,
    bundle: .primerResources,
    value: "Cancel",
    comment: "VoiceOver label for cancel button"
  )

  static let a11yBack = NSLocalizedString(
    "accessibility_common_back",
    tableName: tableName,
    bundle: .primerResources,
    value: "Go back",
    comment: "VoiceOver label for back button"
  )

  static let a11yEdit = NSLocalizedString(
    "accessibility_action_edit",
    tableName: tableName,
    bundle: .primerResources,
    value: "Edit saved payment methods",
    comment: "VoiceOver label for edit button"
  )

  static let a11yDone = NSLocalizedString(
    "primer_vault_manage_button_done",
    tableName: tableName,
    bundle: .primerResources,
    value: "Done editing saved payment methods",
    comment: "VoiceOver label for done button"
  )

  static let a11yDelete = NSLocalizedString(
    "accessibility_action_delete",
    tableName: tableName,
    bundle: .primerResources,
    value: "Delete",
    comment: "VoiceOver label for delete button"
  )

  static let a11yDeletePaymentMethod = NSLocalizedString(
    "accessibility_vault_delete_payment_method",
    tableName: tableName,
    bundle: .primerResources,
    value: "Delete this payment method",
    comment: "VoiceOver label for delete payment method button on card"
  )

  static let a11yShowAll = NSLocalizedString(
    "accessibility_common_show_all",
    tableName: tableName,
    bundle: .primerResources,
    value: "Show all saved payment methods",
    comment: "VoiceOver label for show all button"
  )

  static func a11yVaultedPaymentMethod(_ name: String) -> String {
    let format = NSLocalizedString(
      "accessibility_vaulted_payment_method",
      tableName: tableName,
      bundle: .primerResources,
      value: "Saved payment method: %@",
      comment:
        "VoiceOver label for vaulted payment method card. Parameter is the payment method name."
    )
    return String(format: format, name)
  }

  static let a11yDismiss = NSLocalizedString(
    "accessibility_common_dismiss",
    tableName: tableName,
    bundle: .primerResources,
    value: "Dismiss",
    comment: "VoiceOver label for dismiss button"
  )

  // MARK: Screen Change Announcements

  static func a11yScreenPaymentMethod(_ paymentMethodName: String) -> String {
    let format = NSLocalizedString(
      "accessibility_screen_payment_method",
      tableName: tableName,
      bundle: .primerResources,
      value: "%@ payment method",
      comment:
        "VoiceOver screen change announcement for payment method screens. Parameter is the payment method name (e.g., 'PayPal', 'Apple Pay')"
    )
    return String(format: format, paymentMethodName)
  }

  static let a11yScreenSuccess = NSLocalizedString(
    "accessibility_screen_success",
    tableName: tableName,
    bundle: .primerResources,
    value: "Payment successful",
    comment: "VoiceOver screen change announcement for success screen"
  )

  static let a11yScreenError = NSLocalizedString(
    "accessibility_screen_error",
    tableName: tableName,
    bundle: .primerResources,
    value: "Payment error occurred",
    comment: "VoiceOver screen change announcement for error screen"
  )

  static let a11yScreenCountrySelection = NSLocalizedString(
    "accessibility_screen_country_selection",
    tableName: tableName,
    bundle: .primerResources,
    value: "Select country",
    comment: "VoiceOver screen change announcement for country selection"
  )

  static let a11yScreenProcessingPayment = NSLocalizedString(
    "accessibility_screen_processing_payment",
    tableName: tableName,
    bundle: .primerResources,
    value: "Processing payment",
    comment: "VoiceOver screen change announcement for payment processing"
  )

  static let a11yScreenLoadingPaymentMethods = NSLocalizedString(
    "accessibility_screen_loading_payment_methods",
    tableName: tableName,
    bundle: .primerResources,
    value: "Loading payment methods",
    comment: "VoiceOver screen change announcement for loading payment methods"
  )

  // MARK: Error Announcements

  static func a11yMultipleErrors(_ count: Int) -> String {
    let format = NSLocalizedString(
      "accessibility_error_multiple_errors",
      tableName: tableName,
      bundle: .primerResources,
      value: "%d errors found",
      comment: "VoiceOver announcement for multiple validation errors"
    )
    return String(format: format, count)
  }

  static let a11yGenericError = NSLocalizedString(
    "accessibility_error_generic",
    tableName: tableName,
    bundle: .primerResources,
    value: "An error occurred. Please try again.",
    comment: "VoiceOver generic error announcement"
  )

  // MARK: - ACH Strings

  static let achTitle = NSLocalizedString(
    "primer_ach_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "Bank Account",
    comment: "ACH payment screen title"
  )

  static let achPayWithTitle = NSLocalizedString(
    "primer_ach_pay_with_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "Pay with ACH",
    comment: "ACH payment screen title matching Web/Drop-In"
  )

  static let achUserDetailsTitle = NSLocalizedString(
    "primer_ach_user_details_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "Enter your details to connect your bank account",
    comment: "ACH user details collection description"
  )

  static let achPersonalDetailsSubtitle = NSLocalizedString(
    "primer_ach_personal_details_subtitle",
    tableName: tableName,
    bundle: .primerResources,
    value: "Your personal details",
    comment: "ACH user details section header matching Web/Drop-In"
  )

  static let achEmailDisclaimer = NSLocalizedString(
    "primer_ach_email_disclaimer",
    tableName: tableName,
    bundle: .primerResources,
    value: "We'll only use this to keep you updated about your payment",
    comment: "ACH email field disclaimer text"
  )

  static let achContinueButton = NSLocalizedString(
    "primer_ach_button_continue",
    tableName: tableName,
    bundle: .primerResources,
    value: "Continue",
    comment: "ACH continue button text"
  )

  static let achMandateTitle = NSLocalizedString(
    "primer_ach_mandate_title",
    tableName: tableName,
    bundle: .primerResources,
    value: "Authorization",
    comment: "ACH mandate screen title"
  )

  static let achMandateAcceptButton = NSLocalizedString(
    "primer_ach_mandate_button_accept",
    tableName: tableName,
    bundle: .primerResources,
    value: "I Agree",
    comment: "ACH mandate accept button text"
  )

  static let achMandateDeclineButton = NSLocalizedString(
    "primer_ach_mandate_button_decline",
    tableName: tableName,
    bundle: .primerResources,
    value: "Cancel",
    comment: "ACH mandate decline button text"
  )

  static func achMandateTemplate(merchantName: String) -> String {
    let format = NSLocalizedString(
      "primer_ach_mandate_template",
      tableName: tableName,
      bundle: .primerResources,
      value: "By clicking \"I Agree\", you authorize %@ to debit the bank account specified above for any amount owed for charges arising from your use of %@'s services and/or purchase of products from %@, pursuant to %@'s website and terms, until this authorization is revoked. You may amend or cancel this authorization at any time by providing notice to %@ with 30 (thirty) days notice.",
      comment: "ACH mandate template text. Parameter is merchant name."
    )
    return String(format: format, merchantName, merchantName, merchantName, merchantName, merchantName)
  }

  // MARK: ACH Accessibility Strings

  static let a11yAchContinueHint = NSLocalizedString(
    "accessibility_ach_continue_hint",
    tableName: tableName,
    bundle: .primerResources,
    value: "Double tap to continue to bank account selection",
    comment: "VoiceOver hint for ACH continue button"
  )

  static let a11yAchMandateAcceptHint = NSLocalizedString(
    "accessibility_ach_mandate_accept_hint",
    tableName: tableName,
    bundle: .primerResources,
    value: "Double tap to accept the authorization and complete payment",
    comment: "VoiceOver hint for ACH mandate accept button"
  )

  static let a11yAchMandateDeclineHint = NSLocalizedString(
    "accessibility_ach_mandate_decline_hint",
    tableName: tableName,
    bundle: .primerResources,
    value: "Double tap to decline and cancel the payment",
    comment: "VoiceOver hint for ACH mandate decline button"
  )

  // MARK: - Web Redirect Strings

  static func webRedirectButtonContinue(_ methodName: String) -> String {
    let format = NSLocalizedString(
      "primer_web_redirect_button_continue",
      tableName: tableName,
      bundle: .primerResources,
      value: "Continue with %@",
      comment: "Web redirect submit button text with payment method name"
    )
    return String(format: format, methodName)
  }

  static let webRedirectDescription = NSLocalizedString(
    "primer_web_redirect_description",
    tableName: tableName,
    bundle: .primerResources,
    value: "You will be redirected to complete your payment",
    comment: "Web redirect screen description text"
  )

  // MARK: - Web Redirect Accessibility

  static func a11yWebRedirectSubmitButton(_ methodName: String) -> String {
    let format = NSLocalizedString(
      "accessibility_web_redirect_submit_button",
      tableName: tableName,
      bundle: .primerResources,
      value: "Pay with %@",
      comment: "VoiceOver label for web redirect pay button"
    )
    return String(format: format, methodName)
  }

  static let a11yWebRedirectLoading = NSLocalizedString(
    "accessibility_web_redirect_loading",
    tableName: tableName,
    bundle: .primerResources,
    value: "Processing payment",
    comment: "VoiceOver announcement when web redirect payment is processing"
  )

  static let a11yWebRedirectRedirecting = NSLocalizedString(
    "accessibility_web_redirect_redirecting",
    tableName: tableName,
    bundle: .primerResources,
    value: "Opening payment page",
    comment: "VoiceOver announcement when redirecting to payment provider"
  )

  static let a11yWebRedirectPolling = NSLocalizedString(
    "accessibility_web_redirect_polling",
    tableName: tableName,
    bundle: .primerResources,
    value: "Waiting for payment confirmation",
    comment: "VoiceOver announcement when polling for payment status"
  )

  static let a11yWebRedirectSuccess = NSLocalizedString(
    "accessibility_web_redirect_success",
    tableName: tableName,
    bundle: .primerResources,
    value: "Payment successful",
    comment: "VoiceOver announcement when web redirect payment succeeds"
  )

  static func a11yWebRedirectFailure(_ message: String) -> String {
    let format = NSLocalizedString(
      "accessibility_web_redirect_failure",
      tableName: tableName,
      bundle: .primerResources,
      value: "Payment failed: %@",
      comment: "VoiceOver announcement when web redirect payment fails"
    )
    return String(format: format, message)
  }

  // MARK: - QR Code Strings

  static let qrCodeScanInstruction = NSLocalizedString(
    "primer_qr_code_scan_instruction",
    tableName: tableName,
    bundle: .primerResources,
    value: "Scan to pay or take a screenshot",
    comment: "QR code scanning instruction text"
  )

  static let qrCodeUploadInstruction = NSLocalizedString(
    "primer_qr_code_upload_instruction",
    tableName: tableName,
    bundle: .primerResources,
    value: "Upload the screenshot in your banking app",
    comment: "QR code upload instruction text"
  )

  // MARK: - QR Code Accessibility Strings

  static let a11yQrCodeImage = NSLocalizedString(
    "accessibility_qr_code_image",
    tableName: tableName,
    bundle: .primerResources,
    value: "QR code for payment",
    comment: "VoiceOver label for QR code image"
  )

  static let a11yQrCodeScreen = NSLocalizedString(
    "accessibility_qr_code_screen",
    tableName: tableName,
    bundle: .primerResources,
    value: "QR code payment",
    comment: "VoiceOver screen announcement for QR code payment screen"
  )

  static let a11yQrCodeScanHint = NSLocalizedString(
    "accessibility_qr_code_scan_hint",
    tableName: tableName,
    bundle: .primerResources,
    value: "Take a screenshot to save the QR code",
    comment: "VoiceOver hint for QR code image"
  )

  static let a11yQrCodeSuccessIcon = NSLocalizedString(
    "accessibility_qr_code_success_icon",
    tableName: tableName,
    bundle: .primerResources,
    value: "Payment successful",
    comment: "VoiceOver label for QR code payment success icon"
  )
}

// swiftlint:enable file_length
