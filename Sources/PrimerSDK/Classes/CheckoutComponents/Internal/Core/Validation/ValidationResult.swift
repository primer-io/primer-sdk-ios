//
//  ValidationResult.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

struct ValidationResult {
  let isValid: Bool

  /// Error code if validation failed (nil if valid)
  let errorCode: String?

  /// Human-readable error message if validation failed (nil if valid)
  let errorMessage: String?

  static let valid = ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)

  static func invalid(code: String, message: String) -> ValidationResult {
    ValidationResult(isValid: false, errorCode: code, errorMessage: message)
  }

  /// Creates a failed validation result using ValidationError with automatic error message resolution
  static func invalid(error: ValidationError) -> ValidationResult {
    // Attempt to resolve the error message through ErrorMessageResolver
    let resolvedMessage = ErrorMessageResolver.resolveErrorMessage(for: error) ?? error.message

    return ValidationResult(isValid: false, errorCode: error.code, errorMessage: resolvedMessage)
  }

  /// Converts the validation result to a ValidationError (nil if valid)
  var toValidationError: ValidationError? {
    guard !isValid, let code = errorCode, let message = errorMessage else {
      return nil
    }
    return ValidationError(code: code, message: message)
  }
}
