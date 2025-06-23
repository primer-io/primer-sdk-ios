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
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "name", message: "Name is required")
            ])
        }
        
        if trimmedValue.count < 2 {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "name", message: "Name is too short")
            ])
        }
        
        // Allow letters, spaces, hyphens, apostrophes
        let allowedCharacters = CharacterSet.letters.union(.whitespaces).union(CharacterSet(charactersIn: "-'"))
        if !trimmedValue.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "name", message: "Name contains invalid characters")
            ])
        }
        
        return ValidationResult(isValid: true, errors: [])
    }
}

/// Validation rule for address lines.
internal class AddressRule: ValidationRule {
    
    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Address line 2 is optional, so empty is valid
        if trimmedValue.isEmpty {
            return ValidationResult(isValid: true, errors: [])
        }
        
        if trimmedValue.count < 3 {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "address", message: "Address is too short")
            ])
        }
        
        if trimmedValue.count > 100 {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "address", message: "Address is too long")
            ])
        }
        
        return ValidationResult(isValid: true, errors: [])
    }
}

/// Validation rule for city names.
internal class CityRule: ValidationRule {
    
    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedValue.isEmpty {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "city", message: "City is required")
            ])
        }
        
        if trimmedValue.count < 2 {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "city", message: "City name is too short")
            ])
        }
        
        // Allow letters, spaces, hyphens, periods
        let allowedCharacters = CharacterSet.letters.union(.whitespaces).union(CharacterSet(charactersIn: "-."))
        if !trimmedValue.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "city", message: "City contains invalid characters")
            ])
        }
        
        return ValidationResult(isValid: true, errors: [])
    }
}

/// Validation rule for state/province.
internal class StateRule: ValidationRule {
    
    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedValue.isEmpty {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "state", message: "State is required")
            ])
        }
        
        // State can be abbreviation (2 chars) or full name
        if trimmedValue.count < 2 {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "state", message: "State is too short")
            ])
        }
        
        return ValidationResult(isValid: true, errors: [])
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
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "postalCode", message: "Postal code is required")
            ])
        }
        
        // Country-specific validation
        switch countryCode {
        case "US":
            // US ZIP code: 5 digits or 5+4 format
            let usPattern = "^\\d{5}(-\\d{4})?$"
            if !trimmedValue.range(of: usPattern, options: .regularExpression) != nil {
                return ValidationResult(isValid: false, errors: [
                    ValidationError(field: "postalCode", message: "Invalid ZIP code format")
                ])
            }
            
        case "GB":
            // UK postcode format
            if trimmedValue.count < 5 || trimmedValue.count > 8 {
                return ValidationResult(isValid: false, errors: [
                    ValidationError(field: "postalCode", message: "Invalid postcode format")
                ])
            }
            
        case "CA":
            // Canadian postal code
            let caPattern = "^[A-Za-z]\\d[A-Za-z] ?\\d[A-Za-z]\\d$"
            if !trimmedValue.range(of: caPattern, options: .regularExpression) != nil {
                return ValidationResult(isValid: false, errors: [
                    ValidationError(field: "postalCode", message: "Invalid postal code format")
                ])
            }
            
        default:
            // Generic validation - allow alphanumeric and spaces
            if trimmedValue.count < 3 || trimmedValue.count > 10 {
                return ValidationResult(isValid: false, errors: [
                    ValidationError(field: "postalCode", message: "Invalid postal code length")
                ])
            }
        }
        
        return ValidationResult(isValid: true, errors: [])
    }
}

/// Validation rule for country codes.
internal class CountryCodeRule: ValidationRule {
    
    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedValue.isEmpty {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "countryCode", message: "Country is required")
            ])
        }
        
        // Should be 2-letter ISO code
        if trimmedValue.count != 2 {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "countryCode", message: "Invalid country code")
            ])
        }
        
        return ValidationResult(isValid: true, errors: [])
    }
}