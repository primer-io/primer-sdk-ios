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

        // Check if empty - use Android-matching error structure
        if cleanedNumber.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .cardNumber)
            return .invalid(code: error.code, message: error.message)
        }

        // Check if all digits - use Android-matching error structure
        if !cleanedNumber.allSatisfy({ $0.isNumber }) {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .cardNumber)
            return .invalid(code: error.code, message: error.message)
        }

        // Check length (13-19 digits) - use Android-matching error structure
        if cleanedNumber.count < 13 || cleanedNumber.count > 19 {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .cardNumber)
            return .invalid(code: error.code, message: error.message)
        }

        // Luhn algorithm validation - use Android-matching error structure
        if !isValidLuhn(cleanedNumber) {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .cardNumber)
            return .invalid(code: error.code, message: error.message)
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
        // Check if empty - use Android-matching error structure
        if value.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .cvv)
            return .invalid(code: error.code, message: error.message)
        }

        // Check if all digits - use Android-matching error structure
        if !value.allSatisfy({ $0.isNumber }) {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .cvv)
            return .invalid(code: error.code, message: error.message)
        }

        // Check length based on card network - use Android-matching error structure
        let expectedLength = cardNetwork?.rawValue == "AMEX" ? 4 : 3
        if value.count != expectedLength {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .cvv)
            return .invalid(code: error.code, message: error.message)
        }

        return .valid
    }
}

/// Validation rule for cardholder names.
internal class CardholderNameRule: ValidationRule {

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if empty - use Android-matching error structure
        if trimmedValue.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .cardholderName)
            return .invalid(code: error.code, message: error.message)
        }

        // Check minimum length - use Android-matching error structure with specific length message
        if trimmedValue.count < 2 {
            // Use the specific cardholder name length error from Android parity strings
            let error = ValidationError(
                inputElementType: .cardholderName,
                errorId: "cardholder_name_length",
                fieldNameKey: "cardholder_name_field",
                errorMessageKey: "form_error_card_holder_name_length",
                errorFormatKey: nil,
                code: "invalid-cardholder-name-length",
                message: CheckoutComponentsStrings.formErrorCardHolderNameLength
            )
            return .invalid(code: error.code, message: error.message)
        }

        // Check for valid characters - use Android-matching error structure
        let allowedCharacters = CharacterSet.letters.union(.whitespaces).union(CharacterSet(charactersIn: "-'"))
        if !trimmedValue.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .cardholderName)
            return .invalid(code: error.code, message: error.message)
        }

        return .valid
    }
}
