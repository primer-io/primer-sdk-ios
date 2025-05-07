//
//  CardNumberFieldValidator.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

import Foundation

public class CardNumberFieldValidator: FieldValidator, LogReporter {
    private let validationService: ValidationService

    public init(validationService: ValidationService) {
        self.validationService = validationService
    }

    public func validateWhileTyping(_ input: String) -> ValidationResult {
        if input.isEmpty {
            return .valid // Don't show errors for empty field during typing
        }

        let sanitized = input.filter { $0.isNumber }

        // Get card network for validation rules
        let network = CardNetwork(cardNumber: sanitized)

        // Get valid lengths for this card type
        let validLengths = network.validation?.lengths ?? [16]

        // Check if input length exceeds maximum allowed length for the card type
        if let maxLength = validLengths.max(), sanitized.count > maxLength {
            return .invalid(
                code: "invalid-card-number-length",
                message: "Card number is too long"
            )
        }

        // During typing, only do full validation if we have a complete card number
        if validLengths.contains(sanitized.count) {
            return validationService.validateCardNumber(sanitized)
        }

        // If number is incomplete, just check basic criteria
        // Check if over 13 digits but unknown network
        if sanitized.count >= 13 && network == .unknown {
            return .invalid(
                code: "unsupported-card-type",
                message: "Card type not supported"
            )
        }

        return .valid
    }

    public func validateOnCommit(_ input: String) -> ValidationResult {
        if input.isEmpty {
            return .invalid(code: "invalid-card-number", message: "Card number is required")
        }

        // Full validation with service
        let result = validationService.validateCardNumber(input.filter { $0.isNumber })
        logger.debug(message: "DEBUG: Card Number validation result: \(result.isValid), \(result.errorMessage ?? "nil")")
        return result
    }
}
