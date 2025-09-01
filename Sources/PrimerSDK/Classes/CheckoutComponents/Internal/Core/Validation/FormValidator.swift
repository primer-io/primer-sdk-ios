//
//  FormValidator.swift
//
//
//  Created by Boris on 27.3.25..
//

/// Validates entire forms or individual fields with consistent error formatting
protocol FormValidator {
    /// Validates all fields at once for form submission
    func validateForm(fields: [PrimerInputElementType: String?]) -> [PrimerInputElementType: ValidationError?]

    /// Validates a specific field and returns standard ValidationResult
    func validateField(type: PrimerInputElementType, value: String?) -> ValidationResult

    /// Updates validation context (like card network) for dependent validations
    func updateContext(key: String, value: Any)
}
