//
//  MockValidationService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if DEBUG
    import SwiftUI

    /// Mock implementation of ValidationService for SwiftUI previews
    /// Configurable to return either valid or invalid results for testing different UI states
    @available(iOS 15.0, *)
    public class MockValidationService: ValidationService {
        // MARK: - Configuration Properties

        private let shouldFailValidation: Bool
        private let errorMessage: String

        // MARK: - Initialization

        /// Creates a mock validation service for previews
        /// - Parameters:
        ///   - shouldFailValidation: Whether validation should fail (default: false)
        ///   - errorMessage: Error message to return when validation fails (default: "Please enter a valid value")
        public init(shouldFailValidation: Bool = false, errorMessage: String = "Please enter a valid value") {
            self.shouldFailValidation = shouldFailValidation
            self.errorMessage = errorMessage
        }

        // MARK: - ValidationService Protocol Implementation

        public func validateCardNumber(_: String) -> ValidationResult {
            if shouldFailValidation {
                return ValidationResult(isValid: false, errorCode: "validation_error", errorMessage: errorMessage)
            }
            return ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
        }

        public func validateExpiry(month _: String, year _: String) -> ValidationResult {
            if shouldFailValidation {
                return ValidationResult(isValid: false, errorCode: "validation_error", errorMessage: errorMessage)
            }
            return ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
        }

        public func validateCVV(_: String, cardNetwork _: CardNetwork) -> ValidationResult {
            if shouldFailValidation {
                return ValidationResult(isValid: false, errorCode: "validation_error", errorMessage: errorMessage)
            }
            return ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
        }

        public func validateCardholderName(_: String) -> ValidationResult {
            if shouldFailValidation {
                return ValidationResult(isValid: false, errorCode: "validation_error", errorMessage: errorMessage)
            }
            return ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
        }

        public func validateField(type _: PrimerInputElementType, value _: String?) -> ValidationResult {
            if shouldFailValidation {
                return ValidationResult(isValid: false, errorCode: "validation_error", errorMessage: errorMessage)
            }
            return ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
        }

        public func validate<T, R: ValidationRule>(input _: T, with _: R) -> ValidationResult where R.Input == T {
            if shouldFailValidation {
                return ValidationResult(isValid: false, errorCode: "validation_error", errorMessage: errorMessage)
            }
            return ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
        }

        public func validateFormData(_: FormData, configuration _: CardFormConfiguration) -> [FieldError] {
            []
        }

        public func validateFields(_: [PrimerInputElementType], formData _: FormData) -> [FieldError] {
            []
        }

        public func validateFieldWithStructuredResult(type _: PrimerInputElementType, value _: String?) -> FieldError? {
            nil
        }
    }

#endif // DEBUG
