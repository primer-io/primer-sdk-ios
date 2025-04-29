//
//  CardNumberFieldValidator.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

import Foundation

public class CardNumberFieldValidator: FieldValidator {
    private let validationService: ValidationService
    public init(validationService: ValidationService) {
        self.validationService = validationService
    }
    public func validateWhileTyping(_ input: String) -> ValidationResult {
        let digits = input.filter { $0.isNumber }
        guard digits.count < 19 else {
            return .invalid(code: "invalid-card-number", message: "Too many digits")
        }
        return .valid
    }
    public func validateOnCommit(_ input: String) -> ValidationResult {
        return validationService.validateCardNumber(input.filter { $0.isNumber })
    }
}
