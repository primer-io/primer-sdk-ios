//
//  BillingAddressValidationRules.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 26.6.25.
//

import Foundation

/// Validation rule for first names with Android parity error messaging
internal class FirstNameRule: ValidationRule {

    func validate(_ value: String?) -> ValidationResult {
        guard let value = value else {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .firstName)
            return .invalid(code: error.code, message: error.message)
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .firstName)
            return .invalid(code: error.code, message: error.message)
        }

        if trimmed.count < 2 {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .firstName)
            return .invalid(code: error.code, message: error.message)
        }

        return .valid
    }
}

/// Validation rule for last names with Android parity error messaging
internal class LastNameRule: ValidationRule {

    func validate(_ value: String?) -> ValidationResult {
        guard let value = value else {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .lastName)
            return .invalid(code: error.code, message: error.message)
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .lastName)
            return .invalid(code: error.code, message: error.message)
        }

        if trimmed.count < 2 {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .lastName)
            return .invalid(code: error.code, message: error.message)
        }

        return .valid
    }
}

/// Validation rule for email addresses with Android parity error messaging
internal class EmailValidationRule: ValidationRule {

    func validate(_ value: String?) -> ValidationResult {
        guard let value = value else {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .email)
            return .invalid(code: error.code, message: error.message)
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .email)
            return .invalid(code: error.code, message: error.message)
        }

        // Basic email validation pattern
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        if !emailPredicate.evaluate(with: trimmed) {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .email)
            return .invalid(code: error.code, message: error.message)
        }

        return .valid
    }
}

/// Validation rule for phone numbers with Android parity error messaging
internal class PhoneNumberValidationRule: ValidationRule {

    func validate(_ value: String?) -> ValidationResult {
        guard let value = value else {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .phoneNumber)
            return .invalid(code: error.code, message: error.message)
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .phoneNumber)
            return .invalid(code: error.code, message: error.message)
        }

        // Basic phone number validation - digits, spaces, dashes, parentheses, plus
        let phoneRegex = "^[+]?[0-9\\s\\-\\(\\)]+$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        if !phonePredicate.evaluate(with: trimmed) || trimmed.count < 8 {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .phoneNumber)
            return .invalid(code: error.code, message: error.message)
        }

        return .valid
    }
}

/// Generic validation rule for address fields with Android parity error messaging
internal class AddressFieldRule: ValidationRule {

    private let inputType: ValidationError.InputElementType
    private let isRequired: Bool

    init(inputType: ValidationError.InputElementType, isRequired: Bool = true) {
        self.inputType = inputType
        self.isRequired = isRequired
    }

    func validate(_ value: String?) -> ValidationResult {
        guard let value = value else {
            if isRequired {
                let error = ErrorMessageResolver.createRequiredFieldError(for: inputType)
                return .invalid(code: error.code, message: error.message)
            }
            return .valid
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if isRequired && trimmed.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: inputType)
            return .invalid(code: error.code, message: error.message)
        }

        // Optional fields can be empty
        if !isRequired && trimmed.isEmpty {
            return .valid
        }

        // Basic length validation for non-empty fields
        if !trimmed.isEmpty && trimmed.count < 2 {
            let error = ErrorMessageResolver.createInvalidFieldError(for: inputType)
            return .invalid(code: error.code, message: error.message)
        }

        return .valid
    }
}

/// Validation rule for postal codes with Android parity error messaging
internal class BillingPostalCodeRule: ValidationRule {

    func validate(_ value: String?) -> ValidationResult {
        guard let value = value else {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .postalCode)
            return .invalid(code: error.code, message: error.message)
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .postalCode)
            return .invalid(code: error.code, message: error.message)
        }

        // Basic postal code validation - alphanumeric characters and spaces
        let postalCodeRegex = "^[A-Za-z0-9\\s\\-]+$"
        let postalCodePredicate = NSPredicate(format: "SELF MATCHES %@", postalCodeRegex)
        if !postalCodePredicate.evaluate(with: trimmed) || trimmed.count < 3 {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .postalCode)
            return .invalid(code: error.code, message: error.message)
        }

        return .valid
    }
}

/// Validation rule for country codes with Android parity error messaging
internal class BillingCountryCodeRule: ValidationRule {

    func validate(_ value: String?) -> ValidationResult {
        guard let value = value else {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .countryCode)
            return .invalid(code: error.code, message: error.message)
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .countryCode)
            return .invalid(code: error.code, message: error.message)
        }

        // Country code should be 2-3 characters
        if trimmed.count < 2 || trimmed.count > 3 {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .countryCode)
            return .invalid(code: error.code, message: error.message)
        }

        return .valid
    }
}
