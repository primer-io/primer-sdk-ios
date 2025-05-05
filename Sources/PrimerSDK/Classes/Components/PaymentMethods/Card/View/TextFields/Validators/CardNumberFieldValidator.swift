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

        // During typing, only mark as invalid if we have enough digits for a potentially complete card
        if sanitized.count >= 13 {
            let network = CardNetwork(cardNumber: sanitized)
            let lengths = network.validation?.lengths ?? [16]

            if lengths.contains(sanitized.count) {
                // Only do full validation if we have a potentially complete number
                return validationService.validateCardNumber(sanitized)
            }
        } else if sanitized.count > 19 {
            return .invalid(code: "invalid-card-number-length", message: "Card number is too long")
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
