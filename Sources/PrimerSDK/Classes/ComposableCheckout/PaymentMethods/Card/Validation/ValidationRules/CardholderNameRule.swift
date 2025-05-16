//
//  CardholderNameRule.swift
//
//
//  Created by Boris on 26.3.25..
//

import Foundation

/// Validates the cardholder name
public struct CardholderNameRule: ValidationRule {
    public init() {}

    public func validate(_ name: String) -> ValidationResult {
        // Check if empty
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid(
                code: "invalid-cardholder-name",
                message: "Cardholder name is required"
            )
        }

        // Check minimum length
        if name.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
            return .invalid(
                code: "invalid-cardholder-name-length",
                message: "Cardholder name is too short"
            )
        }

        // Check for valid characters
        let allowedCharacterSet = CharacterSet.letters.union(.whitespaces)
        let disallowedChars = CharacterSet(charactersIn: name).subtracting(allowedCharacterSet)

        if !disallowedChars.isEmpty {
            return .invalid(
                code: "invalid-cardholder-name-format",
                message: "Cardholder name contains invalid characters"
            )
        }

        return .valid
    }
}
