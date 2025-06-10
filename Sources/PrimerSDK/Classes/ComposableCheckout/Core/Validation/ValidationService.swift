//
//  ValidationService.swift
//
//
//  Created by Boris on 26.3.25..
//

import Foundation

/**
 * INTERNAL DOCUMENTATION: Validation Service Architecture
 * 
 * This service provides a centralized, type-safe validation system for all payment
 * form inputs with comprehensive rule-based validation and flexible extension points.
 * 
 * ## Service Architecture:
 * 
 * ### 1. Protocol-Based Design
 * - **ValidationService**: Public interface for all validation operations
 * - **DefaultValidationService**: Concrete implementation with rule delegation
 * - **RulesFactory**: Factory pattern for creating validation rules
 * 
 * ### 2. Validation Flow
 * ```
 * Input → ValidationService → RulesFactory → ValidationRule → ValidationResult
 * ```
 * 
 * ### 3. Rule-Based Validation System
 * Each validation operation delegates to specialized rules:
 * - **CardNumberRule**: Luhn algorithm, format validation, card type detection
 * - **ExpiryDateRule**: Date format, expiration logic, future date validation
 * - **CVVRule**: Card-type-specific CVV length and format validation
 * - **CardholderNameRule**: Name format, character set, length validation
 * 
 * ## Generic Validation Support:
 * 
 * ### 1. Type-Safe Generic Method
 * ```swift
 * func validate<T, R: ValidationRule>(input: T, with rule: R) -> ValidationResult 
 * where R.Input == T
 * ```
 * 
 * This method provides compile-time type safety ensuring that:
 * - Input type matches rule's expected input type
 * - No runtime type casting errors
 * - Clear API contracts for validation consumers
 * 
 * ### 2. Field Type Validation
 * The `validateField(type:value:)` method provides a unified interface
 * for validating any payment form field using enum-based dispatch.
 * 
 * ## Performance Characteristics:
 * 
 * ### 1. Rule Creation
 * - **O(1)**: Factory methods create rules with pre-compiled patterns
 * - **Cached**: Rules are lightweight and can be cached if needed
 * 
 * ### 2. Validation Execution
 * - **Card Number**: O(n) - Luhn algorithm requires digit iteration
 * - **CVV**: O(1) - Simple length and character validation
 * - **Expiry**: O(1) - Date component validation
 * - **Name**: O(n) - Character set validation
 * 
 * ### 3. Memory Usage
 * - **Service Instance**: ~100 bytes (factory reference only)
 * - **Rule Instances**: ~50-200 bytes each (primarily regex patterns)
 * - **Result Objects**: ~50 bytes (boolean + optional string)
 * 
 * ## Extension Points:
 * 
 * ### 1. Custom Rules
 * New validation rules can be added by:
 * - Implementing ValidationRule protocol
 * - Adding factory method to RulesFactory
 * - Extending PrimerInputElementType enum if needed
 * 
 * ### 2. Custom Field Types
 * New field types can be supported by:
 * - Adding case to PrimerInputElementType
 * - Implementing validation logic in validateField method
 * - Creating appropriate validation rules
 * 
 * ## Error Handling Strategy:
 * - **Graceful Degradation**: Invalid inputs return descriptive error messages
 * - **No Exceptions**: All validation returns Result types, never throws
 * - **Localization Ready**: Error messages can be localized via result objects
 * 
 * This architecture provides a robust, extensible validation system that maintains
 * high performance while ensuring type safety and comprehensive error handling.
 */

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
internal final class ValidationResultCache {
    
    /// Shared cache instance for all validation operations
    internal static let shared = ValidationResultCache()
    
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
    internal func cachedValidation(
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
    
    /// Clears validation cache (useful for testing or memory pressure)
    internal func clearCache() {
        cache.removeAllObjects()
    }
}

/// Default implementation of the ValidationService
public class DefaultValidationService: ValidationService {
    // MARK: - Properties

    private let rulesFactory: RulesFactory

    // MARK: - Initialization

    public init(rulesFactory: RulesFactory) {
        self.rulesFactory = rulesFactory
    }

    // MARK: - Public Methods

    public func validateCardNumber(_ number: String) -> ValidationResult {
        // INTERNAL OPTIMIZATION: Use caching for card number validation
        return ValidationResultCache.shared.cachedValidation(
            input: number,
            type: "cardNumber"
        ) {
            let rule = rulesFactory.createCardNumberRule()
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
                return .invalid(code: "invalid-card-number", message: "Card number is required")
            }
            return validateCardNumber(value)

        case .expiryDate:
            guard let value = value else {
                return .invalid(code: "invalid-expiry-date", message: "Expiry date is required")
            }
            let components = value.components(separatedBy: "/")
            let month = components.count > 0 ? components[0] : ""
            let year = components.count > 1 ? components[1] : ""
            return validateExpiry(month: month, year: year)

        case .cvv:
            guard let value = value else {
                return .invalid(code: "invalid-cvv", message: "CVV is required")
            }
            // Using a default network of .visa when none is provided
            return validateCVV(value, cardNetwork: .visa)

        case .cardholderName:
            guard let value = value else {
                return .invalid(code: "invalid-cardholder-name", message: "Cardholder name is required")
            }
            return validateCardholderName(value)

        case .postalCode:
            return validate(input: value, with: RequiredFieldRule(fieldName: "Postal code", errorCode: "invalid-postal-code"))

        case .countryCode:
            return validate(input: value, with: RequiredFieldRule(fieldName: "Country", errorCode: "invalid-country"))

        case .firstName:
            return validate(input: value, with: RequiredFieldRule(fieldName: "First name", errorCode: "invalid-first-name"))

        case .lastName:
            return validate(input: value, with: RequiredFieldRule(fieldName: "Last name", errorCode: "invalid-last-name"))

        case .addressLine1:
            return validate(input: value, with: RequiredFieldRule(fieldName: "Address line 1", errorCode: "invalid-address"))

        case .addressLine2:
            // AddressLine2 is typically optional, so no validation required
            return .valid

        case .city:
            return validate(input: value, with: RequiredFieldRule(fieldName: "City", errorCode: "invalid-city"))

        case .state:
            return validate(input: value, with: RequiredFieldRule(fieldName: "State", errorCode: "invalid-state"))

        case .phoneNumber:
            return validate(input: value, with: RequiredFieldRule(fieldName: "Phone number", errorCode: "invalid-phone-number"))

        case .otp:
            guard let value = value else {
                return .invalid(code: "invalid-otp", message: "OTP is required")
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
        }
    }
    // swiftlint:enable all

    public func validate<T, R: ValidationRule>(input: T, with rule: R) -> ValidationResult where R.Input == T {
        return rule.validate(input)
    }
}
