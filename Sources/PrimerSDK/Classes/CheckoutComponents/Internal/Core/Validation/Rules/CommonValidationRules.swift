//
//  CommonValidationRules.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Validation rule for name fields (first name, last name) with proper localization
class NameRule: ValidationRule {
    typealias Input = String

    private let inputElementType: ValidationError.InputElementType

    init(inputElementType: ValidationError.InputElementType = .firstName) {
        self.inputElementType = inputElementType
    }

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: inputElementType)
            return .invalid(error: error)
        }

        if trimmedValue.count < 2 {
            let error = ErrorMessageResolver.createInvalidFieldError(for: inputElementType)
            return .invalid(error: error)
        }

        // Allow letters, spaces, hyphens, apostrophes
        let allowedCharacters = CharacterSet.letters.union(.whitespaces).union(CharacterSet(charactersIn: "-'"))
        if !trimmedValue.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) {
            let error = ErrorMessageResolver.createInvalidFieldError(for: inputElementType)
            return .invalid(error: error)
        }

        return .valid
    }

    func validate(_ value: String?) -> ValidationResult {
        guard let value = value else {
            let error = ErrorMessageResolver.createRequiredFieldError(for: inputElementType)
            return .invalid(error: error)
        }
        return validate(value)
    }
}

/// Validation rule for first names - convenience wrapper
class FirstNameRule: ValidationRule {
    typealias Input = String?
    private let nameRule = NameRule(inputElementType: .firstName)

    func validate(_ value: String?) -> ValidationResult {
        return nameRule.validate(value)
    }
}

/// Validation rule for last names - convenience wrapper
class LastNameRule: ValidationRule {
    typealias Input = String?
    private let nameRule = NameRule(inputElementType: .lastName)

    func validate(_ value: String?) -> ValidationResult {
        return nameRule.validate(value)
    }
}

/// Validation rule for address lines with proper localization
class AddressRule: ValidationRule {
    typealias Input = String
    private let inputElementType: ValidationError.InputElementType
    private let isRequired: Bool

    init(inputElementType: ValidationError.InputElementType = .addressLine1, isRequired: Bool = true) {
        self.inputElementType = inputElementType
        self.isRequired = isRequired
    }

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        // For optional fields (like address line 2), empty is valid
        if trimmedValue.isEmpty {
            if isRequired {
                let error = ErrorMessageResolver.createRequiredFieldError(for: inputElementType)
                return .invalid(error: error)
            } else {
                return .valid
            }
        }

        if trimmedValue.count < 3 {
            let error = ErrorMessageResolver.createInvalidFieldError(for: inputElementType)
            return .invalid(error: error)
        }

        if trimmedValue.count > 100 {
            let error = ErrorMessageResolver.createInvalidFieldError(for: inputElementType)
            return .invalid(error: error)
        }

        return .valid
    }

    func validate(_ value: String?) -> ValidationResult {
        guard let value = value else {
            if isRequired {
                let error = ErrorMessageResolver.createRequiredFieldError(for: inputElementType)
                return .invalid(error: error)
            }
            return .valid
        }
        return validate(value)
    }
}

/// Generic validation rule for address fields - convenience wrapper
class AddressFieldRule: ValidationRule {
    typealias Input = String?
    private let addressRule: AddressRule

    init(inputType: ValidationError.InputElementType, isRequired: Bool = true) {
        self.addressRule = AddressRule(inputElementType: inputType, isRequired: isRequired)
    }

    func validate(_ value: String?) -> ValidationResult {
        return addressRule.validate(value)
    }
}

/// Validation rule for city names with proper localization
class CityRule: ValidationRule {
    typealias Input = String

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .city)
            return .invalid(error: error)
        }

        if trimmedValue.count < 2 {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .city)
            return .invalid(error: error)
        }

        // Allow letters, spaces, hyphens, periods
        let allowedCharacters = CharacterSet.letters.union(.whitespaces).union(CharacterSet(charactersIn: "-."))
        if !trimmedValue.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .city)
            return .invalid(error: error)
        }

        return .valid
    }
}

/// Validation rule for state/province with proper localization
class StateRule: ValidationRule {
    typealias Input = String

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .state)
            return .invalid(error: error)
        }

        // State can be abbreviation (2 chars) or full name
        if trimmedValue.count < 2 {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .state)
            return .invalid(error: error)
        }

        return .valid
    }
}

/// Validation rule for postal codes with proper localization
class PostalCodeRule: ValidationRule {
    typealias Input = String

    private let countryCode: String?

    init(countryCode: String? = nil) {
        self.countryCode = countryCode
    }

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .postalCode)
            return .invalid(error: error)
        }

        // Country-specific validation
        switch countryCode {
        case "US":
            // US ZIP code: 5 digits or 5+4 format
            let usPattern = "^\\d{5}(-\\d{4})?$"
            if trimmedValue.range(of: usPattern, options: .regularExpression) == nil {
                let error = ErrorMessageResolver.createInvalidFieldError(for: .postalCode)
                return .invalid(error: error)
            }

        case "GB":
            // UK postcode format
            if trimmedValue.count < 5 || trimmedValue.count > 8 {
                let error = ErrorMessageResolver.createInvalidFieldError(for: .postalCode)
                return .invalid(error: error)
            }

        case "CA":
            // Canadian postal code
            let caPattern = "^[A-Za-z]\\d[A-Za-z] ?\\d[A-Za-z]\\d$"
            if trimmedValue.range(of: caPattern, options: .regularExpression) == nil {
                let error = ErrorMessageResolver.createInvalidFieldError(for: .postalCode)
                return .invalid(error: error)
            }

        default:
            // Generic validation - allow alphanumeric and spaces
            let postalCodeRegex = "^[A-Za-z0-9\\s\\-]+$"
            let postalCodePredicate = NSPredicate(format: "SELF MATCHES %@", postalCodeRegex)
            if !postalCodePredicate.evaluate(with: trimmedValue) || trimmedValue.count < 3 || trimmedValue.count > 10 {
                let error = ErrorMessageResolver.createInvalidFieldError(for: .postalCode)
                return .invalid(error: error)
            }
        }

        return .valid
    }

    func validate(_ value: String?) -> ValidationResult {
        guard let value = value else {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .postalCode)
            return .invalid(error: error)
        }
        return validate(value)
    }
}

/// Validation rule for postal codes - convenience wrapper
class BillingPostalCodeRule: ValidationRule {
    typealias Input = String?
    private let postalCodeRule = PostalCodeRule()

    func validate(_ value: String?) -> ValidationResult {
        return postalCodeRule.validate(value)
    }
}

/// Validation rule for country codes with proper localization
class CountryCodeRule: ValidationRule {
    typealias Input = String

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .countryCode)
            return .invalid(error: error)
        }

        // Should be 2-letter ISO code or 3-letter code
        if trimmedValue.count < 2 || trimmedValue.count > 3 {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .countryCode)
            return .invalid(error: error)
        }

        return .valid
    }

    func validate(_ value: String?) -> ValidationResult {
        guard let value = value else {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .countryCode)
            return .invalid(error: error)
        }
        return validate(value)
    }
}

/// Validation rule for country codes - convenience wrapper
class BillingCountryCodeRule: ValidationRule {
    typealias Input = String?
    private let countryCodeRule = CountryCodeRule()

    func validate(_ value: String?) -> ValidationResult {
        return countryCodeRule.validate(value)
    }
}

/// Validation rule for email addresses
class EmailRule: ValidationRule {
    typealias Input = String

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .email)
            return .invalid(error: error)
        }

        // Basic email validation - contains @ and at least one dot after @
        if !trimmedValue.contains("@") {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .email)
            return .invalid(error: error)
        }

        // More comprehensive email regex validation
        let emailPattern = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        if trimmedValue.range(of: emailPattern, options: .regularExpression) == nil {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .email)
            return .invalid(error: error)
        }

        return .valid
    }

    func validate(_ value: String?) -> ValidationResult {
        guard let value = value else {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .email)
            return .invalid(error: error)
        }
        return validate(value)
    }
}

/// Validation rule for email addresses - convenience wrapper
class EmailValidationRule: ValidationRule {
    typealias Input = String?
    private let emailRule = EmailRule()

    func validate(_ value: String?) -> ValidationResult {
        return emailRule.validate(value)
    }
}

/// Validation rule for phone numbers
class PhoneNumberRule: ValidationRule {
    typealias Input = String

    func validate(_ value: String) -> ValidationResult {
        let cleanedValue = value.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "+", with: "")

        if cleanedValue.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .phoneNumber)
            return .invalid(error: error)
        }

        // Check if all digits after cleaning
        if !cleanedValue.allSatisfy({ $0.isNumber }) {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .phoneNumber)
            return .invalid(error: error)
        }

        // Check length (between 7 and 15 digits for international)
        if cleanedValue.count < 7 || cleanedValue.count > 15 {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .phoneNumber)
            return .invalid(error: error)
        }

        return .valid
    }

    func validate(_ value: String?) -> ValidationResult {
        guard let value = value else {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .phoneNumber)
            return .invalid(error: error)
        }
        return validate(value)
    }
}

/// Validation rule for phone numbers - convenience wrapper
class PhoneNumberValidationRule: ValidationRule {
    typealias Input = String?
    private let phoneNumberRule = PhoneNumberRule()

    func validate(_ value: String?) -> ValidationResult {
        return phoneNumberRule.validate(value)
    }
}

/// Validation rule for OTP codes
class OTPCodeRule: ValidationRule {
    typealias Input = String

    private let expectedLength: Int

    init(expectedLength: Int = 6) {
        self.expectedLength = expectedLength
    }

    func validate(_ value: String) -> ValidationResult {
        if value.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .otpCode)
            return .invalid(error: error)
        }

        // Check if all digits
        if !value.allSatisfy({ $0.isNumber }) {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .otpCode)
            return .invalid(error: error)
        }

        // Check length
        if value.count != expectedLength {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .otpCode)
            return .invalid(error: error)
        }

        return .valid
    }
}
