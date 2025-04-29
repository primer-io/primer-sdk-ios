//
//  CVVFieldValidator.swift
//  
//
//  Created by Boris on 29. 4. 2025..
//


import Foundation

public class CVVFieldValidator: FieldValidator {
    private let validationService: ValidationService
    private let cardNetwork: CardNetwork
    public init(validationService: ValidationService, cardNetwork: CardNetwork) {
        self.validationService = validationService
        self.cardNetwork = cardNetwork
    }
    public func validateWhileTyping(_ input: String) -> ValidationResult {
        let fmt = input.filter { $0.isNumber }
        return fmt.count <= (cardNetwork == .amex ? 4 : 3) ? .valid
            : .invalid(code: "invalid-cvv-length", message: "Too many digits")
    }
    public func validateOnCommit(_ input: String) -> ValidationResult {
        return validationService.validateCVV(input.filter { $0.isNumber }, cardNetwork: cardNetwork)
    }
}