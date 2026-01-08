//
//  EmailPhoneValidationRulesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class EmailPhoneValidationRulesTests: XCTestCase {

    // MARK: - Email Validation Tests

    func test_validateEmail_withValidEmail_returnsValid() {
        // Given
        let rule = EmailValidationRule()
        let email = TestData.EmailAddresses.valid

        // When
        let result = rule.validate(email)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateEmail_withSubdomain_returnsValid() {
        // Given
        let rule = EmailValidationRule()
        let email = TestData.EmailAddresses.validWithSubdomain

        // When
        let result = rule.validate(email)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateEmail_withPlusTag_returnsValid() {
        // Given
        let rule = EmailValidationRule()
        let email = TestData.EmailAddresses.validWithPlus

        // When
        let result = rule.validate(email)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateEmail_withMissingAt_returnsInvalid() {
        // Given
        let rule = EmailValidationRule()
        let email = TestData.EmailAddresses.missingAt

        // When
        let result = rule.validate(email)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateEmail_withEmpty_returnsInvalid() {
        // Given
        let rule = EmailValidationRule()
        let email = TestData.EmailAddresses.empty

        // When
        let result = rule.validate(email)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateEmail_withNil_returnsInvalid() {
        // Given
        let rule = EmailValidationRule()

        // When
        let result = rule.validate(nil)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateEmail_withInternationalTLD_returnsValid() {
        // Given
        let rule = EmailValidationRule()
        let email = TestData.EmailAddresses.validWithSubdomain

        // When
        let result = rule.validate(email)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateEmail_withNumbers_returnsValid() {
        // Given
        let rule = EmailValidationRule()
        let email = TestData.EmailAddresses.valid

        // When
        let result = rule.validate(email)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateEmail_withDotsInLocalPart_returnsValid() {
        // Given
        let rule = EmailValidationRule()
        let email = TestData.EmailAddresses.valid

        // When
        let result = rule.validate(email)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateEmail_withMultipleAtSymbols_returnsInvalid() {
        // Given
        let rule = EmailValidationRule()
        let email = TestData.EmailAddresses.invalidFormat

        // When
        let result = rule.validate(email)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateEmail_withSpaces_returnsInvalid() {
        // Given
        let rule = EmailValidationRule()
        let email = TestData.EmailAddresses.invalidFormat

        // When
        let result = rule.validate(email)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateEmail_withMissingDomain_returnsInvalid() {
        // Given
        let rule = EmailValidationRule()
        let email = TestData.EmailAddresses.missingDomain

        // When
        let result = rule.validate(email)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Phone Number Validation Tests

    func test_validatePhoneNumber_withValidUSNumber_returnsValid() {
        // Given
        let rule = PhoneNumberValidationRule()
        let phone = TestData.PhoneNumbers.validUS

        // When
        let result = rule.validate(phone)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePhoneNumber_withCountryCode_returnsValid() {
        // Given
        let rule = PhoneNumberValidationRule()
        let phone = TestData.PhoneNumbers.validWithCountryCode

        // When
        let result = rule.validate(phone)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePhoneNumber_withTooShort_returnsInvalid() {
        // Given
        let rule = PhoneNumberValidationRule()
        let phone = TestData.PhoneNumbers.tooShort

        // When
        let result = rule.validate(phone)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validatePhoneNumber_withEmpty_returnsInvalid() {
        // Given
        let rule = PhoneNumberValidationRule()
        let phone = TestData.PhoneNumbers.empty

        // When
        let result = rule.validate(phone)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validatePhoneNumber_withMinLength7_returnsValid() {
        // Given
        let rule = PhoneNumberValidationRule()
        let phone = TestData.PhoneNumbers.validUS

        // When
        let result = rule.validate(phone)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePhoneNumber_withMaxLength15_returnsValid() {
        // Given
        let rule = PhoneNumberValidationRule()
        let phone = TestData.PhoneNumbers.validInternational

        // When
        let result = rule.validate(phone)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePhoneNumber_with16Digits_returnsInvalid() {
        // Given
        let rule = PhoneNumberValidationRule()
        let phone = TestData.PhoneNumbers.tooShort

        // When
        let result = rule.validate(phone)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validatePhoneNumber_withInternationalFormat_returnsValid() {
        // Given
        let rule = PhoneNumberValidationRule()
        let phone = TestData.PhoneNumbers.validInternational

        // When
        let result = rule.validate(phone)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePhoneNumber_withLetters_returnsInvalid() {
        // Given
        let rule = PhoneNumberValidationRule()
        let phone = TestData.PhoneNumbers.withLetters

        // When
        let result = rule.validate(phone)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validatePhoneNumber_withParentheses_cleansAndValidates() {
        // Given
        let rule = PhoneNumberValidationRule()
        let phone = TestData.PhoneNumbers.validWithCountryCode

        // When
        let result = rule.validate(phone)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePhoneNumber_withNil_returnsInvalid() {
        // Given
        let rule = PhoneNumberValidationRule()

        // When
        let result = rule.validate(nil)

        // Then
        XCTAssertFalse(result.isValid)
    }
}
