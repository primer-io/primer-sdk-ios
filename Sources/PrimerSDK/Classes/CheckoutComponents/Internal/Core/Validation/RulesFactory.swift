//
//  RulesFactory.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol RulesFactory {
  func createCardNumberRule(allowedCardNetworks: [CardNetwork]?) -> CardNumberRule
  func createExpiryDateRule() -> ExpiryDateRule
  func createCVVRule(cardNetwork: CardNetwork) -> CVVRule
  func createCardholderNameRule() -> CardholderNameRule

  // MARK: - Billing Address Validation Rules

  func createFirstNameRule() -> FirstNameRule
  func createLastNameRule() -> LastNameRule
  func createEmailValidationRule() -> EmailValidationRule
  func createPhoneNumberValidationRule() -> PhoneNumberValidationRule
  func createAddressFieldRule(inputType: ValidationError.InputElementType, isRequired: Bool)
    -> AddressFieldRule
  func createBillingPostalCodeRule() -> BillingPostalCodeRule
  func createBillingCountryCodeRule() -> BillingCountryCodeRule
}

final class DefaultRulesFactory: RulesFactory {

  func createCardNumberRule(allowedCardNetworks: [CardNetwork]? = nil) -> CardNumberRule {
    // Use provided networks or default to allowed networks from client session
    let networks = allowedCardNetworks ?? [CardNetwork].allowedCardNetworks
    return CardNumberRule(allowedCardNetworks: networks)
  }

  func createExpiryDateRule() -> ExpiryDateRule {
    ExpiryDateRule()
  }

  func createCVVRule(cardNetwork: CardNetwork) -> CVVRule {
    CVVRule(cardNetwork: cardNetwork)
  }

  func createCardholderNameRule() -> CardholderNameRule {
    CardholderNameRule()
  }

  // MARK: - Billing Address Validation Rules Implementation

  func createFirstNameRule() -> FirstNameRule {
    FirstNameRule()
  }

  func createLastNameRule() -> LastNameRule {
    LastNameRule()
  }

  func createEmailValidationRule() -> EmailValidationRule {
    EmailValidationRule()
  }

  func createPhoneNumberValidationRule() -> PhoneNumberValidationRule {
    PhoneNumberValidationRule()
  }

  func createAddressFieldRule(inputType: ValidationError.InputElementType, isRequired: Bool = true)
    -> AddressFieldRule
  {
    AddressFieldRule(inputType: inputType, isRequired: isRequired)
  }

  func createBillingPostalCodeRule() -> BillingPostalCodeRule {
    BillingPostalCodeRule()
  }

  func createBillingCountryCodeRule() -> BillingCountryCodeRule {
    BillingCountryCodeRule()
  }
}
