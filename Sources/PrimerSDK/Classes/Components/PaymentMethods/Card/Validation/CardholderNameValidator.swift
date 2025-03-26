//
//  CardholderNameValidator.swift
//  
//
//  Created by Boris on 27.3.25..
//


class CardholderNameValidator: BaseInputFieldValidator<String> {
    override func validateWhileTyping(_ input: String) -> ValidationResult {
        if input.isEmpty {
            return .valid // Don't show errors for empty field during typing
        }
        
        // Minimal validation during typing - just check length
        if input.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
            return .invalid(code: "invalid-cardholder-name-length", message: nil)
        }
        
        return .valid
    }
    
    override func validateOnBlur(_ input: String) -> ValidationResult {
        // Full validation on blur
        return validationService.validateCardholderName(input)
    }
}