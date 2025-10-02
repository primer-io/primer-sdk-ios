//
//  ValidationService.swift
//
//
//  Created by Boris on 26.3.25..
//

import Foundation

/// Service that provides validation for all input field types in the Primer SDK
public protocol ValidationService {
    /// Validates a card number
    func validateCardNumber(_ number: String) -> ValidationResult

    /// Validates an expiry date
    func validateExpiry(month: String, year: String) -> ValidationResult

    /// Validates a CVV
    func validateCVV(_ cvv: String, cardNetwork: CardNetwork) -> ValidationResult

    /// Validates a cardholder name
    func validateCardholderName(_ name: String) -> ValidationResult

    /// Validates any field type with the provided value
    func validateField(type: PrimerInputElementType, value: String?) -> ValidationResult

    /// Validates a field using a specific validation rule
    func validate<T, R: ValidationRule>(input: T, with rule: R) -> ValidationResult where R.Input == T

    // MARK: - Structured State Support

    /// Validates all fields in a form and returns structured errors
    ///
    /// - Parameters:
    ///   - formData: The form data containing field values
    ///   - configuration: Configuration specifying which fields to validate
    /// - Returns: Array of field errors for invalid fields (empty if all valid)
    @available(iOS 15.0, *)
    func validateFormData(_ formData: FormData, configuration: CardFormConfiguration) -> [FieldError]

    /// Validates specific fields in a form (useful for partial validation)
    ///
    /// - Parameters:
    ///   - fieldTypes: Specific fields to validate
    ///   - formData: The form data containing field values
    /// - Returns: Array of field errors for invalid fields (empty if all valid)
    @available(iOS 15.0, *)
    func validateFields(_ fieldTypes: [PrimerInputElementType], formData: FormData) -> [FieldError]

    /// Validates a single field and returns a structured error if invalid
    ///
    /// - Parameters:
    ///   - type: The type of field to validate
    ///   - value: The field value (nil for empty)
    /// - Returns: FieldError if validation fails, nil if valid
    @available(iOS 15.0, *)
    func validateFieldWithStructuredResult(type: PrimerInputElementType, value: String?) -> FieldError?
}

/// Default implementation of the ValidationService
///
/// - Note: ValidationResultCache is in ValidationResultCache.swift
/// - Note: Diagnostics and health check methods are in ValidationServiceDiagnostics.swift
public class DefaultValidationService: ValidationService {
    // MARK: - Properties

    internal let rulesFactory: RulesFactory

    // MARK: - Initialization

    internal init(rulesFactory: RulesFactory = DefaultRulesFactory()) {
        self.rulesFactory = rulesFactory
    }
}

// MARK: - DefaultValidationService Public Methods Extension
extension DefaultValidationService {

    // MARK: - Public Methods

    public func validateCardNumber(_ number: String) -> ValidationResult {
        return ValidationResultCache.shared.cachedValidation(
            input: number,
            type: "cardNumber"
        ) {
            let rule = rulesFactory.createCardNumberRule(allowedCardNetworks: nil)
            return rule.validate(number)
        }
    }

    public func validateExpiry(month: String, year: String) -> ValidationResult {
        let expiryString = "\(month)/\(year)"
        return ValidationResultCache.shared.cachedValidation(
            input: expiryString,
            type: "expiry"
        ) {
            let rule = rulesFactory.createExpiryDateRule()
            let expiryInput = ExpiryDateInput(month: month, year: year)
            return rule.validate(expiryInput)
        }
    }

    public func validateCVV(_ cvv: String, cardNetwork: CardNetwork) -> ValidationResult {
        return ValidationResultCache.shared.cachedValidation(
            input: cvv,
            type: "cvv",
            context: cardNetwork.rawValue
        ) {
            let rule = rulesFactory.createCVVRule(cardNetwork: cardNetwork)
            return rule.validate(cvv)
        }
    }

    public func validateCardholderName(_ name: String) -> ValidationResult {
        return ValidationResultCache.shared.cachedValidation(
            input: name,
            type: "cardholderName"
        ) {
            let rule = rulesFactory.createCardholderNameRule()
            return rule.validate(name)
        }
    }

    // swiftlint:disable all
    public func validateField(type: PrimerInputElementType, value: String?) -> ValidationResult {
        switch type {
        case .cardNumber:
            guard let value = value else {
                let error = ErrorMessageResolver.createRequiredFieldError(for: .cardNumber)
                return .invalid(error: error)
            }
            return validateCardNumber(value)

        case .expiryDate:
            guard let value = value else {
                let error = ErrorMessageResolver.createRequiredFieldError(for: .expiryDate)
                return .invalid(error: error)
            }
            let components = value.components(separatedBy: "/")
            let month = components.count > 0 ? components[0] : ""
            let year = components.count > 1 ? components[1] : ""
            return validateExpiry(month: month, year: year)

        case .cvv:
            guard let value = value else {
                let error = ErrorMessageResolver.createRequiredFieldError(for: .cvv)
                return .invalid(error: error)
            }
            // Default to Visa network when card type is unknown (3-digit CVV)
            return validateCVV(value, cardNetwork: CardNetwork.visa)

        case .cardholderName:
            guard let value = value else {
                let error = ErrorMessageResolver.createRequiredFieldError(for: .cardholderName)
                return .invalid(error: error)
            }
            return validateCardholderName(value)

        case .postalCode:
            let rule = rulesFactory.createBillingPostalCodeRule()
            return rule.validate(value)

        case .countryCode:
            let rule = rulesFactory.createBillingCountryCodeRule()
            return rule.validate(value)

        case .firstName:
            let rule = rulesFactory.createFirstNameRule()
            return rule.validate(value)

        case .lastName:
            let rule = rulesFactory.createLastNameRule()
            return rule.validate(value)

        case .addressLine1:
            let rule = rulesFactory.createAddressFieldRule(inputType: .addressLine1, isRequired: true)
            return rule.validate(value)

        case .addressLine2:
            // Address line 2 is optional (apartment, suite, etc.)
            let rule = rulesFactory.createAddressFieldRule(inputType: .addressLine2, isRequired: false)
            return rule.validate(value)

        case .city:
            let rule = rulesFactory.createAddressFieldRule(inputType: .city, isRequired: true)
            return rule.validate(value)

        case .state:
            let rule = rulesFactory.createAddressFieldRule(inputType: .state, isRequired: true)
            return rule.validate(value)

        case .phoneNumber:
            let rule = rulesFactory.createPhoneNumberValidationRule()
            return rule.validate(value)

        case .otp:
            guard let value = value else {
                let error = ErrorMessageResolver.createRequiredFieldError(for: .otpCode)
                return .invalid(error: error)
            }
            // OTP must be numeric only
            let numericRule = CharacterSetRule(
                fieldName: "OTP",
                allowedCharacterSet: CharacterSet(charactersIn: "0123456789"),
                errorCode: "invalid-otp-format"
            )
            return numericRule.validate(value)

        case .retailer, .all:
            // Special field types that don't require validation
            return .valid

        case .unknown:
            // Reject unknown field types
            return .invalid(code: "invalid-unknown-field", message: "Unknown field type")
        case .email:
            let rule = rulesFactory.createEmailValidationRule()
            return rule.validate(value)
        }
    }
    // swiftlint:enable all

    public func validate<T, R: ValidationRule>(input: T, with rule: R) -> ValidationResult where R.Input == T {
        return rule.validate(input)
    }

    // MARK: - Structured State Support Implementation

    @available(iOS 15.0, *)
    public func validateFormData(_ formData: FormData, configuration: CardFormConfiguration) -> [FieldError] {
        return validateFields(configuration.allFields, formData: formData)
    }

    @available(iOS 15.0, *)
    public func validateFields(_ fieldTypes: [PrimerInputElementType], formData: FormData) -> [FieldError] {
        var fieldErrors: [FieldError] = []

        for fieldType in fieldTypes {
            let value = formData[fieldType]
            if let error = validateFieldWithStructuredResult(type: fieldType, value: value.isEmpty ? nil : value) {
                fieldErrors.append(error)
            }
        }

        return fieldErrors
    }

    @available(iOS 15.0, *)
    public func validateFieldWithStructuredResult(type: PrimerInputElementType, value: String?) -> FieldError? {
        let result = validateField(type: type, value: value)

        // Convert ValidationResult to FieldError for structured state support
        if !result.isValid, let message = result.errorMessage {
            return FieldError(
                fieldType: type,
                message: message,
                errorCode: result.errorCode
            )
        }

        return nil
    }
}
