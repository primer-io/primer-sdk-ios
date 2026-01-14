//
//  ValidateInputInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol ValidateInputInteractor {
    func validate(value: String, type: PrimerInputElementType) async -> ValidationResult
    func validateMultiple(fields: [PrimerInputElementType: String]) async -> [PrimerInputElementType: ValidationResult]
}

final class ValidateInputInteractorImpl: ValidateInputInteractor, LogReporter {

    private let validationService: ValidationService

    init(validationService: ValidationService) {
        self.validationService = validationService
    }

    func validate(value: String, type: PrimerInputElementType) async -> ValidationResult {
        logger.debug(message: "Validating \(type.stringValue) field")

        let result = validationService.validateField(type: type, value: value)

        if !result.isValid {
            logger.debug(message: "Validation failed for \(type.stringValue): \(result.errorMessage ?? "Unknown error")")
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
