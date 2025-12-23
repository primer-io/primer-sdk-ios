//
//  MockValidationService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Mock implementation of ValidationService for testing interactors.
@available(iOS 15.0, *)
final class MockValidationService: ValidationService {

    // MARK: - Call Tracking

    var validateFieldCallCount = 0
    var lastFieldType: PrimerInputElementType?
    var lastFieldValue: String?

    // MARK: - Stubbed Returns

    var stubbedValidationResult = ValidationResult.valid
    var stubbedResultsByType: [PrimerInputElementType: ValidationResult] = [:]

    // MARK: - ValidationService Protocol

    func validateCardNumber(_ number: String) -> ValidationResult {
        validateFieldCallCount += 1
        lastFieldType = .cardNumber
        lastFieldValue = number

        if let result = stubbedResultsByType[.cardNumber] {
            return result
        }
        return stubbedValidationResult
    }

    func validateExpiry(month: String, year: String) -> ValidationResult {
        validateFieldCallCount += 1
        lastFieldType = .expiryDate
        lastFieldValue = "\(month)/\(year)"

        if let result = stubbedResultsByType[.expiryDate] {
            return result
        }
        return stubbedValidationResult
    }

    func validateCVV(_ cvv: String, cardNetwork: CardNetwork) -> ValidationResult {
        validateFieldCallCount += 1
        lastFieldType = .cvv
        lastFieldValue = cvv

        if let result = stubbedResultsByType[.cvv] {
            return result
        }
        return stubbedValidationResult
    }

    func validateCardholderName(_ name: String) -> ValidationResult {
        validateFieldCallCount += 1
        lastFieldType = .cardholderName
        lastFieldValue = name

        if let result = stubbedResultsByType[.cardholderName] {
            return result
        }
        return stubbedValidationResult
    }

    func validateField(type: PrimerInputElementType, value: String?) -> ValidationResult {
        validateFieldCallCount += 1
        lastFieldType = type
        lastFieldValue = value

        // Return type-specific result if configured, otherwise default
        if let result = stubbedResultsByType[type] {
            return result
        }
        return stubbedValidationResult
    }

    func validate<T, R: ValidationRule>(input: T, with rule: R) -> ValidationResult where R.Input == T {
        stubbedValidationResult
    }

    func validateFormData(_ formData: FormData, configuration: CardFormConfiguration) -> [FieldError] {
        // Return empty for tests - we're not testing this path
        []
    }

    func validateFields(_ fieldTypes: [PrimerInputElementType], formData: FormData) -> [FieldError] {
        // Return empty for tests
        []
    }

    func validateFieldWithStructuredResult(type: PrimerInputElementType, value: String?) -> FieldError? {
        let result = validateField(type: type, value: value)
        if result.isValid {
            return nil
        }
        return FieldError(
            fieldType: type,
            message: result.errorMessage ?? "Validation failed",
            errorCode: result.errorCode
        )
    }

    // MARK: - Test Helpers

    func reset() {
        validateFieldCallCount = 0
        lastFieldType = nil
        lastFieldValue = nil
        stubbedValidationResult = ValidationResult.valid
        stubbedResultsByType = [:]
    }

    func stubResult(for type: PrimerInputElementType, result: ValidationResult) {
        stubbedResultsByType[type] = result
    }
}
