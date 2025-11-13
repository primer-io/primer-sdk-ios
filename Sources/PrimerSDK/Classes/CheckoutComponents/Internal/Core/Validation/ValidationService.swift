//
//  ValidationService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Service that provides validation for all input field types in the Primer SDK
public protocol ValidationService {
    /// Validates a card number
    func validateCardNumber(_ number: String) -> ValidationResult

    /// Validates an expiry date
    func validateExpiry(month: String, year: String) -> ValidationResult

    /// Validates a CVV
    func validateCVV(_ cvv: String, cardNetwork: CardNetwork) -> ValidationResult

    /// Validates a cardholder name
    func validateCardholderName(_ name: String) -> ValidationResult

    /// Validates any field type with the provided value
    func validateField(type: PrimerInputElementType, value: String?) -> ValidationResult

    /// Validates a field using a specific validation rule
    func validate<T, R: ValidationRule>(input: T, with rule: R) -> ValidationResult where R.Input == T

    // MARK: - Structured State Support

    /// Validates form data using structured state approach
    /// Returns structured field errors for granular error handling
    @available(iOS 15.0, *)
    func validateFormData(_ formData: FormData, configuration: CardFormConfiguration) -> [FieldError]

    /// Validates form data for specific fields only
    /// Useful for partial validation during user input
    @available(iOS 15.0, *)
    func validateFields(_ fieldTypes: [PrimerInputElementType], formData: FormData) -> [FieldError]

    /// Validates a single field and returns structured error
    @available(iOS 15.0, *)
    func validateFieldWithStructuredResult(type: PrimerInputElementType, value: String?) -> FieldError?
}

/**
 * INTERNAL PERFORMANCE OPTIMIZATION: Validation Result Cache
 *
 * High-performance caching system for validation operations to improve
 * real-time form validation performance by avoiding repeated rule execution.
 *
 * ## Cache Strategy:
 * - **Key**: Hash of validation input + rule type + context
 * - **Value**: Pre-computed ValidationResult
 * - **Size Limit**: 200 entries (covers typical form interaction patterns)
 * - **Eviction**: LRU eviction with time-based expiration
 *
 * ## Performance Impact:
 * - **Cache Hit**: O(1) - Direct hash lookup vs O(n) rule execution
 * - **Cache Miss**: O(n) - Original validation + cache store
 * - **Memory**: ~8KB for full cache (200 entries × ~40 bytes each)
 * - **Hit Rate**: Expected 70-85% for typical user typing patterns
 */
final class ValidationResultCache {

    /// Shared cache instance for all validation operations
    static let shared = ValidationResultCache()

    /// Internal cache with automatic cleanup
    private let cache = NSCache<NSString, CachedValidationResult>()

    private init() {
        // Configure cache for optimal validation performance
        cache.countLimit = 200  // Support high-frequency validation calls
        cache.totalCostLimit = 8000  // ~8KB memory limit
    }

    /// Wrapper for cached validation results with timestamp
    private class CachedValidationResult {
        let result: ValidationResult
        let timestamp: Date

        init(result: ValidationResult) {
            self.result = result
            self.timestamp = Date()
        }

        /// Check if cache entry is still valid (30 seconds expiration)
        var isValid: Bool {
            Date().timeIntervalSince(timestamp) < 30
        }
    }

    /// Generates cache key for validation input
    private func cacheKey(for input: String, type: String, context: String = "") -> String {
        return "\(type)_\(input)_\(context)".hash.description
    }

    /// Retrieves cached validation result or performs validation
    func cachedValidation(
        input: String,
        type: String,
        context: String = "",
        validator: () -> ValidationResult
    ) -> ValidationResult {
        let key = cacheKey(for: input, type: type, context: context)
        let cacheKey = key as NSString

        // Check cache first
        if let cached = cache.object(forKey: cacheKey), cached.isValid {
            return cached.result
        }

        // Cache miss or expired - perform validation
        let result = validator()
        cache.setObject(CachedValidationResult(result: result), forKey: cacheKey)

        return result
    }
}

/// Default implementation of the ValidationService
public class DefaultValidationService: ValidationService {
    // MARK: - Properties
    
    private let rulesFactory: RulesFactory
    
    // MARK: - Initialization
    
    init(rulesFactory: RulesFactory = DefaultRulesFactory()) {
        self.rulesFactory = rulesFactory
    }
}

// MARK: - DefaultValidationService Public Methods Extension
extension DefaultValidationService {

    // MARK: - Public Methods

    public func validateCardNumber(_ number: String) -> ValidationResult {
        // INTERNAL OPTIMIZATION: Use caching for card number validation
        return ValidationResultCache.shared.cachedValidation(
            input: number,
            type: "cardNumber"
        ) {
            let rule = rulesFactory.createCardNumberRule(allowedCardNetworks: nil)
            return rule.validate(number)
        }
    }

    public func validateExpiry(month: String, year: String) -> ValidationResult {
        // INTERNAL OPTIMIZATION: Use caching for expiry validation
        let expiryString = "\(month)/\(year)"
        return ValidationResultCache.shared.cachedValidation(
            input: expiryString,
            type: "expiry"
        ) {
            let rule = rulesFactory.createExpiryDateRule()
            let expiryInput = ExpiryDateInput(month: month, year: year)
            return rule.validate(expiryInput)
        }
    }

    public func validateCVV(_ cvv: String, cardNetwork: CardNetwork) -> ValidationResult {
        // INTERNAL OPTIMIZATION: Use caching for CVV validation with card network context
        return ValidationResultCache.shared.cachedValidation(
            input: cvv,
            type: "cvv",
            context: cardNetwork.rawValue
        ) {
            let rule = rulesFactory.createCVVRule(cardNetwork: cardNetwork)
            return rule.validate(cvv)
        }
    }

    public func validateCardholderName(_ name: String) -> ValidationResult {
        // INTERNAL OPTIMIZATION: Use caching for cardholder name validation
        return ValidationResultCache.shared.cachedValidation(
            input: name,
            type: "cardholderName"
        ) {
            let rule = rulesFactory.createCardholderNameRule()
            return rule.validate(name)
        }
    }

    // swiftlint:disable all
    public func validateField(type: PrimerInputElementType, value: String?) -> ValidationResult {
        switch type {
        case .cardNumber:
            guard let value = value else {
                let error = ErrorMessageResolver.createRequiredFieldError(for: .cardNumber)
                return .invalid(error: error)
            }
            return validateCardNumber(value)

        case .expiryDate:
            guard let value = value else {
                let error = ErrorMessageResolver.createRequiredFieldError(for: .expiryDate)
                return .invalid(error: error)
            }
            let components = value.components(separatedBy: "/")
            let month = components.count > 0 ? components[0] : ""
            let year = components.count > 1 ? components[1] : ""
            return validateExpiry(month: month, year: year)

        case .cvv:
            guard let value = value else {
                let error = ErrorMessageResolver.createRequiredFieldError(for: .cvv)
                return .invalid(error: error)
            }
            // Using a default network of .visa when none is provided
            return validateCVV(value, cardNetwork: CardNetwork.visa)

        case .cardholderName:
            guard let value = value else {
                let error = ErrorMessageResolver.createRequiredFieldError(for: .cardholderName)
                return .invalid(error: error)
            }
            return validateCardholderName(value)

        case .postalCode:
            let rule = rulesFactory.createBillingPostalCodeRule()
            return rule.validate(value)

        case .countryCode:
            let rule = rulesFactory.createBillingCountryCodeRule()
            return rule.validate(value)

        case .firstName:
            let rule = rulesFactory.createFirstNameRule()
            return rule.validate(value)

        case .lastName:
            let rule = rulesFactory.createLastNameRule()
            return rule.validate(value)

        case .addressLine1:
            let rule = rulesFactory.createAddressFieldRule(inputType: .addressLine1, isRequired: true)
            return rule.validate(value)

        case .addressLine2:
            // AddressLine2 is typically optional
            let rule = rulesFactory.createAddressFieldRule(inputType: .addressLine2, isRequired: false)
            return rule.validate(value)

        case .city:
            let rule = rulesFactory.createAddressFieldRule(inputType: .city, isRequired: true)
            return rule.validate(value)

        case .state:
            let rule = rulesFactory.createAddressFieldRule(inputType: .state, isRequired: true)
            return rule.validate(value)

        case .phoneNumber:
            let rule = rulesFactory.createPhoneNumberValidationRule()
            return rule.validate(value)

        case .otp:
            guard let value = value else {
                let error = ErrorMessageResolver.createRequiredFieldError(for: .otpCode)
                return .invalid(error: error)
            }
            // Validate OTP is numeric
            let numericRule = CharacterSetRule(
                fieldName: "OTP",
                allowedCharacterSet: CharacterSet(charactersIn: "0123456789"),
                errorCode: "invalid-otp-format"
            )
            return numericRule.validate(value)

        case .retailer, .all:
            // These types don't need validation
            return .valid

        case .unknown:
            // Unknown type always fails validation
            return .invalid(code: "invalid-unknown-field", message: "Unknown field type")
        case .email:
            let rule = rulesFactory.createEmailValidationRule()
            return rule.validate(value)
        }
    }
    // swiftlint:enable all

    public func validate<T, R: ValidationRule>(input: T, with rule: R) -> ValidationResult where R.Input == T {
        return rule.validate(input)
    }

    // MARK: - Structured State Support Implementation

    /// Implementation of validateFormData for structured state
    @available(iOS 15.0, *)
    public func validateFormData(_ formData: FormData, configuration: CardFormConfiguration) -> [FieldError] {
        return validateFields(configuration.allFields, formData: formData)
    }

    /// Implementation of validateFields for partial validation
    @available(iOS 15.0, *)
    public func validateFields(_ fieldTypes: [PrimerInputElementType], formData: FormData) -> [FieldError] {
        var fieldErrors: [FieldError] = []

        for fieldType in fieldTypes {
            let value = formData[fieldType]
            if let error = validateFieldWithStructuredResult(type: fieldType, value: value.isEmpty ? nil : value) {
                fieldErrors.append(error)
            }
        }

        return fieldErrors
    }

    /// Implementation of validateFieldWithStructuredResult
    @available(iOS 15.0, *)
    public func validateFieldWithStructuredResult(type: PrimerInputElementType, value: String?) -> FieldError? {
        let result = validateField(type: type, value: value)

        // Convert ValidationResult to FieldError if invalid
        if !result.isValid, let message = result.errorMessage {
            return FieldError(
                fieldType: type,
                message: message,
                errorCode: result.errorCode
            )
        }

        return nil
    }
}
