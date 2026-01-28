//
//  CardValidationRules.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

class CardNumberRule: ValidationRule {

    private let allowedCardNetworks: Set<CardNetwork>

    init(allowedCardNetworks: [CardNetwork] = [CardNetwork].allowedCardNetworks) {
        self.allowedCardNetworks = Set(allowedCardNetworks)
    }

    func validate(_ value: String) -> ValidationResult {
        let cleanedNumber = value.replacingOccurrences(of: " ", with: "")

        if cleanedNumber.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .cardNumber)
            return .invalid(error: error)
        }

        if !cleanedNumber.allSatisfy(\.isNumber) {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .cardNumber)
            return .invalid(error: error)
        }

        if cleanedNumber.count < 13 || cleanedNumber.count > 19 {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .cardNumber)
            return .invalid(error: error)
        }

        if !isValidLuhn(cleanedNumber) {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .cardNumber)
            return .invalid(error: error)
        }

        // Only validate network for complete card numbers (13+ digits)
        if cleanedNumber.count >= 13 {
            let detectedNetwork = CardNetwork(cardNumber: cleanedNumber)
            if !allowedCardNetworks.contains(detectedNetwork) {
                let error = ValidationError(
                    inputElementType: .cardNumber,
                    errorId: "unsupported_card_type",
                    fieldNameKey: "card_number_field",
                    errorMessageKey: "form_error_card_type_not_supported",
                    errorFormatKey: nil,
                    code: "unsupported-card-type",
                    message: CheckoutComponentsStrings.formErrorCardTypeNotSupported
                )
                return .invalid(error: error)
            }

            if detectedNetwork != .unknown,
               let validation = detectedNetwork.validation,
               !validation.lengths.contains(cleanedNumber.count) {
                let error = ErrorMessageResolver.createInvalidFieldError(for: .cardNumber)
                return .invalid(error: error)
            }
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

class CVVRule: ValidationRule {

    private let cardNetwork: CardNetwork?

    init(cardNetwork: CardNetwork? = nil) {
        self.cardNetwork = cardNetwork
    }

    func validate(_ value: String) -> ValidationResult {
        if value.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .cvv)
            return .invalid(error: error)
        }

        if !value.allSatisfy(\.isNumber) {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .cvv)
            return .invalid(error: error)
        }

        let expectedLength = cardNetwork?.rawValue == "AMEX" ? 4 : 3
        if value.count != expectedLength {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .cvv)
            return .invalid(error: error)
        }

        return .valid
    }
}

class CardholderNameRule: ValidationRule {

    func validate(_ value: String) -> ValidationResult {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty {
            let error = ErrorMessageResolver.createRequiredFieldError(for: .cardholderName)
            return .invalid(error: error)
        }

        if trimmedValue.count < 2 {
            let error = ValidationError(
                inputElementType: .cardholderName,
                errorId: "cardholder_name_length",
                fieldNameKey: "cardholder_name_field",
                errorMessageKey: "form_error_card_holder_name_length",
                errorFormatKey: nil,
                code: "invalid-cardholder-name-length",
                message: CheckoutComponentsStrings.formErrorCardHolderNameLength
            )
            return .invalid(error: error)
        }

        let allowedCharacters = CharacterSet.letters.union(.whitespaces).union(CharacterSet(charactersIn: "-'"))
        if !trimmedValue.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) {
            let error = ErrorMessageResolver.createInvalidFieldError(for: .cardholderName)
            return .invalid(error: error)
        }

        return .valid
    }
}
