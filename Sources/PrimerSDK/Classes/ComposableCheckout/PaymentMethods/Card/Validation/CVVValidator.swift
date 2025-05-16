//
//  CVVValidator.swift
//
//
//  Created by Boris on 27.3.25..
//

import Foundation

/// Validates CVV/security code fields based on card network
class CVVValidator: BaseInputFieldValidator<String> {
    /// The card network that determines expected CVV length
    private let cardNetwork: CardNetwork

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
        }

        return .valid
    }

    override func validateOnBlur(_ input: String) -> ValidationResult {
        if input.isEmpty {
            return .invalid(code: "invalid-cvv", message: "CVV is required")
        }

        // Full validation on blur
        return validationService.validateCVV(input, cardNetwork: cardNetwork)
    }
}
