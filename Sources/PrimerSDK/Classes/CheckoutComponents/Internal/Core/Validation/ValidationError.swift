//
//  ValidationError.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/**
 * A data class representing a validation error encountered during the payment method data validation process.
 *
 * @property code A unique identifier for the error.
 * @property message A descriptive message explaining the error.
 * @property inputElementType The input element type that failed validation.
 * @property errorId Error identifier string.
 * @property fieldNameKey Localization key for field name.
 * @property errorMessageKey Localization key for error message.
 * @property errorFormatKey Localization key for formatted error with placeholder.
 */
public struct ValidationError: Equatable, Hashable, Codable {
    // Core error properties
    let code: String
    let message: String

    let inputElementType: InputElementType // ?? Is this needed
    let errorId: String
    let fieldNameKey: String? // Localization key for field name
    let errorMessageKey: String? // Localization key for error message
    let errorFormatKey: String? // Localization key for formatted error

    /// Input element types matching PrimerInputElementType
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
        inputElementType = .unknown
        errorId = code
        fieldNameKey = nil
        errorMessageKey = nil
        errorFormatKey = nil
    }
}

// MARK: - Convenience Extensions
