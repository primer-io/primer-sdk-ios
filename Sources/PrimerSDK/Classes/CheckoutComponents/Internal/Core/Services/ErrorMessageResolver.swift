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
        switch key {
        // Form validation error patterns
        case "form_error_required":
            return CheckoutComponentsStrings.formErrorRequired
        case "form_error_invalid":
            return CheckoutComponentsStrings.formErrorInvalid
        case "form_error_card_type_not_supported":
            return CheckoutComponentsStrings.formErrorCardTypeNotSupported
        case "form_error_card_holder_name_length":
            return CheckoutComponentsStrings.formErrorCardHolderNameLength

        // Success/error screen messages
        case "payment_successful":
            return CheckoutComponentsStrings.paymentSuccessful
        case "payment_failed":
            return CheckoutComponentsStrings.paymentFailed

        // Default fallback
        default:
            return CheckoutComponentsStrings.unexpectedError
        }
    }

    /// Get localized field name for error message formatting
    private static func getLocalizedFieldName(_ key: String) -> String {
        switch key {
        // Card field names
        case "card_number_field":
            return CheckoutComponentsStrings.cardNumberFieldName
        case "cvv_field":
            return CheckoutComponentsStrings.cvvFieldName
        case "expiry_date_field":
            return CheckoutComponentsStrings.expiryDateFieldName
        case "cardholder_name_field":
            return CheckoutComponentsStrings.cardholderNameFieldName

        // Personal information field names
        case "first_name_field":
            return CheckoutComponentsStrings.firstNameFieldName
        case "last_name_field":
            return CheckoutComponentsStrings.lastNameFieldName
        case "email_field":
            return CheckoutComponentsStrings.emailFieldName
        case "phone_number_field":
            return CheckoutComponentsStrings.phoneNumberFieldName
        case "country_field":
            return CheckoutComponentsStrings.countryFieldName

        // Generic fallback
        default:
            return "Field"
        }
    }
}

// MARK: - Convenience Extensions

extension ErrorMessageResolver {

    /// Create a validation error with Android-matching structure for required field validation
    static func createRequiredFieldError(for inputElementType: ValidationError.InputElementType) -> ValidationError {
        let fieldKey = fieldNameKey(for: inputElementType)
        let errorId = "\(inputElementType.rawValue.lowercased())_required"

        return ValidationError(
            inputElementType: inputElementType,
            errorId: errorId,
            fieldNameKey: fieldKey,
            errorMessageKey: nil,
            errorFormatKey: "form_error_required",
            code: "invalid-\(inputElementType.rawValue.lowercased())",
            message: "Field is required" // Legacy fallback
        )
    }

    /// Create a validation error with Android-matching structure for invalid field validation
    static func createInvalidFieldError(for inputElementType: ValidationError.InputElementType) -> ValidationError {
        let fieldKey = fieldNameKey(for: inputElementType)
        let errorId = "\(inputElementType.rawValue.lowercased())_invalid"

        return ValidationError(
            inputElementType: inputElementType,
            errorId: errorId,
            fieldNameKey: fieldKey,
            errorMessageKey: nil,
            errorFormatKey: "form_error_invalid",
            code: "invalid-\(inputElementType.rawValue.lowercased())",
            message: "Field is invalid" // Legacy fallback
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
        default:
            return "field"
        }
    }
}
