//
//  MockValidateInputInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Mock implementation of ValidateInputInteractor for testing.
/// Provides configurable validation results and call tracking.
@available(iOS 15.0, *)
final class MockValidateInputInteractor: ValidateInputInteractor {

    // MARK: - Configurable Return Values

    var validationResults: [PrimerInputElementType: ValidationResult] = [:]

    // MARK: - Call Tracking

    private(set) var validateCallCount = 0
    private(set) var validateMultipleCallCount = 0
    private(set) var lastValidatedValue: String?
    private(set) var lastValidatedType: PrimerInputElementType?

    // MARK: - Protocol Implementation

    func validate(value: String, type: PrimerInputElementType) async -> ValidationResult {
        validateCallCount += 1
        lastValidatedValue = value
        lastValidatedType = type
        return validationResults[type] ?? ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
    }

    func validateMultiple(fields: [PrimerInputElementType: String]) async -> [PrimerInputElementType: ValidationResult] {
        validateMultipleCallCount += 1
        var results: [PrimerInputElementType: ValidationResult] = [:]
        for (type, _) in fields {
            results[type] = validationResults[type] ?? ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
        }
        return results
    }

    // MARK: - Test Helpers

    func reset() {
        validateCallCount = 0
        validateMultipleCallCount = 0
        lastValidatedValue = nil
        lastValidatedType = nil
        validationResults = [:]
    }

    func setValidResult(for type: PrimerInputElementType) {
        validationResults[type] = ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
    }

    func setInvalidResult(for type: PrimerInputElementType, message: String, code: String = "INVALID") {
        validationResults[type] = ValidationResult(isValid: false, errorCode: code, errorMessage: message)
    }
}
