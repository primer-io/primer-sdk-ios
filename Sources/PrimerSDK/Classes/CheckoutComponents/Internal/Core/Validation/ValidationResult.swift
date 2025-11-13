//
//  ValidationResult.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

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

    /// Creates a failed validation result using ValidationError with automatic error message resolution
    public static func invalid(error: ValidationError) -> ValidationResult {
        // Attempt to resolve the error message through ErrorMessageResolver
        let resolvedMessage = ErrorMessageResolver.resolveErrorMessage(for: error) ?? error.message

        return ValidationResult(isValid: false, errorCode: error.code, errorMessage: resolvedMessage)
    }

    /// Converts the validation result to a ValidationError (nil if valid)
    public var toValidationError: ValidationError? {
        guard !isValid, let code = errorCode, let message = errorMessage else {
            return nil
        }
        return ValidationError(code: code, message: message)
    }
}
