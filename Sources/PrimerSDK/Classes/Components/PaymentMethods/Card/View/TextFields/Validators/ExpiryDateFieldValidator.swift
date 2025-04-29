//
//  ExpiryDateFieldValidator.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

import Foundation

public class ExpiryDateFieldValidator: FieldValidator {
    private let validationService: ValidationService
    public init(validationService: ValidationService) {
        self.validationService = validationService
    }
    public func validateWhileTyping(_ input: String) -> ValidationResult {
        let fmt = ExpiryDateFormatter().format(input)
        // only basic format
        return fmt.count == 5 ? .valid : .valid
    }
    public func validateOnCommit(_ input: String) -> ValidationResult {
        let parts = input.components(separatedBy: "/")
        guard parts.count == 2 else {
            return .invalid(code: "invalid-expiry-format", message: "Use MM/YY")
        }
        return validationService.validateExpiry(month: parts[0], year: parts[1])
    }
}
