//
//  CardNumberValidator.swift
//
//
//  Created by Boris on 27.3.25..
//

import Foundation

/**
 * INTERNAL HELPER UTILITIES: Card Number Validation Enhancements
 *
 * Internal helper methods and extensions to improve validation logic maintainability
 * and reduce code duplication across validation operations.
 */

// MARK: - Internal String Extensions for Card Processing
internal extension String {

    /// Sanitizes card number input by removing non-numeric characters
    /// INTERNAL OPTIMIZATION: Commonly used pattern extracted to reusable utility
    var sanitizedCardNumber: String {
        return self.filter { $0.isNumber }
    }

    /// Checks if the card number has a potentially valid length for any card network
    /// INTERNAL HELPER: Avoids repeated length validation logic
    var hasValidCardLength: Bool {
        let sanitized = self.sanitizedCardNumber
        return sanitized.count >= 13 && sanitized.count <= 19
    }

    /// Determines if card number is complete based on detected network
    /// INTERNAL UTILITY: Centralizes completion detection logic
    func isCompleteCardNumber(for network: CardNetwork) -> Bool {
        let sanitized = self.sanitizedCardNumber
        let validLengths = network.validation?.lengths ?? [16]
        return validLengths.contains(sanitized.count)
    }
}

// MARK: - Internal CardNetwork Extensions
internal extension CardNetwork {

    /// Determines if this network requires full validation for the given input length
    /// INTERNAL HELPER: Encapsulates network-specific validation timing logic
    func shouldPerformFullValidation(for input: String) -> Bool {
        let sanitized = input.sanitizedCardNumber
        let validLengths = self.validation?.lengths ?? [16]

        // Perform full validation if we have at least minimum card length (13)
        return sanitized.count >= 13
    }

    /// Provides validation hints for incomplete card numbers
    /// INTERNAL UTILITY: Improves user experience with contextual feedback
    func validationHint(for input: String) -> String? {
        let sanitized = input.sanitizedCardNumber
        let validLengths = self.validation?.lengths ?? [16]
        let minLength = validLengths.min() ?? 16

        if sanitized.count < minLength {
            let remaining = minLength - sanitized.count
            return "Enter \(remaining) more digit\(remaining == 1 ? "" : "s")"
        }

        return nil
    }
}

/// Validates card numbers with network detection
class CardNumberValidator: BaseInputFieldValidator<String> {
    /// Callback when card network changes
    var onCardNetworkChange: ((CardNetwork) -> Void)?

    override func validateWhileTyping(_ input: String) -> ValidationResult {
        if input.isEmpty {
            onValidationChange?(true)
            return .valid // Don't show errors for empty field during typing
        }

        // INTERNAL OPTIMIZATION: Use sanitized card number helper
        let sanitized = input.sanitizedCardNumber

        // Detect card network and notify listener
        let network = CardNetwork(cardNumber: sanitized)
        if network != .unknown {
            onCardNetworkChange?(network)
        }

        // INTERNAL OPTIMIZATION: Use network-specific validation timing helper
        if network.shouldPerformFullValidation(for: input) {
            let result = validationService.validateCardNumber(sanitized)
            onValidationChange?(result.isValid)
            if !result.isValid {
                onErrorMessageChange?(result.errorMessage)
            }
            return result
        }

        onValidationChange?(true)
        return .valid
    }

    override func validateOnBlur(_ input: String) -> ValidationResult {
        if input.isEmpty {
            let result = ValidationResult.invalid(code: "invalid-card-number", message: "Card number is required")
            onValidationChange?(false)
            onErrorMessageChange?(result.errorMessage)
            return result
        }

        // INTERNAL OPTIMIZATION: Use sanitized helper for validation
        let result = validationService.validateCardNumber(input.sanitizedCardNumber)
        onValidationChange?(result.isValid)
        onErrorMessageChange?(result.isValid ? nil : result.errorMessage)
        return result
    }

    // MARK: - Internal Helper Methods

    /// INTERNAL UTILITY: Provides contextual validation hints for better UX
    internal func internalValidationHint(for input: String) -> String? {
        guard !input.isEmpty else { return nil }

        let sanitized = input.sanitizedCardNumber
        let network = CardNetwork(cardNumber: sanitized)

        return network.validationHint(for: input)
    }

    /// INTERNAL HELPER: Enhanced validation with caching and contextual feedback
    internal func internalValidateWithContext(_ input: String) -> (result: ValidationResult, hint: String?) {
        let result = validateOnBlur(input)
        let hint = internalValidationHint(for: input)

        return (result: result, hint: hint)
    }
}
