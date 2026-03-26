//
//  MockValidateInputInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockValidateInputInteractor: ValidateInputInteractor {

    var validationResults: [PrimerInputElementType: ValidationResult] = [:]

    func validate(value: String, type: PrimerInputElementType) async -> ValidationResult {
        validationResults[type] ?? ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
    }

    func validateMultiple(fields: [PrimerInputElementType: String]) async -> [PrimerInputElementType: ValidationResult] {
        var results: [PrimerInputElementType: ValidationResult] = [:]
        for (type, _) in fields {
            results[type] = validationResults[type] ?? ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
        }
        return results
    }

    func setValidResult(for type: PrimerInputElementType) {
        validationResults[type] = ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
    }

    func setInvalidResult(for type: PrimerInputElementType, message: String, code: String = TestData.ErrorCodes.invalid) {
        validationResults[type] = ValidationResult(isValid: false, errorCode: code, errorMessage: message)
    }
}
