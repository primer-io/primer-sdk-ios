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
            return .invalid(code: "invalid-card-number", message: "Card number is required")
        }

        // Check if all digits
        if !cleanedNumber.allSatisfy({ $0.isNumber }) {
            return .invalid(code: "invalid-card-number-format", message: "Card number must contain only digits")
        }

        // Check length (13-19 digits)
        if cleanedNumber.count < 13 || cleanedNumber.count > 19 {
            return .invalid(code: "invalid-card-number-length", message: "Invalid card number length")
        }

        // Luhn algorithm validation
        if !isValidLuhn(cleanedNumber) {
            return .invalid(code: "invalid-card-number-luhn", message: "Invalid card number")
        }

        return .valid
    }

    private func isValidLuhn(_ number: String) -> Bool {
        var sum = 0
        let digitStrings = number.reversed().map { String($0) }

        for tuple in digitStrings.enumerated() {
            if let digit = Int(tuple.element) {
                let odd = tuple.offset % 2 == 1

                switch (odd, digit) {
                case (true, 9):
                    sum += 9
                case (true, 0...8):
                    sum += (digit * 2) % 9
                default:
                    sum += digit
                }
            } else {
                return false
            }
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
            return .invalid(code: "invalid-cvv", message: "CVV is required")
        }

        // Check if all digits
        if !value.allSatisfy({ $0.isNumber }) {
            return .invalid(code: "invalid-cvv-format", message: "CVV must contain only digits")
        }

        // Check length based on card network
        let expectedLength = cardNetwork?.rawValue == "AMEX" ? 4 : 3
        if value.count != expectedLength {
            let message = expectedLength == 4 ? "CVV must be 4 digits" : "CVV must be 3 digits"
            return .invalid(code: "invalid-cvv-length", message: message)
        }

        return .valid
    }
}

/// Validation rule for cardholder names.
internal class CardholderNameRule: ValidationRule {

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if empty
        if trimmedValue.isEmpty {
            return .invalid(code: "invalid-cardholder-name", message: "Cardholder name is required")
        }

        // Check minimum length
        if trimmedValue.count < 2 {
            return .invalid(code: "invalid-cardholder-name-length", message: "Name is too short")
        }

        // Check for valid characters (letters, spaces, hyphens, apostrophes)
        let allowedCharacters = CharacterSet.letters.union(.whitespaces).union(CharacterSet(charactersIn: "-'"))
        if !trimmedValue.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) {
            return .invalid(code: "invalid-cardholder-name-format", message: "Name contains invalid characters")
        }

        return .valid
    }
}
