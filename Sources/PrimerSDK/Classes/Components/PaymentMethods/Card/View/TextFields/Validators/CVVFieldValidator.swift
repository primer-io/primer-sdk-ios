//
//  CVVFieldValidator.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

import Foundation

public class CVVFieldValidator: FieldValidator, LogReporter {
    private let validationService: ValidationService
    private let cardNetwork: CardNetwork

    public init(validationService: ValidationService, cardNetwork: CardNetwork) {
        self.validationService = validationService
        self.cardNetwork = cardNetwork
    }

    public func validateWhileTyping(_ input: String) -> ValidationResult {
        if input.isEmpty {
            return .valid // Don't show errors for empty field during typing
        }

        // Check that input contains only digits
        if !input.allSatisfy({ $0.isNumber }) {
            return .invalid(code: "invalid-cvv-format", message: "Input should contain only digits")
        }

        // Expected length based on card network
        let expectedLength = cardNetwork == .amex ? 4 : 3

        // Only validate when we have the expected number of digits
        if input.count == expectedLength {
            return validationService.validateCVV(input, cardNetwork: cardNetwork)
        } else if input.count > expectedLength {
            return .invalid(code: "invalid-cvv-length", message: "CVV must be \(expectedLength) digits")
        }

        return .valid
    }

    public func validateOnCommit(_ input: String) -> ValidationResult {
        if input.isEmpty {
            return .invalid(code: "invalid-cvv", message: "CVV is required")
        }

        // Full validation with service
        let result = validationService.validateCVV(input.filter { $0.isNumber }, cardNetwork: cardNetwork)
        logger.debug(message: "DEBUG: CVV validation result: \(result.isValid), \(result.errorMessage ?? "nil")")
        return result
    }
}
