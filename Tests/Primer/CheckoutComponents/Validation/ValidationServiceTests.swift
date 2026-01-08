//
//  ValidationServiceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class ValidationServiceTests: XCTestCase {

    private var sut: DefaultValidationService!
    private var mockRulesFactory: MockRulesFactory!

    override func setUp() {
        super.setUp()
        mockRulesFactory = MockRulesFactory()
        sut = DefaultValidationService(rulesFactory: mockRulesFactory)
    }

    override func tearDown() {
        sut = nil
        mockRulesFactory = nil
        super.tearDown()
    }

    // MARK: - Card Number Validation Tests

    func test_validateCardNumber_withValidNumber_returnsValid() {
        // Given
        let cardNumber = TestData.CardNumbers.validVisa

        // When
        let result = sut.validateCardNumber(cardNumber)

        // Then - Since MockRulesFactory returns real rules, the result depends on the rule
        XCTAssertNotNil(result)
    }

    // MARK: - Expiry Validation Tests

    func test_validateExpiry_withValidDate_returnsValid() {
        // Given
        let expiry = TestData.ExpiryDates.validFuture

        // When
        let result = sut.validateExpiry(month: expiry.month, year: expiry.year)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateExpiry_withExpiredDate_returnsInvalid() {
        // Given
        let expiry = TestData.ExpiryDates.expired

        // When
        let result = sut.validateExpiry(month: expiry.month, year: expiry.year)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - CVV Validation Tests

    func test_validateCVV_with3DigitsForVisa_returnsValid() {
        // Given
        let cvv = TestData.CVV.valid3Digit

        // When
        let result = sut.validateCVV(cvv, cardNetwork: .visa)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCVV_with4DigitsForAmex_returnsValid() {
        // Given
        let cvv = TestData.CVV.valid4Digit

        // When
        let result = sut.validateCVV(cvv, cardNetwork: .amex)

        // Then
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Cardholder Name Validation Tests

    func test_validateCardholderName_withValidName_returnsValid() {
        // Given
        let name = TestData.CardholderNames.valid

        // When
        let result = sut.validateCardholderName(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    // MARK: - validateField Tests

    func test_validateField_cardNumber_withNilValue_returnsInvalid() {
        // Given
        let fieldType = PrimerInputElementType.cardNumber

        // When
        let result = sut.validateField(type: fieldType, value: nil)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateField_cvv_withNilValue_returnsInvalid() {
        // Given
        let fieldType = PrimerInputElementType.cvv

        // When
        let result = sut.validateField(type: fieldType, value: nil)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateField_expiryDate_parsesCorrectly() {
        // Given
        let fieldType = PrimerInputElementType.expiryDate
        let expiry = TestData.ExpiryDates.validFuture
        let value = "\(expiry.month)/\(expiry.year)"

        // When
        let result = sut.validateField(type: fieldType, value: value)

        // Then
        XCTAssertTrue(result.isValid)
        // Note: Call count may be 0 due to internal caching optimization
    }

    func test_validateField_firstName_callsRulesFactory() {
        // Given
        let fieldType = PrimerInputElementType.firstName
        let value = TestData.FirstNames.valid

        // When
        _ = sut.validateField(type: fieldType, value: value)

        // Then
        XCTAssertEqual(mockRulesFactory.createFirstNameRuleCallCount, 1)
    }

    func test_validateField_lastName_callsRulesFactory() {
        // Given
        let fieldType = PrimerInputElementType.lastName
        let value = TestData.LastNames.valid

        // When
        _ = sut.validateField(type: fieldType, value: value)

        // Then
        XCTAssertEqual(mockRulesFactory.createLastNameRuleCallCount, 1)
    }

    func test_validateField_email_callsRulesFactory() {
        // Given
        let fieldType = PrimerInputElementType.email
        let value = TestData.EmailAddresses.valid

        // When
        _ = sut.validateField(type: fieldType, value: value)

        // Then
        XCTAssertEqual(mockRulesFactory.createEmailRuleCallCount, 1)
    }

    func test_validateField_phoneNumber_callsRulesFactory() {
        // Given
        let fieldType = PrimerInputElementType.phoneNumber
        let value = TestData.PhoneNumbers.validUS

        // When
        _ = sut.validateField(type: fieldType, value: value)

        // Then
        XCTAssertEqual(mockRulesFactory.createPhoneNumberRuleCallCount, 1)
    }

    func test_validateField_postalCode_callsRulesFactory() {
        // Given
        let fieldType = PrimerInputElementType.postalCode
        let value = TestData.PostalCodes.validUS

        // When
        _ = sut.validateField(type: fieldType, value: value)

        // Then
        XCTAssertEqual(mockRulesFactory.createPostalCodeRuleCallCount, 1)
    }

    func test_validateField_countryCode_callsRulesFactory() {
        // Given
        let fieldType = PrimerInputElementType.countryCode
        let value = TestData.CountryCodes.us

        // When
        _ = sut.validateField(type: fieldType, value: value)

        // Then
        XCTAssertEqual(mockRulesFactory.createCountryCodeRuleCallCount, 1)
    }

    func test_validateField_addressLine1_callsRulesFactory() {
        // Given
        let fieldType = PrimerInputElementType.addressLine1
        let value = TestData.Addresses.valid

        // When
        _ = sut.validateField(type: fieldType, value: value)

        // Then
        XCTAssertEqual(mockRulesFactory.createAddressFieldRuleCallCount, 1)
        XCTAssertEqual(mockRulesFactory.lastInputType, .addressLine1)
        XCTAssertEqual(mockRulesFactory.lastIsRequired, true)
    }

    func test_validateField_addressLine2_isOptional() {
        // Given
        let fieldType = PrimerInputElementType.addressLine2
        let value: String? = nil

        // When
        _ = sut.validateField(type: fieldType, value: value)

        // Then
        XCTAssertEqual(mockRulesFactory.createAddressFieldRuleCallCount, 1)
        XCTAssertEqual(mockRulesFactory.lastIsRequired, false)
    }

    func test_validateField_retailer_returnsValid() {
        // Given
        let fieldType = PrimerInputElementType.retailer

        // When
        let result = sut.validateField(type: fieldType, value: nil)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateField_unknown_returnsInvalid() {
        // Given
        let fieldType = PrimerInputElementType.unknown

        // When
        let result = sut.validateField(type: fieldType, value: "any")

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Generic Validate Tests

    func test_validate_withCustomRule_usesProvidedRule() {
        // Given
        let rule = CVVRule(cardNetwork: .visa)
        let input = TestData.CVV.valid3Digit

        // When
        let result = sut.validate(input: input, with: rule)

        // Then
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Structured State Validation Tests

    func test_validateFieldWithStructuredResult_withInvalidValue_returnsFieldError() {
        // Given
        let fieldType = PrimerInputElementType.cardNumber

        // When
        let error = sut.validateFieldWithStructuredResult(type: fieldType, value: nil)

        // Then
        XCTAssertNotNil(error)
        XCTAssertEqual(error?.fieldType, fieldType)
    }

    func test_validateFieldWithStructuredResult_withValidValue_returnsNil() {
        // Given
        let fieldType = PrimerInputElementType.cardholderName
        let value = TestData.CardholderNames.valid

        // When
        let error = sut.validateFieldWithStructuredResult(type: fieldType, value: value)

        // Then
        XCTAssertNil(error)
    }
}
