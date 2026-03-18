//
//  DefaultCardFormScope+Validation.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// MARK: - Field Validation State Update

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
}
