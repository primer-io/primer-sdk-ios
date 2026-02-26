//
//  ErrorMessageResolver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

final class ErrorMessageResolver {

  static func resolveErrorMessage(for error: ValidationError) -> String? {
    // Resolution priority:
    // 1. Try formatted error with field name placeholder
    if let formatKey = error.errorFormatKey,
      let fieldNameKey = error.fieldNameKey
    {
      let fieldName = getLocalizedFieldName(fieldNameKey)
      let formatString = getLocalizedString(formatKey)
      return String(format: formatString, fieldName)
    }

    // 2. Try direct error message key
    if let messageKey = error.errorMessageKey {
      return getLocalizedString(messageKey)
    }

    // 3. Fall back to error ID
    return error.errorId
  }

  private static func getLocalizedString(_ key: String) -> String {
    // Check for form validation errors first
    if let formError = getFormValidationError(for: key) {
      return formError
    }

    // Check for field required errors
    if let requiredError = getRequiredFieldError(for: key) {
      return requiredError
    }

    // Check for field invalid errors
    if let invalidError = getInvalidFieldError(for: key) {
      return invalidError
    }

    // Check for result screen messages
    if let resultError = getResultScreenMessage(for: key) {
      return resultError
    }

    // Default fallback
    return CheckoutComponentsStrings.unexpectedError
  }

  private static func getFormValidationError(for key: String) -> String? {
    switch key {
    case "form_error_card_type_not_supported":
      CheckoutComponentsStrings.formErrorCardTypeNotSupported
    case "form_error_card_holder_name_length":
      CheckoutComponentsStrings.formErrorCardHolderNameLength
    case "form_error_card_expired":
      CheckoutComponentsStrings.formErrorCardExpired
    default:
      nil
    }
  }

  private static func getRequiredFieldError(for key: String) -> String? {
    switch key {
    case "checkout_components_first_name_required":
      CheckoutComponentsStrings.firstNameErrorRequired
    case "checkout_components_last_name_required":
      CheckoutComponentsStrings.lastNameErrorRequired
    case "checkout_components_email_required":
      CheckoutComponentsStrings.emailErrorRequired
    case "checkout_components_country_required":
      CheckoutComponentsStrings.countryCodeErrorRequired
    case "checkout_components_address_line_1_required":
      CheckoutComponentsStrings.addressLine1ErrorRequired
    case "checkout_components_address_line_2_required":
      CheckoutComponentsStrings.addressLine2ErrorRequired
    case "checkout_components_city_required":
      CheckoutComponentsStrings.cityErrorRequired
    case "checkout_components_state_required":
      CheckoutComponentsStrings.stateErrorRequired
    case "checkout_components_postal_code_required":
      CheckoutComponentsStrings.postalCodeErrorRequired
    case "checkout_components_phone_number_required":
      CheckoutComponentsStrings.enterValidPhoneNumber
    case "checkout_components_otp_code_required":
      CheckoutComponentsStrings.otpCodeRequired
    case "checkout_components_retail_outlet_required":
      "Retail outlet is required"
    default:
      nil
    }
  }

  private static func getInvalidFieldError(for key: String) -> String? {
    switch key {
    // Card field validation errors
    case "checkout_components_card_number_invalid":
      CheckoutComponentsStrings.enterValidCardNumber
    case "checkout_components_cvv_invalid":
      CheckoutComponentsStrings.enterValidCVV
    case "checkout_components_expiry_date_invalid":
      CheckoutComponentsStrings.enterValidExpiryDate
    case "checkout_components_cardholder_name_invalid":
      CheckoutComponentsStrings.enterValidCardholderName
    // Billing address field validation errors
    case "checkout_components_first_name_invalid":
      CheckoutComponentsStrings.firstNameErrorInvalid
    case "checkout_components_last_name_invalid":
      CheckoutComponentsStrings.lastNameErrorInvalid
    case "checkout_components_email_invalid":
      CheckoutComponentsStrings.emailErrorInvalid
    case "checkout_components_country_invalid":
      CheckoutComponentsStrings.countryCodeErrorInvalid
    case "checkout_components_address_line_1_invalid":
      CheckoutComponentsStrings.addressLine1ErrorInvalid
    case "checkout_components_address_line_2_invalid":
      CheckoutComponentsStrings.addressLine2ErrorInvalid
    case "checkout_components_city_invalid":
      CheckoutComponentsStrings.cityErrorInvalid
    case "checkout_components_state_invalid":
      CheckoutComponentsStrings.stateErrorInvalid
    case "checkout_components_postal_code_invalid":
      CheckoutComponentsStrings.postalCodeErrorInvalid
    case "checkout_components_phone_number_invalid":
      CheckoutComponentsStrings.enterValidPhoneNumber
    case "checkout_components_otp_code_invalid":
      CheckoutComponentsStrings.otpCodeInvalid
    case "checkout_components_retail_outlet_invalid":
      "Invalid retail outlet"
    default:
      nil
    }
  }

  private static func getResultScreenMessage(for key: String) -> String? {
    switch key {
    case "payment_successful":
      CheckoutComponentsStrings.paymentSuccessful
    case "payment_failed":
      CheckoutComponentsStrings.paymentFailed
    default:
      nil
    }
  }

  private static func getLocalizedFieldName(_ key: String) -> String {
    // Check for personal information field names first
    if let personalFieldName = getPersonalFieldName(for: key) {
      return personalFieldName
    }

    // Check for address field names
    if let addressFieldName = getAddressFieldName(for: key) {
      return addressFieldName
    }

    // Check for card field names
    if let cardFieldName = getCardFieldName(for: key) {
      return cardFieldName
    }

    // Generic fallback
    return "Field"
  }

  private static func getPersonalFieldName(for key: String) -> String? {
    switch key {
    case "first_name_field":
      CheckoutComponentsStrings.firstNameLabel
    case "last_name_field":
      CheckoutComponentsStrings.lastNameLabel
    case "email_field":
      CheckoutComponentsStrings.emailLabel
    case "phone_number_field":
      CheckoutComponentsStrings.phoneNumberLabel
    default:
      nil
    }
  }

  private static func getAddressFieldName(for key: String) -> String? {
    switch key {
    case "country_field":
      CheckoutComponentsStrings.countryLabel
    case "address_line_1_field":
      CheckoutComponentsStrings.addressLine1Label
    case "address_line_2_field":
      CheckoutComponentsStrings.addressLine2Label
    case "city_field":
      CheckoutComponentsStrings.cityLabel
    case "state_field":
      CheckoutComponentsStrings.stateLabel
    case "postal_code_field":
      CheckoutComponentsStrings.postalCodeLabel
    default:
      nil
    }
  }

  private static func getCardFieldName(for key: String) -> String? {
    switch key {
    case "card_number_field":
      NSLocalizedString(
        "primer-form-text-field-title-card-number", bundle: Bundle.primerResources,
        value: "Card number", comment: "Card number field name")
    case "cvv_field":
      NSLocalizedString(
        "primer-card-form-cvv", bundle: Bundle.primerResources, value: "CVV",
        comment: "CVV field name")
    case "expiry_date_field":
      NSLocalizedString(
        "primer-form-text-field-title-expiry-date", bundle: Bundle.primerResources,
        value: "Expiry date", comment: "Expiry date field name")
    case "cardholder_name_field":
      NSLocalizedString(
        "primer-card-form-name", bundle: Bundle.primerResources, value: "Name",
        comment: "Cardholder name field name")
    case "otp_code_field":
      NSLocalizedString(
        "primer-otp-code-field", bundle: Bundle.primerResources, value: "OTP code",
        comment: "OTP code field name")
    default:
      nil
    }
  }
}

// MARK: - Convenience Extensions

extension ErrorMessageResolver {

  static func createRequiredFieldError(for inputElementType: ValidationError.InputElementType)
    -> ValidationError
  {
    let errorMessageKey = requiredErrorMessageKey(for: inputElementType)
    let errorId = "\(inputElementType.rawValue.lowercased())_required"

    return ValidationError(
      inputElementType: inputElementType,
      errorId: errorId,
      fieldNameKey: nil,
      errorMessageKey: errorMessageKey,
      errorFormatKey: nil,
      code: "invalid-\(inputElementType.rawValue.lowercased())",
      message: "Field is required"  // Default fallback
    )
  }

  static func createInvalidFieldError(for inputElementType: ValidationError.InputElementType)
    -> ValidationError
  {
    let errorMessageKey = invalidErrorMessageKey(for: inputElementType)
    let errorId = "\(inputElementType.rawValue.lowercased())_invalid"

    return ValidationError(
      inputElementType: inputElementType,
      errorId: errorId,
      fieldNameKey: nil,
      errorMessageKey: errorMessageKey,
      errorFormatKey: nil,
      code: "invalid-\(inputElementType.rawValue.lowercased())",
      message: "Field is invalid"  // Default fallback
    )
  }

  private static func requiredErrorMessageKey(
    for inputElementType: ValidationError.InputElementType
  ) -> String {
    switch inputElementType {
    case .firstName:
      "checkout_components_first_name_required"
    case .lastName:
      "checkout_components_last_name_required"
    case .email:
      "checkout_components_email_required"
    case .countryCode:
      "checkout_components_country_required"
    case .addressLine1:
      "checkout_components_address_line_1_required"
    case .addressLine2:
      "checkout_components_address_line_2_required"
    case .city:
      "checkout_components_city_required"
    case .state:
      "checkout_components_state_required"
    case .postalCode:
      "checkout_components_postal_code_required"
    case .phoneNumber:
      "checkout_components_phone_number_required"
    case .otpCode:
      "checkout_components_otp_code_required"
    case .retailOutlet:
      "checkout_components_retail_outlet_required"
    default:
      "form_error_required"
    }
  }

  private static func invalidErrorMessageKey(for inputElementType: ValidationError.InputElementType)
    -> String
  {
    switch inputElementType {
    // Card field validation error keys
    case .cardNumber:
      "checkout_components_card_number_invalid"
    case .cvv:
      "checkout_components_cvv_invalid"
    case .expiryDate:
      "checkout_components_expiry_date_invalid"
    case .cardholderName:
      "checkout_components_cardholder_name_invalid"
    // Billing address field validation error keys
    case .firstName:
      "checkout_components_first_name_invalid"
    case .lastName:
      "checkout_components_last_name_invalid"
    case .email:
      "checkout_components_email_invalid"
    case .countryCode:
      "checkout_components_country_invalid"
    case .addressLine1:
      "checkout_components_address_line_1_invalid"
    case .addressLine2:
      "checkout_components_address_line_2_invalid"
    case .city:
      "checkout_components_city_invalid"
    case .state:
      "checkout_components_state_invalid"
    case .postalCode:
      "checkout_components_postal_code_invalid"
    case .phoneNumber:
      "checkout_components_phone_number_invalid"
    case .otpCode:
      "checkout_components_otp_code_invalid"
    case .retailOutlet:
      "checkout_components_retail_outlet_invalid"
    default:
      "form_error_invalid"
    }
  }
}
