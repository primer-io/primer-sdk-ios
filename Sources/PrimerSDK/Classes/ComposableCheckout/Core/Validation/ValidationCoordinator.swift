//
//  ValidationCoordinator.swift
//
//
//  Created by Boris on 26.3.25..
//

import Foundation

/**
 * INTERNAL DOCUMENTATION: Validation Coordination Strategy
 * 
 * This protocol defines a sophisticated validation timing system that balances
 * user experience with validation accuracy through strategic timing of feedback.
 * 
 * ## Validation Timing Strategy:
 * 
 * ### 1. Two-Phase Validation Approach
 * - **While Typing (`validateWhileTyping`)**: Lenient, non-disruptive validation
 * - **On Blur (`validateOnBlur`)**: Comprehensive validation with full error feedback
 * 
 * ### 2. Timing Rationale
 * ```
 * User Types → Light Validation (No Errors Shown)
 * User Leaves Field → Full Validation (Errors Displayed)
 * ```
 * 
 * This pattern prevents annoying users with premature error messages while
 * still providing real-time positive feedback for valid input.
 * 
 * ### 3. Validation Feedback Coordination
 * - **onValidationChange**: Immediate boolean feedback for UI state changes
 * - **onErrorMessageChange**: Contextual error messages for user guidance
 * 
 * ## Implementation Pattern:
 * 
 * ### 1. During Typing (Non-Intrusive)
 * ```swift
 * func validateWhileTyping(_ input: String) -> ValidationResult {
 *     // Only show positive feedback, suppress premature errors
 *     let result = validationService.validate(input, strict: false)
 *     return result.isValid ? .valid : .valid // Suppress errors while typing
 * }
 * ```
 * 
 * ### 2. On Focus Loss (Comprehensive)
 * ```swift
 * func validateOnBlur(_ input: String) -> ValidationResult {
 *     // Full validation with complete error feedback
 *     return validationService.validate(input, strict: true)
 * }
 * ```
 * 
 * ## User Experience Benefits:
 * - **Reduced Frustration**: No premature error interruptions
 * - **Progressive Disclosure**: Errors appear when user is ready
 * - **Immediate Positive Feedback**: Valid states are confirmed immediately
 * - **Clear Error Context**: Full error messages when user completes field
 * 
 * ## Performance Characteristics:
 * - **Typing Validation**: O(1) - Basic format checks only
 * - **Blur Validation**: O(n) - Complete rule evaluation
 * - **Callback Overhead**: Minimal - Single closure invocation
 * 
 * This coordination strategy ensures optimal balance between validation accuracy
 * and user experience, following modern UX best practices for form validation.
 */

/// Coordinates validation timing and feedback for input fields
protocol ValidationCoordinator {
    associatedtype InputType

    var validationService: ValidationService { get }
    var onValidationChange: ((Bool) -> Void)? { get }
    var onErrorMessageChange: ((String?) -> Void)? { get }

    /// Light validation during typing - typically less strict
    func validateWhileTyping(_ input: InputType) -> ValidationResult

    /// Full validation when field loses focus - typically shows errors
    func validateOnBlur(_ input: InputType) -> ValidationResult
}
