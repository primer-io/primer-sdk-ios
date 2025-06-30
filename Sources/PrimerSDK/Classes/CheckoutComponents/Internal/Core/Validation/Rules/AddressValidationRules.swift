//
//  AddressValidationRules.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Validation rule for name fields (first name, last name) with proper localization
internal class NameRule: ValidationRule {
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
}

/// Validation rule for address lines with proper localization
internal class AddressRule: ValidationRule {
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
}

/// Validation rule for city names with proper localization
internal class CityRule: ValidationRule {

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
internal class StateRule: ValidationRule {

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
internal class PostalCodeRule: ValidationRule {

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
            if trimmedValue.count < 3 || trimmedValue.count > 10 {
                let error = ErrorMessageResolver.createInvalidFieldError(for: .postalCode)
                return .invalid(error: error)
            }
        }

        return .valid
    }
}

/// Validation rule for country codes with proper localization
internal class CountryCodeRule: ValidationRule {

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .countryCode)
            return .invalid(error: error)
        }

        // Should be 2-letter ISO code
        if trimmedValue.count != 2 {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .countryCode)
            return .invalid(error: error)
        }

        return .valid
    }
}
