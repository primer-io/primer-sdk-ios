//
//  CVVValidator.swift
//
//
//  Created by Boris on 27.3.25..
//

import Foundation

/**
 * INTERNAL HELPER UTILITIES: CVV Validation Enhancements
 *
 * Internal utilities for CVV validation logic to improve maintainability
 * and provide consistent validation behavior across card networks.
 */

// MARK: - Internal CVV Extensions
internal extension String {

    /// Validates that CVV contains only numeric characters
    /// INTERNAL HELPER: Common validation pattern extracted to reusable utility
    var isValidCVVFormat: Bool {
        return !isEmpty && allSatisfy { $0.isNumber }
    }

    /// Checks if CVV length is appropriate for the given card network
    /// INTERNAL UTILITY: Centralizes network-specific length validation
    func hasValidCVVLength(for network: CardNetwork) -> Bool {
        let expectedLength = network.expectedCVVLength
        return count == expectedLength
    }

    /// Provides CVV completion status for better UX feedback
    /// INTERNAL HELPER: Improves user experience with clear status
    func cvvCompletionStatus(for network: CardNetwork) -> CVVCompletionStatus {
        guard isValidCVVFormat else { return .invalidFormat }

        let expectedLength = network.expectedCVVLength

        if count < expectedLength {
            return .incomplete(remaining: expectedLength - count)
        } else if count == expectedLength {
            return .complete
        } else {
            return .tooLong
        }
    }
}

// MARK: - Internal CardNetwork CVV Extensions
internal extension CardNetwork {

    /// Returns the expected CVV length for this card network
    /// INTERNAL UTILITY: Centralizes CVV length logic
    var expectedCVVLength: Int {
        return self == .amex ? 4 : 3
    }

    /// Provides descriptive name for CVV field based on network
    /// INTERNAL HELPER: Consistent terminology across UI
    var cvvFieldName: String {
        return self == .amex ? "Security Code (4 digits)" : "CVV (3 digits)"
    }
}

// MARK: - Internal CVV Status Enumeration
internal enum CVVCompletionStatus: Equatable {
    case incomplete(remaining: Int)
    case complete
    case tooLong
    case invalidFormat

    /// User-friendly description for current status
    var userDescription: String {
        switch self {
        case .incomplete(let remaining):
            return "Enter \(remaining) more digit\(remaining == 1 ? "" : "s")"
        case .complete:
            return "CVV complete"
        case .tooLong:
            return "CVV too long"
        case .invalidFormat:
            return "CVV must contain only numbers"
        }
    }
}

/// Validates CVV/security code fields based on card network
class CVVValidator: BaseInputFieldValidator<String> {
    /// The card network that determines expected CVV length
    private var cardNetwork: CardNetwork

    init(
        validationService: ValidationService,
        cardNetwork: CardNetwork,
        onValidationChange: ((Bool) -> Void)? = nil,
        onErrorMessageChange: ((String?) -> Void)? = nil
    ) {
        self.cardNetwork = cardNetwork
        super.init(
            validationService: validationService,
            onValidationChange: onValidationChange,
            onErrorMessageChange: onErrorMessageChange
        )
    }

    override func validateWhileTyping(_ input: String) -> ValidationResult {
        if input.isEmpty {
            onValidationChange?(true)
            return .valid // Don't show errors for empty field during typing
        }

        // INTERNAL OPTIMIZATION: Use format validation helper
        if !input.isValidCVVFormat {
            let result = ValidationResult.invalid(code: "invalid-cvv-format", message: "Input should contain only digits")
            onValidationChange?(false)
            onErrorMessageChange?(result.errorMessage)
            return result
        }

        // INTERNAL OPTIMIZATION: Use length validation helper
        if input.hasValidCVVLength(for: cardNetwork) {
            let result = validationService.validateCVV(input, cardNetwork: cardNetwork)
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
            let result = ValidationResult.invalid(code: "invalid-cvv", message: "CVV is required")
            onValidationChange?(false)
            onErrorMessageChange?(result.errorMessage)
            return result
        }

        // Full validation on blur
        let result = validationService.validateCVV(input, cardNetwork: cardNetwork)
        onValidationChange?(result.isValid)
        onErrorMessageChange?(result.isValid ? nil : result.errorMessage)
        return result
    }

    /// Updates the card network for CVV validation
    /// - Parameter network: The new card network
    func updateCardNetwork(_ network: CardNetwork) {
        cardNetwork = network
    }

    // MARK: - Internal Helper Methods

    /// INTERNAL UTILITY: Provides CVV completion status for better UX
    internal func internalCompletionStatus(for input: String) -> CVVCompletionStatus {
        return input.cvvCompletionStatus(for: cardNetwork)
    }

    /// INTERNAL HELPER: Enhanced validation with contextual feedback
    internal func internalValidateWithStatus(_ input: String) -> (result: ValidationResult, status: CVVCompletionStatus) {
        let result = validateOnBlur(input)
        let status = internalCompletionStatus(for: input)

        return (result: result, status: status)
    }

    /// INTERNAL UTILITY: Provides user-friendly field description
    internal func internalFieldDescription() -> String {
        return cardNetwork.cvvFieldName
    }
}
