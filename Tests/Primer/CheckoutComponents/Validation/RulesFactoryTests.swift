//
//  RulesFactoryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class RulesFactoryTests: XCTestCase {

    private var sut: DefaultRulesFactory!

    override func setUp() {
        super.setUp()
        sut = DefaultRulesFactory()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Card Number Rule Tests

    func test_createCardNumberRule_returnsCardNumberRule() {
        // When
        let rule = sut.createCardNumberRule(allowedCardNetworks: nil)

        // Then
        XCTAssertNotNil(rule)
        XCTAssertTrue(rule is CardNumberRule)
    }

    func test_createCardNumberRule_withAllowedNetworks_returnsConfiguredRule() {
        // Given
        let allowedNetworks: [CardNetwork] = [.visa, .masterCard]

        // When
        let rule = sut.createCardNumberRule(allowedCardNetworks: allowedNetworks)

        // Then
        XCTAssertNotNil(rule)
        // Verify rule rejects non-allowed network
        let result = rule.validate(TestData.CardNumbers.validAmex)
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Expiry Date Rule Tests

    func test_createExpiryDateRule_returnsExpiryDateRule() {
        // When
        let rule = sut.createExpiryDateRule()

        // Then
        XCTAssertNotNil(rule)
        XCTAssertTrue(rule is ExpiryDateRule)
    }

    func test_createExpiryDateRule_validatesExpiry() {
        // Given
        let rule = sut.createExpiryDateRule()
        let expiry = TestData.ExpiryDates.validFuture
        let input = ExpiryDateInput(month: expiry.month, year: expiry.year)

        // When
        let result = rule.validate(input)

        // Then
        XCTAssertTrue(result.isValid)
    }

    // MARK: - CVV Rule Tests

    func test_createCVVRule_forVisa_returnsCVVRule() {
        // When
        let rule = sut.createCVVRule(cardNetwork: .visa)

        // Then
        XCTAssertNotNil(rule)
        XCTAssertTrue(rule is CVVRule)
    }

    func test_createCVVRule_forVisa_validates3Digits() {
        // Given
        let rule = sut.createCVVRule(cardNetwork: .visa)

        // When
        let result = rule.validate(TestData.CVV.valid3Digit)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_createCVVRule_forAmex_validates4Digits() {
        // Given
        let rule = sut.createCVVRule(cardNetwork: .amex)

        // When
        let result = rule.validate(TestData.CVV.valid4Digit)

        // Then
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Cardholder Name Rule Tests

    func test_createCardholderNameRule_returnsCardholderNameRule() {
        // When
        let rule = sut.createCardholderNameRule()

        // Then
        XCTAssertNotNil(rule)
        XCTAssertTrue(rule is CardholderNameRule)
    }

    // MARK: - First Name Rule Tests

    func test_createFirstNameRule_returnsFirstNameRule() {
        // When
        let rule = sut.createFirstNameRule()

        // Then
        XCTAssertNotNil(rule)
        XCTAssertTrue(rule is FirstNameRule)
    }

    // MARK: - Last Name Rule Tests

    func test_createLastNameRule_returnsLastNameRule() {
        // When
        let rule = sut.createLastNameRule()

        // Then
        XCTAssertNotNil(rule)
        XCTAssertTrue(rule is LastNameRule)
    }

    // MARK: - Email Rule Tests

    func test_createEmailValidationRule_returnsEmailValidationRule() {
        // When
        let rule = sut.createEmailValidationRule()

        // Then
        XCTAssertNotNil(rule)
        XCTAssertTrue(rule is EmailValidationRule)
    }

    // MARK: - Phone Number Rule Tests

    func test_createPhoneNumberValidationRule_returnsPhoneNumberValidationRule() {
        // When
        let rule = sut.createPhoneNumberValidationRule()

        // Then
        XCTAssertNotNil(rule)
        XCTAssertTrue(rule is PhoneNumberValidationRule)
    }

    // MARK: - Address Field Rule Tests

    func test_createAddressFieldRule_returnsAddressFieldRule() {
        // When
        let rule = sut.createAddressFieldRule(inputType: .addressLine1, isRequired: true)

        // Then
        XCTAssertNotNil(rule)
        XCTAssertTrue(rule is AddressFieldRule)
    }

    func test_createAddressFieldRule_withDifferentInputTypes() {
        // When
        let line1Rule = sut.createAddressFieldRule(inputType: .addressLine1, isRequired: true)
        let line2Rule = sut.createAddressFieldRule(inputType: .addressLine2, isRequired: false)
        let cityRule = sut.createAddressFieldRule(inputType: .city, isRequired: true)

        // Then
        XCTAssertNotNil(line1Rule)
        XCTAssertNotNil(line2Rule)
        XCTAssertNotNil(cityRule)

        // line2 is optional so nil should be valid
        XCTAssertTrue(line2Rule.validate(nil).isValid)
    }

    // MARK: - Postal Code Rule Tests

    func test_createBillingPostalCodeRule_returnsBillingPostalCodeRule() {
        // When
        let rule = sut.createBillingPostalCodeRule()

        // Then
        XCTAssertNotNil(rule)
        XCTAssertTrue(rule is BillingPostalCodeRule)
    }

    // MARK: - Country Code Rule Tests

    func test_createBillingCountryCodeRule_returnsBillingCountryCodeRule() {
        // When
        let rule = sut.createBillingCountryCodeRule()

        // Then
        XCTAssertNotNil(rule)
        XCTAssertTrue(rule is BillingCountryCodeRule)
    }
}
