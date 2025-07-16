//
//  representing.swift
//
//
//  Created by Boris on 26.3.25..
//

import Foundation

/**
 * A data class representing a validation error encountered during the payment method data validation process.
 * Updated to match Android SyncValidationError structure for exact parity.
 *
 * @property code A unique identifier for the error.
 * @property message A descriptive message explaining the error.
 * @property inputElementType Android parity: The input element type that failed validation.
 * @property errorId Android parity: Error identifier string.
 * @property fieldNameKey Android parity: Localization key for field name.
 * @property errorMessageKey Android parity: Localization key for error message.
 * @property errorFormatKey Android parity: Localization key for formatted error with placeholder.
 */
public struct ValidationError: Equatable, Hashable, Codable {
    // Core error properties
    let code: String
    let message: String

    // Android parity: Match SyncValidationError structure
    let inputElementType: InputElementType
    let errorId: String
    let fieldNameKey: String?       // Localization key for field name
    let errorMessageKey: String?    // Localization key for error message
    let errorFormatKey: String?     // Localization key for formatted error

    /// Android parity: Input element types matching Android PrimerInputElementType
    public enum InputElementType: String, Codable, CaseIterable {
        case cardNumber = "CARD_NUMBER"
        case cvv = "CVV"
        case expiryDate = "EXPIRY_DATE"
        case cardholderName = "CARDHOLDER_NAME"
        case firstName = "FIRST_NAME"
        case lastName = "LAST_NAME"
        case email = "EMAIL"
        case phoneNumber = "PHONE_NUMBER"
        case addressLine1 = "ADDRESS_LINE_1"
        case addressLine2 = "ADDRESS_LINE_2"
        case city = "CITY"
        case state = "STATE"
        case postalCode = "POSTAL_CODE"
        case countryCode = "COUNTRY_CODE"
        case retailOutlet = "RETAIL_OUTLET"
        case otpCode = "OTP_CODE"
        case unknown = "UNKNOWN"
    }

    /// Full initializer matching Android structure
    public init(
        inputElementType: InputElementType,
        errorId: String,
        fieldNameKey: String? = nil,
        errorMessageKey: String? = nil,
        errorFormatKey: String? = nil,
        code: String,
        message: String
    ) {
        self.inputElementType = inputElementType
        self.errorId = errorId
        self.fieldNameKey = fieldNameKey
        self.errorMessageKey = errorMessageKey
        self.errorFormatKey = errorFormatKey
        self.code = code
        self.message = message
    }

    /// Simplified initializer
    public init(code: String, message: String) {
        self.code = code
        self.message = message
        self.inputElementType = .unknown
        self.errorId = code
        self.fieldNameKey = nil
        self.errorMessageKey = nil
        self.errorFormatKey = nil
    }

    /// Field-based initializer
    internal init(field: String, message: String) {
        self.code = "invalid-\(field)"
        self.message = message
        self.inputElementType = ValidationError.InputElementType.from(field: field)
        self.errorId = "invalid-\(field)"
        self.fieldNameKey = nil
        self.errorMessageKey = nil
        self.errorFormatKey = nil
    }
}

// MARK: - Convenience Extensions

extension ValidationError.InputElementType {
    /// Convert from field string to InputElementType
    static func from(field: String) -> ValidationError.InputElementType {
        switch field.lowercased() {
        case "cardnumber", "card-number", "card_number":
            return .cardNumber
        case "cvv", "cvc", "security_code":
            return .cvv
        case "expirydate", "expiry-date", "expiry_date":
            return .expiryDate
        case "cardholdername", "cardholder-name", "cardholder_name":
            return .cardholderName
        case "firstname", "first-name", "first_name":
            return .firstName
        case "lastname", "last-name", "last_name":
            return .lastName
        case "email":
            return .email
        case "phonenumber", "phone-number", "phone_number":
            return .phoneNumber
        case "countrycode", "country-code", "country_code":
            return .countryCode
        case "postalcode", "postal-code", "postal_code":
            return .postalCode
        default:
            return .unknown
        }
    }

    /// Convert to PrimerInputElementType for interop
    var toPrimerInputElementType: PrimerInputElementType {
        switch self {
        case .cardNumber: return .cardNumber
        case .cvv: return .cvv
        case .expiryDate: return .expiryDate
        case .cardholderName: return .cardholderName
        case .firstName: return .firstName
        case .lastName: return .lastName
        case .email: return .email
        case .phoneNumber: return .phoneNumber
        case .addressLine1: return .addressLine1
        case .addressLine2: return .addressLine2
        case .city: return .city
        case .state: return .state
        case .postalCode: return .postalCode
        case .countryCode: return .countryCode
        case .retailOutlet: return .retailer
        case .otpCode: return .otp
        case .unknown: return .unknown
        }
    }
}
