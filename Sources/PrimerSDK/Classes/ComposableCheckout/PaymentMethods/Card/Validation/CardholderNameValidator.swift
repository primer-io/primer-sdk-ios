//
//  CardholderNameValidator.swift
//
//
//  Created by Boris on 27.3.25..
//

import Foundation

/// Validates cardholder name fields
class CardholderNameValidator: BaseInputFieldValidator<String> {
    override func validateWhileTyping(_ input: String) -> ValidationResult {
        if input.isEmpty {
            onValidationChange?(true)
            return .valid // Don't show errors for empty field during typing
        }

        // Minimal validation during typing - just check length
        if input.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
            onValidationChange?(true)
            return .valid // Don't show error while still typing
        }

        // Only validate if we have a name of reasonable length
        let result = validationService.validateCardholderName(input)
        onValidationChange?(result.isValid)
        if !result.isValid {
            onErrorMessageChange?(result.errorMessage)
        }
        return result
    }

    override func validateOnBlur(_ input: String) -> ValidationResult {
        if input.isEmpty {
            let result = ValidationResult.invalid(code: "invalid-cardholder-name", message: "Cardholder name is required")
            onValidationChange?(false)
            onErrorMessageChange?(result.errorMessage)
            return result
        }

        // Full validation on blur
        let result = validationService.validateCardholderName(input)
        onValidationChange?(result.isValid)
        onErrorMessageChange?(result.isValid ? nil : result.errorMessage)
        return result
    }
}
