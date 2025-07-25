//
//  ErrorMessageResolver.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 24.6.25.
//

import Foundation

/// Android parity: Error message resolution service matching Android's resolveErrorMessage() pattern.
/// This service converts ValidationError objects to localized, formatted error messages.
internal final class ErrorMessageResolver {

    /// Resolve error message to match Android's string resolution pattern exactly
    /// @param error The validation error to resolve
    /// @return Localized error message string, or nil if error cannot be resolved
    static func resolveErrorMessage(for error: ValidationError) -> String? {
        // Match Android's resolution priority:
        // 1. Try formatted error with field name placeholder
        if let formatKey = error.errorFormatKey,
           let fieldNameKey = error.fieldNameKey {
            let fieldName = getLocalizedFieldName(fieldNameKey)
            let formatString = getLocalizedString(formatKey)
            return String(format: formatString, fieldName)
        }

        // 2. Try direct error message key
        if let messageKey = error.errorMessageKey {
            return getLocalizedString(messageKey)
        }

        // 3. Fall back to error ID (like Android)
        return error.errorId
    }

    /// Get localized string for error format/message keys
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

    /// Get form validation error messages
    private static func getFormValidationError(for key: String) -> String? {
        switch key {
        case "form_error_card_type_not_supported":
            return CheckoutComponentsStrings.formErrorCardTypeNotSupported
        case "form_error_card_holder_name_length":
            return CheckoutComponentsStrings.formErrorCardHolderNameLength
        case "form_error_card_expired":
            return CheckoutComponentsStrings.formErrorCardExpired
        default:
            return nil
        }
    }

    /// Get required field error messages
    private static func getRequiredFieldError(for key: String) -> String? {
        switch key {
        case "checkout_components_first_name_required":
            return CheckoutComponentsStrings.firstNameErrorRequired
        case "checkout_components_last_name_required":
            return CheckoutComponentsStrings.lastNameErrorRequired
        case "checkout_components_email_required":
            return CheckoutComponentsStrings.emailErrorRequired
        case "checkout_components_country_required":
            return CheckoutComponentsStrings.countryCodeErrorRequired
        case "checkout_components_address_line_1_required":
            return CheckoutComponentsStrings.addressLine1ErrorRequired
        case "checkout_components_address_line_2_required":
            return CheckoutComponentsStrings.addressLine2ErrorRequired
        case "checkout_components_city_required":
            return CheckoutComponentsStrings.cityErrorRequired
        case "checkout_components_state_required":
            return CheckoutComponentsStrings.stateErrorRequired
        case "checkout_components_postal_code_required":
            return CheckoutComponentsStrings.postalCodeErrorRequired
        case "checkout_components_phone_number_required":
            return CheckoutComponentsStrings.enterValidPhoneNumber
        case "checkout_components_retail_outlet_required":
            return "Retail outlet is required"
        default:
            return nil
        }
    }

    /// Get invalid field error messages
    private static func getInvalidFieldError(for key: String) -> String? {
        switch key {
        // Card field validation errors
        case "checkout_components_card_number_invalid":
            return CheckoutComponentsStrings.enterValidCardNumber
        case "checkout_components_cvv_invalid":
            return CheckoutComponentsStrings.enterValidCVV
        case "checkout_components_expiry_date_invalid":
            return CheckoutComponentsStrings.enterValidExpiryDate
        case "checkout_components_cardholder_name_invalid":
            return CheckoutComponentsStrings.enterValidCardholderName
        // Billing address field validation errors
        case "checkout_components_first_name_invalid":
            return CheckoutComponentsStrings.firstNameErrorInvalid
        case "checkout_components_last_name_invalid":
            return CheckoutComponentsStrings.lastNameErrorInvalid
        case "checkout_components_email_invalid":
            return CheckoutComponentsStrings.emailErrorInvalid
        case "checkout_components_country_invalid":
            return CheckoutComponentsStrings.countryCodeErrorInvalid
        case "checkout_components_address_line_1_invalid":
            return CheckoutComponentsStrings.addressLine1ErrorInvalid
        case "checkout_components_address_line_2_invalid":
            return CheckoutComponentsStrings.addressLine2ErrorInvalid
        case "checkout_components_city_invalid":
            return CheckoutComponentsStrings.cityErrorInvalid
        case "checkout_components_state_invalid":
            return CheckoutComponentsStrings.stateErrorInvalid
        case "checkout_components_postal_code_invalid":
            return CheckoutComponentsStrings.postalCodeErrorInvalid
        case "checkout_components_phone_number_invalid":
            return CheckoutComponentsStrings.enterValidPhoneNumber
        case "checkout_components_retail_outlet_invalid":
            return "Invalid retail outlet"
        default:
            return nil
        }
    }

    /// Get result screen messages
    private static func getResultScreenMessage(for key: String) -> String? {
        switch key {
        case "payment_successful":
            return CheckoutComponentsStrings.paymentSuccessful
        case "payment_failed":
            return CheckoutComponentsStrings.paymentFailed
        default:
            return nil
        }
    }

    /// Get localized field name for error message formatting
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

    /// Get personal information field names
    private static func getPersonalFieldName(for key: String) -> String? {
        switch key {
        case "first_name_field":
            return CheckoutComponentsStrings.firstNameLabel
        case "last_name_field":
            return CheckoutComponentsStrings.lastNameLabel
        case "email_field":
            return CheckoutComponentsStrings.emailLabel
        case "phone_number_field":
            return CheckoutComponentsStrings.phoneNumberLabel
        default:
            return nil
        }
    }

    /// Get address field names
    private static func getAddressFieldName(for key: String) -> String? {
        switch key {
        case "country_field":
            return CheckoutComponentsStrings.countryLabel
        case "address_line_1_field":
            return CheckoutComponentsStrings.addressLine1Label
        case "address_line_2_field":
            return CheckoutComponentsStrings.addressLine2Label
        case "city_field":
            return CheckoutComponentsStrings.cityLabel
        case "state_field":
            return CheckoutComponentsStrings.stateLabel
        case "postal_code_field":
            return CheckoutComponentsStrings.postalCodeLabel
        default:
            return nil
        }
    }

    /// Get card field names
    private static func getCardFieldName(for key: String) -> String? {
        switch key {
        case "card_number_field":
            return NSLocalizedString("primer-form-text-field-title-card-number", bundle: Bundle.primerResources, value: "Card number", comment: "Card number field name")
        case "cvv_field":
            return NSLocalizedString("primer-card-form-cvv", bundle: Bundle.primerResources, value: "CVV", comment: "CVV field name")
        case "expiry_date_field":
            return NSLocalizedString("primer-form-text-field-title-expiry-date", bundle: Bundle.primerResources, value: "Expiry date", comment: "Expiry date field name")
        case "cardholder_name_field":
            return NSLocalizedString("primer-card-form-name", bundle: Bundle.primerResources, value: "Name", comment: "Cardholder name field name")
        case "otp_code_field":
            return NSLocalizedString("primer-otp-code-field", bundle: Bundle.primerResources, value: "OTP code", comment: "OTP code field name")
        default:
            return nil
        }
    }
}

// MARK: - Convenience Extensions

extension ErrorMessageResolver {

    /// Create a validation error with Android-matching structure for required field validation
    static func createRequiredFieldError(for inputElementType: ValidationError.InputElementType) -> ValidationError {
        let errorMessageKey = requiredErrorMessageKey(for: inputElementType)
        let errorId = "\(inputElementType.rawValue.lowercased())_required"

        return ValidationError(
            inputElementType: inputElementType,
            errorId: errorId,
            fieldNameKey: nil,
            errorMessageKey: errorMessageKey,
            errorFormatKey: nil,
            code: "invalid-\(inputElementType.rawValue.lowercased())",
            message: "Field is required" // Default fallback
        )
    }

    /// Create a validation error with Android-matching structure for invalid field validation
    static func createInvalidFieldError(for inputElementType: ValidationError.InputElementType) -> ValidationError {
        let errorMessageKey = invalidErrorMessageKey(for: inputElementType)
        let errorId = "\(inputElementType.rawValue.lowercased())_invalid"

        return ValidationError(
            inputElementType: inputElementType,
            errorId: errorId,
            fieldNameKey: nil,
            errorMessageKey: errorMessageKey,
            errorFormatKey: nil,
            code: "invalid-\(inputElementType.rawValue.lowercased())",
            message: "Field is invalid" // Default fallback
        )
    }

    /// Get appropriate field name key for input element type
    private static func fieldNameKey(for inputElementType: ValidationError.InputElementType) -> String {
        switch inputElementType {
        case .cardNumber:
            return "card_number_field"
        case .cvv:
            return "cvv_field"
        case .expiryDate:
            return "expiry_date_field"
        case .cardholderName:
            return "cardholder_name_field"
        case .firstName:
            return "first_name_field"
        case .lastName:
            return "last_name_field"
        case .email:
            return "email_field"
        case .phoneNumber:
            return "phone_number_field"
        case .countryCode:
            return "country_field"
        case .addressLine1:
            return "address_line_1_field"
        case .addressLine2:
            return "address_line_2_field"
        case .city:
            return "city_field"
        case .state:
            return "state_field"
        case .postalCode:
            return "postal_code_field"
        case .otpCode:
            return "otp_code_field"
        default:
            return "field"
        }
    }

    /// Get specific required error message key for input element type
    private static func requiredErrorMessageKey(for inputElementType: ValidationError.InputElementType) -> String {
        switch inputElementType {
        case .firstName:
            return "checkout_components_first_name_required"
        case .lastName:
            return "checkout_components_last_name_required"
        case .email:
            return "checkout_components_email_required"
        case .countryCode:
            return "checkout_components_country_required"
        case .addressLine1:
            return "checkout_components_address_line_1_required"
        case .addressLine2:
            return "checkout_components_address_line_2_required"
        case .city:
            return "checkout_components_city_required"
        case .state:
            return "checkout_components_state_required"
        case .postalCode:
            return "checkout_components_postal_code_required"
        case .phoneNumber:
            return "checkout_components_phone_number_required"
        case .retailOutlet:
            return "checkout_components_retail_outlet_required"
        default:
            return "form_error_required"
        }
    }

    /// Get specific invalid error message key for input element type
    private static func invalidErrorMessageKey(for inputElementType: ValidationError.InputElementType) -> String {
        switch inputElementType {
        // Card field validation error keys
        case .cardNumber:
            return "checkout_components_card_number_invalid"
        case .cvv:
            return "checkout_components_cvv_invalid"
        case .expiryDate:
            return "checkout_components_expiry_date_invalid"
        case .cardholderName:
            return "checkout_components_cardholder_name_invalid"
        // Billing address field validation error keys
        case .firstName:
            return "checkout_components_first_name_invalid"
        case .lastName:
            return "checkout_components_last_name_invalid"
        case .email:
            return "checkout_components_email_invalid"
        case .countryCode:
            return "checkout_components_country_invalid"
        case .addressLine1:
            return "checkout_components_address_line_1_invalid"
        case .addressLine2:
            return "checkout_components_address_line_2_invalid"
        case .city:
            return "checkout_components_city_invalid"
        case .state:
            return "checkout_components_state_invalid"
        case .postalCode:
            return "checkout_components_postal_code_invalid"
        case .phoneNumber:
            return "checkout_components_phone_number_invalid"
        case .retailOutlet:
            return "checkout_components_retail_outlet_invalid"
        default:
            return "form_error_invalid"
        }
    }
}
