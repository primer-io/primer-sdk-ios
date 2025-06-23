//
//  CardValidationRules.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Validation rule for card numbers.
internal class CardNumberRule: ValidationRule {
    
    func validate(_ value: String) -> ValidationResult {
        let cleanedNumber = value.replacingOccurrences(of: " ", with: "")
        
        // Check if empty
        if cleanedNumber.isEmpty {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "cardNumber", message: "Card number is required")
            ])
        }
        
        // Check if all digits
        if !cleanedNumber.allSatisfy({ $0.isNumber }) {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "cardNumber", message: "Card number must contain only digits")
            ])
        }
        
        // Check length (13-19 digits)
        if cleanedNumber.count < 13 || cleanedNumber.count > 19 {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "cardNumber", message: "Invalid card number length")
            ])
        }
        
        // Luhn algorithm validation
        if !isValidLuhn(cleanedNumber) {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "cardNumber", message: "Invalid card number")
            ])
        }
        
        return ValidationResult(isValid: true, errors: [])
    }
    
    private func isValidLuhn(_ number: String) -> Bool {
        let digits = number.compactMap { Int(String($0)) }
        let sum = digits.enumerated().reversed().reduce(0) { sum, item in
            let digit = item.offset % 2 == 0 ? item.element : item.element * 2
            return sum + (digit > 9 ? digit - 9 : digit)
        }
        return sum % 10 == 0
    }
}

/// Validation rule for CVV/CVC codes.
internal class CVVRule: ValidationRule {
    
    private let cardNetwork: CardNetwork?
    
    init(cardNetwork: CardNetwork? = nil) {
        self.cardNetwork = cardNetwork
    }
    
    func validate(_ value: String) -> ValidationResult {
        // Check if empty
        if value.isEmpty {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "cvv", message: "CVV is required")
            ])
        }
        
        // Check if all digits
        if !value.allSatisfy({ $0.isNumber }) {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "cvv", message: "CVV must contain only digits")
            ])
        }
        
        // Check length based on card network
        let expectedLength = cardNetwork?.type == "AMEX" ? 4 : 3
        if value.count != expectedLength {
            let message = expectedLength == 4 ? "CVV must be 4 digits" : "CVV must be 3 digits"
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "cvv", message: message)
            ])
        }
        
        return ValidationResult(isValid: true, errors: [])
    }
}

/// Validation rule for expiry dates.
internal class ExpiryDateRule: ValidationRule {
    
    func validate(_ value: String) -> ValidationResult {
        // Remove any formatting
        let cleanedValue = value.replacingOccurrences(of: "/", with: "")
        
        // Check if empty
        if cleanedValue.isEmpty {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "expiryDate", message: "Expiry date is required")
            ])
        }
        
        // Check format (MMYY)
        if cleanedValue.count != 4 || !cleanedValue.allSatisfy({ $0.isNumber }) {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "expiryDate", message: "Invalid expiry date format")
            ])
        }
        
        // Parse month and year
        let month = Int(cleanedValue.prefix(2)) ?? 0
        let year = Int(cleanedValue.suffix(2)) ?? 0
        
        // Validate month
        if month < 1 || month > 12 {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "expiryDate", message: "Invalid month")
            ])
        }
        
        // Check if expired
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        if year < currentYear || (year == currentYear && month < currentMonth) {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "expiryDate", message: "Card has expired")
            ])
        }
        
        return ValidationResult(isValid: true, errors: [])
    }
}

/// Validation rule for cardholder names.
internal class CardholderNameRule: ValidationRule {
    
    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if empty
        if trimmedValue.isEmpty {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "cardholderName", message: "Cardholder name is required")
            ])
        }
        
        // Check minimum length
        if trimmedValue.count < 2 {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "cardholderName", message: "Name is too short")
            ])
        }
        
        // Check for valid characters (letters, spaces, hyphens, apostrophes)
        let allowedCharacters = CharacterSet.letters.union(.whitespaces).union(CharacterSet(charactersIn: "-'"))
        if !trimmedValue.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) {
            return ValidationResult(isValid: false, errors: [
                ValidationError(field: "cardholderName", message: "Name contains invalid characters")
            ])
        }
        
        return ValidationResult(isValid: true, errors: [])
    }
}