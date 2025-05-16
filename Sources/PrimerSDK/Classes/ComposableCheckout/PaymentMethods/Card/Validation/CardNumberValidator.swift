//
//  CardNumberValidator.swift
//
//
//  Created by Boris on 27.3.25..
//

import Foundation

/// Validates card numbers with network detection
class CardNumberValidator: BaseInputFieldValidator<String> {
    /// Callback when card network changes
    var onCardNetworkChange: ((CardNetwork) -> Void)?

    override func validateWhileTyping(_ input: String) -> ValidationResult {
        if input.isEmpty {
            return .valid // Don't show errors for empty field during typing
        }

        let sanitized = input.filter { $0.isNumber }

        // Detect card network and notify listener
        let network = CardNetwork(cardNumber: sanitized)
        if network != .unknown {
            onCardNetworkChange?(network)
        }

        // During typing, only mark as invalid if we have enough digits for a potentially complete card
        if sanitized.count >= 13 {
            let lengths = network.validation?.lengths ?? [16]
            if lengths.contains(sanitized.count) {
                // Only do full validation if we have a potentially complete number
                return validationService.validateCardNumber(sanitized)
            }
        }

        return .valid
    }

    override func validateOnBlur(_ input: String) -> ValidationResult {
        if input.isEmpty {
            return .invalid(code: "invalid-card-number", message: "Card number is required")
        }

        // Full validation on blur
        return validationService.validateCardNumber(input)
    }
}
