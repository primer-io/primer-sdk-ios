//
//  FormValidator.swift
//
//
//  Created by Boris on 27.3.25..
//

/**
 * INTERNAL DOCUMENTATION: Form Validation Coordination Architecture
 * 
 * This protocol defines a comprehensive form validation system that coordinates
 * multi-field validation with context awareness and consistent error handling.
 * 
 * ## Form Validation Strategy:
 * 
 * ### 1. Holistic Form Validation
 * Unlike individual field validators, FormValidator considers:
 * - **Cross-field Dependencies**: CVV validation depends on detected card type
 * - **Form-level Logic**: All fields must be valid for successful submission
 * - **Context Awareness**: Validation rules adapt based on dynamic context
 * 
 * ### 2. Validation Modes
 * ```
 * Individual Field → validateField() → Real-time feedback
 * Complete Form → validateForm() → Submission readiness
 * ```
 * 
 * ### 3. Context-Dependent Validation
 * The `updateContext(key:value:)` method enables dynamic validation behavior:
 * - **Card Network Detection**: CVV length varies by card type (Visa=3, Amex=4)
 * - **Regional Rules**: Different validation rules for different countries
 * - **Feature Flags**: Enable/disable validation rules based on configuration
 * 
 * ## Multi-Field Coordination:
 * 
 * ### 1. Dependency Management
 * ```swift
 * // Card number validation affects CVV validation
 * let cardNumber = "4111111111111111" // Visa detected
 * updateContext(key: "cardNetwork", value: CardNetwork.visa)
 * let cvvResult = validateField(type: .cvv, value: "123") // 3-digit validation
 * ```
 * 
 * ### 2. Batch Validation
 * ```swift
 * let fields: [PrimerInputElementType: String?] = [
 *     .cardNumber: "4111111111111111",
 *     .cvv: "123",
 *     .expiryDate: "12/25",
 *     .cardholderName: "John Doe"
 * ]
 * let results = validateForm(fields: fields)
 * ```
 * 
 * ### 3. Result Coordination
 * - **Individual Results**: Immediate field-level feedback via ValidationResult
 * - **Batch Results**: Complete form state via [FieldType: ValidationError?] map
 * - **Error Consistency**: Same validation logic used in both modes
 * 
 * ## Performance Characteristics:
 * 
 * ### 1. Individual Field Validation
 * - **Time Complexity**: O(1) - Single field rule evaluation
 * - **Memory**: O(1) - Single ValidationResult allocation
 * - **Usage**: Real-time typing feedback
 * 
 * ### 2. Form Validation
 * - **Time Complexity**: O(n) where n is number of fields
 * - **Memory**: O(n) - ValidationError allocation per field
 * - **Usage**: Form submission validation
 * 
 * ### 3. Context Updates
 * - **Time Complexity**: O(1) - Dictionary key-value update
 * - **Memory**: O(1) - Context storage overhead
 * - **Usage**: Dynamic rule adaptation
 * 
 * ## Error Handling Strategy:
 * 
 * ### 1. Granular Error Information
 * - **Field-level Errors**: Specific to individual field validation
 * - **Form-level Errors**: Aggregated view of all field states
 * - **Context Errors**: Validation errors due to context dependencies
 * 
 * ### 2. Error Type Consistency
 * Both validation modes produce compatible error representations:
 * - ValidationResult for real-time feedback
 * - ValidationError for detailed error information
 * - Consistent error codes and messages across modes
 * 
 * ## Implementation Benefits:
 * - **Centralized Logic**: Single source of truth for validation rules
 * - **Context Awareness**: Adapts to dynamic form state
 * - **Performance Optimized**: Efficient for both real-time and batch operations
 * - **Error Consistency**: Uniform error handling across validation modes
 * 
 * This architecture enables sophisticated payment form validation that adapts
 * to user input patterns while maintaining optimal performance and error clarity.
 */

/// Validates entire forms or individual fields with consistent error formatting
protocol FormValidator {
    /// Validates all fields at once for form submission
    func validateForm(fields: [PrimerInputElementType: String?]) -> [PrimerInputElementType: ValidationError?]

    /// Validates a specific field and returns standard ValidationResult
    func validateField(type: PrimerInputElementType, value: String?) -> ValidationResult

    /// Updates validation context (like card network) for dependent validations
    func updateContext(key: String, value: Any)
}
