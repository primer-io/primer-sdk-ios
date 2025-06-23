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
    func createCardNumberRule() -> CardNumberRule

    /// Creates an expiry date validation rule
    func createExpiryDateRule() -> ExpiryDateRule

    /// Creates a CVV validation rule for the specified card network
    func createCVVRule(cardNetwork: CardNetwork) -> CVVRule

    /// Creates a cardholder name validation rule
    func createCardholderNameRule() -> CardholderNameRule

    /// Creates an OTP code validation rule
    func createOTPCodeRule(expectedLength: Int) -> OTPCodeRule
}

/// Default implementation of RulesFactory
internal final class DefaultRulesFactory: RulesFactory {

    func createCardNumberRule() -> CardNumberRule {
        return CardNumberRule()
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
}
