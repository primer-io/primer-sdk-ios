//
//  ValidationServiceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class ValidationServiceTests: XCTestCase {

    private var sut: DefaultValidationService!

    override func setUp() {
        super.setUp()
        sut = DefaultValidationService(rulesFactory: DefaultRulesFactory())
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Card Number Validation Tests

    func test_validateCardNumber_withValidVisa_returnsValid() {
        let result = sut.validateCardNumber(TestData.CardNumbers.validVisa)
        XCTAssertTrue(result.isValid)
    }

    func test_validateCardNumber_withInvalidNumber_returnsInvalid() {
        let result = sut.validateCardNumber(TestData.CardNumbers.invalidRandom)
        XCTAssertFalse(result.isValid)
    }

    func test_validateCardNumber_withEmptyString_returnsInvalid() {
        let result = sut.validateCardNumber("")
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Expiry Validation Tests

    func test_validateExpiry_withValidDate_returnsValid() {
        let expiry = TestData.ExpiryDates.validFuture
        let result = sut.validateExpiry(month: expiry.month, year: expiry.year)
        XCTAssertTrue(result.isValid)
    }

    func test_validateExpiry_withExpiredDate_returnsInvalid() {
        let expiry = TestData.ExpiryDates.expired
        let result = sut.validateExpiry(month: expiry.month, year: expiry.year)
        XCTAssertFalse(result.isValid)
    }

    func test_validateExpiry_withInvalidMonth_returnsInvalid() {
        let result = sut.validateExpiry(month: TestData.ExpiryDates.invalidMonth.0, year: TestData.ExpiryDates.year30)
        XCTAssertFalse(result.isValid)
    }

    // MARK: - CVV Validation Tests

    func test_validateCVV_with3DigitsForVisa_returnsValid() {
        let result = sut.validateCVV(TestData.CVV.valid3Digit, cardNetwork: .visa)
        XCTAssertTrue(result.isValid)
    }

    func test_validateCVV_with4DigitsForAmex_returnsValid() {
        let result = sut.validateCVV(TestData.CVV.valid4Digit, cardNetwork: .amex)
        XCTAssertTrue(result.isValid)
    }

    func test_validateCVV_with3DigitsForAmex_returnsInvalid() {
        let result = sut.validateCVV(TestData.CVV.valid3Digit, cardNetwork: .amex)
        XCTAssertFalse(result.isValid)
    }

    func test_validateCVV_withEmptyString_returnsInvalid() {
        let result = sut.validateCVV("", cardNetwork: .visa)
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Cardholder Name Validation Tests

    func test_validateCardholderName_withValidName_returnsValid() {
        let result = sut.validateCardholderName(TestData.CardholderNames.valid)
        XCTAssertTrue(result.isValid)
    }

    func test_validateCardholderName_withEmptyString_returnsInvalid() {
        let result = sut.validateCardholderName("")
        XCTAssertFalse(result.isValid)
    }

    // MARK: - validateField Tests

    func test_validateField_cardNumber_withNilValue_returnsInvalid() {
        let result = sut.validateField(type: .cardNumber, value: nil)
        XCTAssertFalse(result.isValid)
    }

    func test_validateField_cardNumber_withValidValue_returnsValid() {
        let result = sut.validateField(type: .cardNumber, value: TestData.CardNumbers.validVisa)
        XCTAssertTrue(result.isValid)
    }

    func test_validateField_cvv_withNilValue_returnsInvalid() {
        let result = sut.validateField(type: .cvv, value: nil)
        XCTAssertFalse(result.isValid)
    }

    func test_validateField_expiryDate_withValidFormat_returnsValid() {
        let expiry = TestData.ExpiryDates.validFuture
        let value = "\(expiry.month)/\(expiry.year)"
        let result = sut.validateField(type: .expiryDate, value: value)
        XCTAssertTrue(result.isValid)
    }

    func test_validateField_expiryDate_withInvalidFormat_returnsInvalid() {
        let result = sut.validateField(type: .expiryDate, value: TestData.CardNumbers.invalidExpiryFormat)
        XCTAssertFalse(result.isValid)
    }

    func test_validateField_firstName_withValidValue_returnsValid() {
        let result = sut.validateField(type: .firstName, value: TestData.FirstNames.valid)
        XCTAssertTrue(result.isValid)
    }

    func test_validateField_firstName_withEmptyValue_returnsInvalid() {
        let result = sut.validateField(type: .firstName, value: "")
        XCTAssertFalse(result.isValid)
    }

    func test_validateField_lastName_withValidValue_returnsValid() {
        let result = sut.validateField(type: .lastName, value: TestData.LastNames.valid)
        XCTAssertTrue(result.isValid)
    }

    func test_validateField_email_withValidValue_returnsValid() {
        let result = sut.validateField(type: .email, value: TestData.EmailAddresses.valid)
        XCTAssertTrue(result.isValid)
    }

    func test_validateField_email_withInvalidValue_returnsInvalid() {
        let result = sut.validateField(type: .email, value: TestData.EmailAddresses.invalidFormat)
        XCTAssertFalse(result.isValid)
    }

    func test_validateField_phoneNumber_withValidValue_returnsValid() {
        let result = sut.validateField(type: .phoneNumber, value: TestData.PhoneNumbers.validUS)
        XCTAssertTrue(result.isValid)
    }

    func test_validateField_postalCode_withValidValue_returnsValid() {
        let result = sut.validateField(type: .postalCode, value: TestData.PostalCodes.validUS)
        XCTAssertTrue(result.isValid)
    }

    func test_validateField_countryCode_withValidValue_returnsValid() {
        let result = sut.validateField(type: .countryCode, value: TestData.CountryCodes.us)
        XCTAssertTrue(result.isValid)
    }

    func test_validateField_addressLine1_withValidValue_returnsValid() {
        let result = sut.validateField(type: .addressLine1, value: TestData.Addresses.valid)
        XCTAssertTrue(result.isValid)
    }

    func test_validateField_addressLine1_withEmptyValue_returnsInvalid() {
        let result = sut.validateField(type: .addressLine1, value: "")
        XCTAssertFalse(result.isValid)
    }

    func test_validateField_addressLine2_withNilValue_returnsValid() {
        let result = sut.validateField(type: .addressLine2, value: nil)
        XCTAssertTrue(result.isValid)
    }

    func test_validateField_retailer_returnsValid() {
        let result = sut.validateField(type: .retailer, value: nil)
        XCTAssertTrue(result.isValid)
    }

    func test_validateField_unknown_returnsInvalid() {
        let result = sut.validateField(type: .unknown, value: "any")
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Generic Validate Tests

    func test_validate_withCustomRule_usesProvidedRule() {
        let rule = CVVRule(cardNetwork: .visa)
        let result = sut.validate(input: TestData.CVV.valid3Digit, with: rule)
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Structured State Validation Tests

    func test_validateFieldWithStructuredResult_withInvalidValue_returnsFieldError() {
        let error = sut.validateFieldWithStructuredResult(type: .cardNumber, value: nil)
        XCTAssertNotNil(error)
        XCTAssertEqual(error?.fieldType, .cardNumber)
    }

    func test_validateFieldWithStructuredResult_withValidValue_returnsNil() {
        let error = sut.validateFieldWithStructuredResult(type: .cardholderName, value: TestData.CardholderNames.valid)
        XCTAssertNil(error)
    }
}
