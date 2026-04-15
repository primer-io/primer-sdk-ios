//
//  DefaultCardFormScope+Validation.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
extension DefaultCardFormScope {

  /// Updates the validation state for a specific field using a KeyPath.
  ///
  /// Required when using custom field components via `InputFieldConfig(component:)`.
  /// The SDK uses this to track which fields are valid and determine overall form validity.
  ///
  /// ```swift
  /// scope.updateValidationState(\.cvv, isValid: true)
  /// scope.updateValidationState(\.cardNumber, isValid: false)
  /// ```
  public func updateValidationState(_ field: WritableKeyPath<FieldValidationStates, Bool>, isValid: Bool) {
    fieldValidationStates[keyPath: field] = isValid
    updateFieldValidationState()
  }

  public func updateValidationStateIfNeeded(for field: PrimerInputElementType, isValid: Bool) {
    guard let keyPath = field.validationKeyPath else { return }
    updateValidationState(keyPath, isValid: isValid)
  }
}

// MARK: - PrimerInputElementType to FieldValidationStates KeyPath Mapping

private extension PrimerInputElementType {
  var validationKeyPath: WritableKeyPath<FieldValidationStates, Bool>? {
    switch self {
    case .cardNumber: \.cardNumber
    case .cvv: \.cvv
    case .expiryDate: \.expiry
    case .cardholderName: \.cardholderName
    case .email: \.email
    case .firstName: \.firstName
    case .lastName: \.lastName
    case .addressLine1: \.addressLine1
    case .addressLine2: \.addressLine2
    case .city: \.city
    case .state: \.state
    case .postalCode: \.postalCode
    case .countryCode: \.countryCode
    case .phoneNumber: \.phoneNumber
    case .retailer, .otp, .unknown, .all: nil
    }
  }
}
