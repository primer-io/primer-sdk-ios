//
//  RulesFactory.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Factory for creating validation rules
internal protocol RulesFactory {
    /// Creates a card number validation rule
    /// - Parameter allowedCardNetworks: The allowed card networks for validation (defaults to client session config)
    func createCardNumberRule(allowedCardNetworks: [CardNetwork]?) -> CardNumberRule

    /// Creates an expiry date validation rule
    func createExpiryDateRule() -> ExpiryDateRule

    /// Creates a CVV validation rule for the specified card network
    func createCVVRule(cardNetwork: CardNetwork) -> CVVRule

    /// Creates a cardholder name validation rule
    func createCardholderNameRule() -> CardholderNameRule

    /// Creates an OTP code validation rule
    func createOTPCodeRule(expectedLength: Int) -> OTPCodeRule

    // MARK: - Billing Address Validation Rules

    /// Creates a first name validation rule
    func createFirstNameRule() -> FirstNameRule

    /// Creates a last name validation rule
    func createLastNameRule() -> LastNameRule

    /// Creates an email validation rule
    func createEmailValidationRule() -> EmailValidationRule

    /// Creates a phone number validation rule
    func createPhoneNumberValidationRule() -> PhoneNumberValidationRule

    /// Creates an address field validation rule
    func createAddressFieldRule(inputType: ValidationError.InputElementType, isRequired: Bool) -> AddressFieldRule

    /// Creates a postal code validation rule
    func createBillingPostalCodeRule() -> BillingPostalCodeRule

    /// Creates a country code validation rule
    func createBillingCountryCodeRule() -> BillingCountryCodeRule
}

/// Default implementation of RulesFactory
internal final class DefaultRulesFactory: RulesFactory {

    func createCardNumberRule(allowedCardNetworks: [CardNetwork]? = nil) -> CardNumberRule {
        // Use provided networks or default to allowed networks from client session
        let networks = allowedCardNetworks ?? [CardNetwork].allowedCardNetworks
        return CardNumberRule(allowedCardNetworks: networks)
    }

    func createExpiryDateRule() -> ExpiryDateRule {
        return ExpiryDateRule()
    }

    func createCVVRule(cardNetwork: CardNetwork) -> CVVRule {
        return CVVRule(cardNetwork: cardNetwork)
    }

    func createCardholderNameRule() -> CardholderNameRule {
        return CardholderNameRule()
    }

    func createOTPCodeRule(expectedLength: Int = 6) -> OTPCodeRule {
        return OTPCodeRule(expectedLength: expectedLength)
    }

    // MARK: - Billing Address Validation Rules Implementation

    func createFirstNameRule() -> FirstNameRule {
        return FirstNameRule()
    }

    func createLastNameRule() -> LastNameRule {
        return LastNameRule()
    }

    func createEmailValidationRule() -> EmailValidationRule {
        return EmailValidationRule()
    }

    func createPhoneNumberValidationRule() -> PhoneNumberValidationRule {
        return PhoneNumberValidationRule()
    }

    func createAddressFieldRule(inputType: ValidationError.InputElementType, isRequired: Bool = true) -> AddressFieldRule {
        return AddressFieldRule(inputType: inputType, isRequired: isRequired)
    }

    func createBillingPostalCodeRule() -> BillingPostalCodeRule {
        return BillingPostalCodeRule()
    }

    func createBillingCountryCodeRule() -> BillingCountryCodeRule {
        return BillingCountryCodeRule()
    }
}
