//
//  ValidationError.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public struct ValidationError: Equatable, Hashable, Codable {
  let code: String
  let message: String

  let inputElementType: InputElementType  // ?? Is this needed
  let errorId: String
  let fieldNameKey: String?  // Localization key for field name
  let errorMessageKey: String?  // Localization key for error message
  let errorFormatKey: String?  // Localization key for formatted error

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

  public init(code: String, message: String) {
    self.code = code
    self.message = message
    self.inputElementType = .unknown
    self.errorId = code
    self.fieldNameKey = nil
    self.errorMessageKey = nil
    self.errorFormatKey = nil
  }
}

// MARK: - Convenience Extensions
