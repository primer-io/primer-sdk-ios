//
//  BaseInputFieldValidator.swift
//  
//
//  Created by Boris on 26.3.25..
//


/// Base implementation that handles timing of validation events
class BaseInputFieldValidator<T>: ValidationCoordinator {
    typealias InputType = T
    
    let validationService: ValidationService
    let onValidationChange: ((Bool) -> Void)?
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
    
    /// Handle text field beginning edit - typically clears errors
    func handleDidBeginEditing() {
        // Clear error message when user starts editing
        onErrorMessageChange?(nil)
    }
    
    /// Handle text changes during typing
    func handleTextChange(input: T) {
        let result = validateWhileTyping(input)
        
        // During typing, update validation state but don't show error messages
        onValidationChange?(result.isValid)
    }
    
    /// Handle text field ending edit - show full validation
    func handleDidEndEditing(input: T) {
        let result = validateOnBlur(input)
        
        // When focus lost, update validation state and show error messages
        onValidationChange?(result.isValid)
        onErrorMessageChange?(result.errorMessage)
    }
    
    // Default implementations to be overridden by subclasses
    func validateWhileTyping(_ input: T) -> ValidationResult {
        return .valid // Simple default
    }
    
    func validateOnBlur(_ input: T) -> ValidationResult {
        return .valid // Simple default
    }
}