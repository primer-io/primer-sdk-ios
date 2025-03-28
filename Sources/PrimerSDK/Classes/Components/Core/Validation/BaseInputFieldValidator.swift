//
//  BaseInputFieldValidator.swift
//
//
//  Created by Boris on 26.3.25..
//

import Foundation

/// Base validator that handles common validation timing behavior
class BaseInputFieldValidator<T> {
    /// The validation service used for actual validation rules
    let validationService: ValidationService

    /// Callback when validation state changes (valid/invalid)
    let onValidationChange: ((Bool) -> Void)?

    /// Callback when error message changes
    let onErrorMessageChange: ((String?) -> Void)?

    init(
        validationService: ValidationService,
        onValidationChange: ((Bool) -> Void)? = nil,
        onErrorMessageChange: ((String?) -> Void)? = nil
    ) {
        self.validationService = validationService
        self.onValidationChange = onValidationChange
        self.onErrorMessageChange = onErrorMessageChange
    }

    /// Called when field begins editing - typically clears errors
    func handleDidBeginEditing() {
        // Clear error message when user starts editing
        onErrorMessageChange?(nil)
    }

    /// Called during typing - uses lightweight validation
    func handleTextChange(input: T) {
        let result = validateWhileTyping(input)

        // During typing, update validation state but don't show error messages
        onValidationChange?(result.isValid)

        // Optionally show errors during typing if explicitly provided
        if !result.isValid && result.errorMessage != nil {
            onErrorMessageChange?(result.errorMessage)
        }
    }

    /// Called when field loses focus - uses full validation
    func handleDidEndEditing(input: T) {
        let result = validateOnBlur(input)

        // When focus lost, update validation state and show error messages
        onValidationChange?(result.isValid)
        onErrorMessageChange?(result.errorMessage)
    }

    // Methods to be overridden by subclasses

    /// Lighter validation during typing
    func validateWhileTyping(_ input: T) -> ValidationResult {
        return .valid // Default implementation
    }

    /// Complete validation when field loses focus
    func validateOnBlur(_ input: T) -> ValidationResult {
        return .valid // Default implementation
    }
}
