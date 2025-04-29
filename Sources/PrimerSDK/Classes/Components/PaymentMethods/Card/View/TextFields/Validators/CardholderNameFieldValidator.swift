//
//  CardholderNameFieldValidator.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

import Foundation

public class CardholderNameFieldValidator: FieldValidator {
    private let validationService: ValidationService
    public init(validationService: ValidationService) {
        self.validationService = validationService
    }
    public func validateWhileTyping(_ input: String) -> ValidationResult {
        return input.trimmingCharacters(in: .whitespaces).count >= 1 ? .valid : .valid
    }
    public func validateOnCommit(_ input: String) -> ValidationResult {
        return validationService.validateCardholderName(input)
    }
}
