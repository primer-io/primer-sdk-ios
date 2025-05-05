//
//  CardholderNameFieldValidator.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

import Foundation

public class CardholderNameFieldValidator: FieldValidator {
    private let validationService: ValidationService

    public init(validationService: ValidationService) {
        self.validationService = validationService
    }

    public func validateWhileTyping(_ input: String) -> ValidationResult {
        if input.isEmpty {
            return .valid // Don't show errors for empty field during typing
        }

        // Minimal validation during typing - just check length
        if input.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
            return .valid // Don't show error while still typing
        }

        // Only validate if we have a name of reasonable length
        return validationService.validateCardholderName(input)
    }

    public func validateOnCommit(_ input: String) -> ValidationResult {
        if input.isEmpty {
            return .invalid(code: "invalid-cardholder-name", message: "Cardholder name is required")
        }

        // Full validation on blur
        return validationService.validateCardholderName(input)
    }
}
