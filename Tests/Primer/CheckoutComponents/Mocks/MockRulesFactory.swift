//
//  MockRulesFactory.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Mock implementation of RulesFactory for testing.
/// Allows configuring validation rules to return specific results.
@available(iOS 15.0, *)
final class MockRulesFactory: RulesFactory {

    // MARK: - Call Tracking

    private(set) var createCardNumberRuleCallCount = 0
    private(set) var createExpiryDateRuleCallCount = 0
    private(set) var createCVVRuleCallCount = 0
    private(set) var createCardholderNameRuleCallCount = 0
    private(set) var createFirstNameRuleCallCount = 0
    private(set) var createLastNameRuleCallCount = 0
    private(set) var createEmailRuleCallCount = 0
    private(set) var createPhoneNumberRuleCallCount = 0
    private(set) var createAddressFieldRuleCallCount = 0
    private(set) var createPostalCodeRuleCallCount = 0
    private(set) var createCountryCodeRuleCallCount = 0

    // MARK: - Captured Parameters

    private(set) var lastAllowedCardNetworks: [CardNetwork]?
    private(set) var lastCardNetwork: CardNetwork?
    private(set) var lastInputType: ValidationError.InputElementType?
    private(set) var lastIsRequired: Bool?

    // MARK: - RulesFactory Protocol

    func createCardNumberRule(allowedCardNetworks: [CardNetwork]?) -> CardNumberRule {
        createCardNumberRuleCallCount += 1
        lastAllowedCardNetworks = allowedCardNetworks
        return CardNumberRule(allowedCardNetworks: allowedCardNetworks ?? [])
    }

    func createExpiryDateRule() -> ExpiryDateRule {
        createExpiryDateRuleCallCount += 1
        return ExpiryDateRule()
    }

    func createCVVRule(cardNetwork: CardNetwork) -> CVVRule {
        createCVVRuleCallCount += 1
        lastCardNetwork = cardNetwork
        return CVVRule(cardNetwork: cardNetwork)
    }

    func createCardholderNameRule() -> CardholderNameRule {
        createCardholderNameRuleCallCount += 1
        return CardholderNameRule()
    }

    func createFirstNameRule() -> FirstNameRule {
        createFirstNameRuleCallCount += 1
        return FirstNameRule()
    }

    func createLastNameRule() -> LastNameRule {
        createLastNameRuleCallCount += 1
        return LastNameRule()
    }

    func createEmailValidationRule() -> EmailValidationRule {
        createEmailRuleCallCount += 1
        return EmailValidationRule()
    }

    func createPhoneNumberValidationRule() -> PhoneNumberValidationRule {
        createPhoneNumberRuleCallCount += 1
        return PhoneNumberValidationRule()
    }

    func createAddressFieldRule(inputType: ValidationError.InputElementType, isRequired: Bool) -> AddressFieldRule {
        createAddressFieldRuleCallCount += 1
        lastInputType = inputType
        lastIsRequired = isRequired
        return AddressFieldRule(inputType: inputType, isRequired: isRequired)
    }

    func createBillingPostalCodeRule() -> BillingPostalCodeRule {
        createPostalCodeRuleCallCount += 1
        return BillingPostalCodeRule()
    }

    func createBillingCountryCodeRule() -> BillingCountryCodeRule {
        createCountryCodeRuleCallCount += 1
        return BillingCountryCodeRule()
    }

    // MARK: - Test Helpers

    /// Resets all call counts and captured parameters
    func reset() {
        createCardNumberRuleCallCount = 0
        createExpiryDateRuleCallCount = 0
        createCVVRuleCallCount = 0
        createCardholderNameRuleCallCount = 0
        createFirstNameRuleCallCount = 0
        createLastNameRuleCallCount = 0
        createEmailRuleCallCount = 0
        createPhoneNumberRuleCallCount = 0
        createAddressFieldRuleCallCount = 0
        createPostalCodeRuleCallCount = 0
        createCountryCodeRuleCallCount = 0

        lastAllowedCardNetworks = nil
        lastCardNetwork = nil
        lastInputType = nil
        lastIsRequired = nil
    }
}
