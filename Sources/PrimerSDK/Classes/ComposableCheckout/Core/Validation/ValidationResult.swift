//
//  ValidationResult.swift
//
//
//  Created by Boris on 26.3.25..
//

import Foundation

/// Represents the result of a validation operation.
public struct ValidationResult {
    /// Whether the validation passed
    public let isValid: Bool

    /// Error code if validation failed (nil if valid)
    public let errorCode: String?

    /// Human-readable error message if validation failed (nil if valid)
    public let errorMessage: String?

    /// Creates a successful validation result
    public static let valid = ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)

    /// Creates a failed validation result with the given error details
    public static func invalid(code: String, message: String) -> ValidationResult {
        return ValidationResult(isValid: false, errorCode: code, errorMessage: message)
    }

    /// Converts the validation result to a ValidationError (nil if valid)
    public var toValidationError: ValidationError? {
        guard !isValid, let code = errorCode, let message = errorMessage else {
            return nil
        }
        return ValidationError(code: code, message: message)
    }
}
