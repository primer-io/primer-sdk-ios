//
//  CardFormFieldScopeInternal.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

struct FieldValidationStates: Equatable {
  var cardNumber: Bool = false
  var cvv: Bool = false
  var expiry: Bool = false
  var cardholderName: Bool = false
  var postalCode: Bool = false
  var countryCode: Bool = false
  var city: Bool = false
  var state: Bool = false
  var addressLine1: Bool = false
  var addressLine2: Bool = false
  var firstName: Bool = false
  var lastName: Bool = false
  var email: Bool = false
  var phoneNumber: Bool = false
  var otp: Bool = false
}

@available(iOS 15.0, *)
@MainActor
protocol CardFormFieldScopeInternal: PrimerCardFormScope {
  var currentState: PrimerCardFormState { get }

  /// Nested country-selection scope (internal).
  var selectCountry: PrimerSelectCountryScope { get }

  func updateValidationState(_ keyPath: WritableKeyPath<FieldValidationStates, Bool>, isValid: Bool)
  func updateValidationStateIfNeeded(for field: PrimerInputElementType, isValid: Bool)
  func performSubmit() async

  /// Auto-detected network from the card number (keystroke/BIN prefix); ignored while the user has
  /// pinned a still-available co-badge network.
  func autoSelectDetectedNetwork(_ network: String)
}
