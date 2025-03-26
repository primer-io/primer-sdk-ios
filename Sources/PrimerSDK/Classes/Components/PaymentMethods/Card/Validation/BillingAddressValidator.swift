//
//  BillingAddressValidator.swift
//
//
//  Created by Boris on 24.3.25..
//

import Foundation

/// Protocol for validating billing address fields
public protocol BillingAddressValidator {
    /// Validates a billing address and returns validation errors for each field
    /// - Parameter billingAddress: Map of input field types to their values
    /// - Returns: Map of input field types to their validation errors (nil if valid)
    func getValidatedBillingAddress(
        billingAddress: [PrimerInputElementType: String?]
    ) -> [PrimerInputElementType: ValidationError?]
}

/// Default implementation of BillingAddressValidator using the ValidationService
public class DefaultBillingAddressValidator: BillingAddressValidator {
    private let validationService: ValidationService

    public init(validationService: ValidationService = DefaultValidationService()) {
        self.validationService = validationService
    }

    public func getValidatedBillingAddress(
        billingAddress: [PrimerInputElementType: String?]
    ) -> [PrimerInputElementType: ValidationError?] {
        var result: [PrimerInputElementType: ValidationError?] = [:]

        for (inputType, value) in billingAddress {
            let validationResult = validationService.validateField(type: inputType, value: value)
            result[inputType] = validationResult.toValidationError
        }

        return result
    }
}
