//
//  ValidateInputInteractor.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Protocol for validating input fields.
internal protocol ValidateInputInteractor {
    /// Validates a single input field value.
    /// - Parameters:
    ///   - value: The value to validate.
    ///   - type: The type of input field.
    /// - Returns: The validation result.
    func validate(value: String, type: PrimerInputElementType) async -> ValidationResult
    
    /// Validates multiple input fields.
    /// - Parameter fields: Dictionary of field types and their values.
    /// - Returns: Dictionary of field types and their validation results.
    func validateMultiple(fields: [PrimerInputElementType: String]) async -> [PrimerInputElementType: ValidationResult]
}

/// Default implementation using the validation service.
internal final class ValidateInputInteractorImpl: ValidateInputInteractor, LogReporter {
    
    private let validationService: ValidationService
    
    init(validationService: ValidationService) {
        self.validationService = validationService
    }
    
    func validate(value: String, type: PrimerInputElementType) async -> ValidationResult {
        logger.debug(message: "Validating \(type.rawValue) field")
        
        guard let rule = type.validationRule else {
            logger.warn(message: "No validation rule for \(type.rawValue)")
            return ValidationResult(isValid: true, errors: [])
        }
        
        let result = await validationService.validate(value: value, using: rule)
        
        if !result.isValid {
            logger.debug(message: "Validation failed for \(type.rawValue): \(result.errors)")
        }
        
        return result
    }
    
    func validateMultiple(fields: [PrimerInputElementType: String]) async -> [PrimerInputElementType: ValidationResult] {
        logger.debug(message: "Validating \(fields.count) fields")
        
        var results: [PrimerInputElementType: ValidationResult] = [:]
        
        for (type, value) in fields {
            results[type] = await validate(value: value, type: type)
        }
        
        let invalidCount = results.values.filter { !$0.isValid }.count
        if invalidCount > 0 {
            logger.debug(message: "\(invalidCount) fields failed validation")
        }
        
        return results
    }
}