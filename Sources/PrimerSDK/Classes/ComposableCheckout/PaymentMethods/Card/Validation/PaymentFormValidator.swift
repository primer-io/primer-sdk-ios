//
//  PaymentFormValidator.swift
//
//
//  Created by Boris on 27.3.25..
//

import Foundation

/// Implementation that handles both card fields and billing address validation
class CardFormValidator: FormValidator, LogReporter {
    private let validationService: ValidationService

    // Current card network for CVV validation
    private var currentCardNetwork: CardNetwork = .unknown

    init(validationService: ValidationService) {
        self.validationService = validationService
    }

    func validateForm(fields: [PrimerInputElementType: String?]) -> [PrimerInputElementType: ValidationError?] {
        var results: [PrimerInputElementType: ValidationError?] = [:]

        for (type, value) in fields {
            let result = validateField(type: type, value: value)
            results[type] = result.toValidationError
        }

        return results
    }

    func validateField(type: PrimerInputElementType, value: String?) -> ValidationResult {
        // Log the validation input to help debug
        logger.debug(message: "Validating field \(type.stringValue) with value: \(value?.isEmpty == true ? "[empty]" : (value == nil ? "[nil]" : "[filled]"))")

        guard let value = value else {
            // Handle nil values with appropriate error messages
            let message = errorMessageFor(fieldType: type, errorType: .required)
            return .invalid(code: "required-\(type.simpleIdentifier)", message: message)
        }

        // Check for empty strings and treat them as missing values for required fields
        if value.isEmpty {
            let message = errorMessageFor(fieldType: type, errorType: .required)
            return .invalid(code: "required-\(type.simpleIdentifier)", message: message)
        }

        // Validate based on field type
        switch type {
        // Card fields
        case .cardNumber:
            return validationService.validateCardNumber(value)
        case .cvv:
            return validationService.validateCVV(value, cardNetwork: currentCardNetwork)
        case .expiryDate:
            guard let expiryInput = ExpiryDateInput(formattedDate: value) else {
                return .invalid(code: "invalid-expiry-format", message: "Please enter date as MM/YY")
            }
            return validationService.validateExpiry(month: expiryInput.month, year: expiryInput.year)
        case .cardholderName:
            return validationService.validateCardholderName(value)

        // Billing address fields
        case .postalCode, .countryCode, .city, .state, .addressLine1, .addressLine2, .firstName, .lastName:
            if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let message = errorMessageFor(fieldType: type, errorType: .required)
                return .invalid(code: "invalid-\(type.simpleIdentifier)", message: message)
            }
            return .valid

        // Handle other field types
        default:
            return validationService.validateField(type: type, value: value)
        }
    }

    func updateContext(key: String, value: Any) {
        if key == "cardNetwork", let network = value as? CardNetwork {
            currentCardNetwork = network
            logger.debug(message: "Updated card network in form validator to: \(network.displayName)")
        }
    }

    // Helper to generate consistent error messages
    // swiftlint:disable:next cyclomatic_complexity
    private func errorMessageFor(fieldType: PrimerInputElementType, errorType: FieldErrorType) -> String {
        switch (fieldType, errorType) {
        case (.postalCode, .required): return "Postal code is required."
        case (.countryCode, .required): return "Country is required."
        case (.city, .required): return "City is required."
        case (.state, .required): return "State is required."
        case (.addressLine1, .required): return "Address line 1 is required."
        case (.firstName, .required): return "First name is required."
        case (.lastName, .required): return "Last name is required."
        case (.cardNumber, .required): return "Card number is required."
        case (.expiryDate, .required): return "Expiry date is required."
        case (.cvv, .required): return "CVV is required."
        case (.cardholderName, .required): return "Cardholder name is required."
        default: return "This field is required."
        }
    }

    // Field error types for message generation
    private enum FieldErrorType {
        case required
        case invalid
        case tooShort
        case tooLong
    }
}
