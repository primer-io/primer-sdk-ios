//
//  CardValidator.swift
//
//
//  Created by Boris on 26.3.25..
//

/// Protocol for validating card fields
public protocol CardValidator {
    /// Validates a card's fields and returns validation errors for each field
    /// - Parameter cardFields: Map of card field types to their values
    /// - Returns: Map of card field types to their validation errors (nil if valid)
    func getValidatedCardFields(
        cardFields: [PrimerInputElementType: String?]
    ) -> [PrimerInputElementType: ValidationError?]
}

/// Default implementation of CardValidator using the ValidationService
public class DefaultCardValidator: CardValidator {
    private let validationService: ValidationService

    public init(validationService: ValidationService = DefaultValidationService()) {
        self.validationService = validationService
    }

    public func getValidatedCardFields(
        cardFields: [PrimerInputElementType: String?]
    ) -> [PrimerInputElementType: ValidationError?] {
        var result: [PrimerInputElementType: ValidationError?] = [:]

        for (inputType, value) in cardFields {
            let validationResult = validationService.validateField(type: inputType, value: value)
            result[inputType] = validationResult.toValidationError
        }

        return result
    }
}
