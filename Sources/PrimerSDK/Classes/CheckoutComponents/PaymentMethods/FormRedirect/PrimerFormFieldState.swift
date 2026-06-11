//
//  PrimerFormFieldState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
struct PrimerFormFieldState: Equatable, Identifiable {

  enum FieldType: String, Sendable {
    case otpCode
    case phoneNumber
  }

  enum KeyboardType: Sendable {
    case numberPad
    case phonePad
    case `default`
  }

  let fieldType: FieldType
  let placeholder: String
  let label: String
  let helperText: String?
  let keyboardType: KeyboardType
  let maxLength: Int?
  var value: String
  var isValid: Bool
  var errorMessage: String?
  var countryCodePrefix: String?
  var dialCode: String?

  var id: String { fieldType.rawValue }

  init(
    fieldType: FieldType,
    value: String = "",
    isValid: Bool = false,
    errorMessage: String? = nil,
    placeholder: String,
    label: String,
    helperText: String? = nil,
    keyboardType: KeyboardType = .numberPad,
    maxLength: Int? = nil,
    countryCodePrefix: String? = nil,
    dialCode: String? = nil
  ) {
    self.fieldType = fieldType
    self.value = value
    self.isValid = isValid
    self.errorMessage = errorMessage
    self.placeholder = placeholder
    self.label = label
    self.helperText = helperText
    self.keyboardType = keyboardType
    self.maxLength = maxLength
    self.countryCodePrefix = countryCodePrefix
    self.dialCode = dialCode
  }
}

@available(iOS 15.0, *)
extension PrimerFormFieldState {

  static func blikOtpField() -> PrimerFormFieldState {
    PrimerFormFieldState(
      fieldType: .otpCode,
      placeholder: CheckoutComponentsStrings.blikOtpPlaceholder,
      label: CheckoutComponentsStrings.blikOtpLabel,
      helperText: CheckoutComponentsStrings.blikOtpHelper,
      maxLength: 6
    )
  }

  static func mbwayPhoneField(countryCodePrefix: String, dialCode: String) -> PrimerFormFieldState {
    PrimerFormFieldState(
      fieldType: .phoneNumber,
      placeholder: "",
      label: CheckoutComponentsStrings.phoneNumberLabel,
      countryCodePrefix: countryCodePrefix,
      dialCode: dialCode
    )
  }
}
