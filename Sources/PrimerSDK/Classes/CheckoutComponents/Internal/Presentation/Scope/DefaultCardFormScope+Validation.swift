//
//  DefaultCardFormScope+Validation.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// MARK: - Individual Field Validation Methods

@available(iOS 15.0, *)
extension DefaultCardFormScope {

  public func updateCardNumberValidationState(_ isValid: Bool) {
    fieldValidationStates.cardNumber = isValid
    updateFieldValidationState()
  }

  public func updateCvvValidationState(_ isValid: Bool) {
    fieldValidationStates.cvv = isValid
    updateFieldValidationState()
  }

  public func updateExpiryValidationState(_ isValid: Bool) {
    fieldValidationStates.expiry = isValid
    updateFieldValidationState()
  }

  public func updateCardholderNameValidationState(_ isValid: Bool) {
    fieldValidationStates.cardholderName = isValid
    updateFieldValidationState()
  }

  public func updatePostalCodeValidationState(_ isValid: Bool) {
    fieldValidationStates.postalCode = isValid
    updateFieldValidationState()
  }

  public func updateCityValidationState(_ isValid: Bool) {
    fieldValidationStates.city = isValid
    updateFieldValidationState()
  }

  public func updateStateValidationState(_ isValid: Bool) {
    fieldValidationStates.state = isValid
    updateFieldValidationState()
  }

  public func updateAddressLine1ValidationState(_ isValid: Bool) {
    fieldValidationStates.addressLine1 = isValid
    updateFieldValidationState()
  }

  public func updateAddressLine2ValidationState(_ isValid: Bool) {
    fieldValidationStates.addressLine2 = isValid
    updateFieldValidationState()
  }

  public func updateFirstNameValidationState(_ isValid: Bool) {
    fieldValidationStates.firstName = isValid
    updateFieldValidationState()
  }

  public func updateLastNameValidationState(_ isValid: Bool) {
    fieldValidationStates.lastName = isValid
    updateFieldValidationState()
  }

  public func updateEmailValidationState(_ isValid: Bool) {
    fieldValidationStates.email = isValid
    updateFieldValidationState()
  }

  public func updatePhoneNumberValidationState(_ isValid: Bool) {
    fieldValidationStates.phoneNumber = isValid
    updateFieldValidationState()
  }

  public func updateCountryCodeValidationState(_ isValid: Bool) {
    fieldValidationStates.countryCode = isValid
    updateFieldValidationState()
  }
}
