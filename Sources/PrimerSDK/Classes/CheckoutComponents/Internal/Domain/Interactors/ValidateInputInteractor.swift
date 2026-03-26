//
//  ValidateInputInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol ValidateInputInteractor {
  func validate(value: String, type: PrimerInputElementType) async -> ValidationResult
  func validateMultiple(fields: [PrimerInputElementType: String]) async -> [PrimerInputElementType:
    ValidationResult]
}

final class ValidateInputInteractorImpl: ValidateInputInteractor, LogReporter {

  private let validationService: ValidationService

  init(validationService: ValidationService) {
    self.validationService = validationService
  }

  func validate(value: String, type: PrimerInputElementType) async -> ValidationResult {
    let result = validationService.validateField(type: type, value: value)
    if !result.isValid {
      logger.debug(
        message: "Validation failed for \(type.stringValue): \(result.errorMessage ?? "Unknown error")")
    }
    return result
  }

  func validateMultiple(fields: [PrimerInputElementType: String]) async -> [PrimerInputElementType:
    ValidationResult] {
    var results: [PrimerInputElementType: ValidationResult] = [:]
    for (type, value) in fields {
      results[type] = await validate(value: value, type: type)
    }
    return results
  }
}
