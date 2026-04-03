//
//  MockValidationService.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if DEBUG
  import SwiftUI

  /// Preview implementation of ValidationService for SwiftUI previews
  /// Configurable to return either valid or invalid results for testing different UI states
  @available(iOS 15.0, *)
  final class PreviewValidationService: ValidationService {

    // MARK: - Configuration Properties

    private let shouldFailValidation: Bool
    private let errorMessage: String

    // MARK: - Initialization

    /// Creates a mock validation service for previews
    /// - Parameters:
    ///   - shouldFailValidation: Whether validation should fail (default: false)
    ///   - errorMessage: Error message to return when validation fails (default: "Please enter a valid value")
    init(
      shouldFailValidation: Bool = false, errorMessage: String = "Please enter a valid value"
    ) {
      self.shouldFailValidation = shouldFailValidation
      self.errorMessage = errorMessage
    }

    // MARK: - ValidationService Protocol Implementation

    func validateCardNumber(_ number: String) -> ValidationResult {
      if shouldFailValidation {
        return ValidationResult(
          isValid: false, errorCode: "validation_error", errorMessage: errorMessage)
      }
      return ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
    }

    func validateExpiry(month: String, year: String) -> ValidationResult {
      if shouldFailValidation {
        return ValidationResult(
          isValid: false, errorCode: "validation_error", errorMessage: errorMessage)
      }
      return ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
    }

    func validateCVV(_ cvv: String, cardNetwork: CardNetwork) -> ValidationResult {
      if shouldFailValidation {
        return ValidationResult(
          isValid: false, errorCode: "validation_error", errorMessage: errorMessage)
      }
      return ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
    }

    func validateCardholderName(_ name: String) -> ValidationResult {
      if shouldFailValidation {
        return ValidationResult(
          isValid: false, errorCode: "validation_error", errorMessage: errorMessage)
      }
      return ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
    }

    func validateField(type: PrimerInputElementType, value: String?) -> ValidationResult {
      if shouldFailValidation {
        return ValidationResult(
          isValid: false, errorCode: "validation_error", errorMessage: errorMessage)
      }
      return ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
    }

    func validate<T, R: ValidationRule>(input: T, with rule: R) -> ValidationResult
    where R.Input == T {
      if shouldFailValidation {
        return ValidationResult(
          isValid: false, errorCode: "validation_error", errorMessage: errorMessage)
      }
      return ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
    }

    func validateFormData(_ formData: FormData, configuration: CardFormConfiguration)
      -> [FieldError] {
      []
    }

    func validateFields(_ fieldTypes: [PrimerInputElementType], formData: FormData)
      -> [FieldError] {
      []
    }

    func validateFieldWithStructuredResult(type: PrimerInputElementType, value: String?)
      -> FieldError? {
      nil
    }
  }

#endif  // DEBUG
