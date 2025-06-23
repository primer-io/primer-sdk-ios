//
//  AddressValidationRules.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Validation rule for name fields (first name, last name).
internal class NameRule: ValidationRule {

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty {
            return .invalid(code: "invalid-name", message: "Name is required")
        }

        if trimmedValue.count < 2 {
            return .invalid(code: "invalid-name-length", message: "Name is too short")
        }

        // Allow letters, spaces, hyphens, apostrophes
        let allowedCharacters = CharacterSet.letters.union(.whitespaces).union(CharacterSet(charactersIn: "-'"))
        if !trimmedValue.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) {
            return .invalid(code: "invalid-name-format", message: "Name contains invalid characters")
        }

        return .valid
    }
}

/// Validation rule for address lines.
internal class AddressRule: ValidationRule {

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        // Address line 2 is optional, so empty is valid
        if trimmedValue.isEmpty {
            return .valid
        }

        if trimmedValue.count < 3 {
            return .invalid(code: "invalid-address-length", message: "Address is too short")
        }

        if trimmedValue.count > 100 {
            return .invalid(code: "invalid-address-length", message: "Address is too long")
        }

        return .valid
    }
}

/// Validation rule for city names.
internal class CityRule: ValidationRule {

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty {
            return .invalid(code: "invalid-city", message: "City is required")
        }

        if trimmedValue.count < 2 {
            return .invalid(code: "invalid-city-length", message: "City name is too short")
        }

        // Allow letters, spaces, hyphens, periods
        let allowedCharacters = CharacterSet.letters.union(.whitespaces).union(CharacterSet(charactersIn: "-."))
        if !trimmedValue.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) {
            return .invalid(code: "invalid-city-format", message: "City contains invalid characters")
        }

        return .valid
    }
}

/// Validation rule for state/province.
internal class StateRule: ValidationRule {

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty {
            return .invalid(code: "invalid-state", message: "State is required")
        }

        // State can be abbreviation (2 chars) or full name
        if trimmedValue.count < 2 {
            return .invalid(code: "invalid-state-length", message: "State is too short")
        }

        return .valid
    }
}

/// Validation rule for postal codes.
internal class PostalCodeRule: ValidationRule {

    private let countryCode: String?

    init(countryCode: String? = nil) {
        self.countryCode = countryCode
    }

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty {
            return .invalid(code: "invalid-postal-code", message: "Postal code is required")
        }

        // Country-specific validation
        switch countryCode {
        case "US":
            // US ZIP code: 5 digits or 5+4 format
            let usPattern = "^\\d{5}(-\\d{4})?$"
            if trimmedValue.range(of: usPattern, options: .regularExpression) == nil {
                return .invalid(code: "invalid-postal-code-format", message: "Invalid ZIP code format")
            }

        case "GB":
            // UK postcode format
            if trimmedValue.count < 5 || trimmedValue.count > 8 {
                return .invalid(code: "invalid-postal-code-format", message: "Invalid postcode format")
            }

        case "CA":
            // Canadian postal code
            let caPattern = "^[A-Za-z]\\d[A-Za-z] ?\\d[A-Za-z]\\d$"
            if trimmedValue.range(of: caPattern, options: .regularExpression) == nil {
                return .invalid(code: "invalid-postal-code-format", message: "Invalid postal code format")
            }

        default:
            // Generic validation - allow alphanumeric and spaces
            if trimmedValue.count < 3 || trimmedValue.count > 10 {
                return .invalid(code: "invalid-postal-code-length", message: "Invalid postal code length")
            }
        }

        return .valid
    }
}

/// Validation rule for country codes.
internal class CountryCodeRule: ValidationRule {

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty {
            return .invalid(code: "invalid-country-code", message: "Country is required")
        }

        // Should be 2-letter ISO code
        if trimmedValue.count != 2 {
            return .invalid(code: "invalid-country-code-format", message: "Invalid country code")
        }

        return .valid
    }
}
