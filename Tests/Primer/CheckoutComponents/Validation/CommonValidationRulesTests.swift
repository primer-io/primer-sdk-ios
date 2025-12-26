//
//  CommonValidationRulesTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for common validation rules including name, email, phone, address, and postal code validation.
@available(iOS 15.0, *)
final class CommonValidationRulesTests: XCTestCase {

    // MARK: - First Name Validation Tests

    func test_validateFirstName_withValidName_returnsValid() {
        // Given
        let rule = FirstNameRule()
        let name = "John"

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateFirstName_withEmpty_returnsInvalid() {
        // Given
        let rule = FirstNameRule()
        let name = ""

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateFirstName_withNil_returnsInvalid() {
        // Given
        let rule = FirstNameRule()

        // When
        let result = rule.validate(nil)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Last Name Validation Tests

    func test_validateLastName_withValidName_returnsValid() {
        // Given
        let rule = LastNameRule()
        let name = "Doe"

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateLastName_withEmpty_returnsInvalid() {
        // Given
        let rule = LastNameRule()
        let name = ""

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertFalse(result.isValid)
    }

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

    // MARK: - Postal Code Validation Tests

    func test_validatePostalCode_withValidUSCode_returnsValid() {
        // Given
        let rule = BillingPostalCodeRule()
        let postalCode = TestData.PostalCodes.validUS

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePostalCode_withEmpty_returnsInvalid() {
        // Given
        let rule = BillingPostalCodeRule()
        let postalCode = TestData.PostalCodes.empty

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validatePostalCode_withNil_returnsInvalid() {
        // Given
        let rule = BillingPostalCodeRule()

        // When
        let result = rule.validate(nil)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Country Code Validation Tests

    func test_validateCountryCode_withValidCode_returnsValid() {
        // Given
        let rule = BillingCountryCodeRule()
        let countryCode = "US"

        // When
        let result = rule.validate(countryCode)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCountryCode_withLowercase_returnsValid() {
        // Given
        let rule = BillingCountryCodeRule()
        let countryCode = "gb"

        // When
        let result = rule.validate(countryCode)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCountryCode_withEmpty_returnsInvalid() {
        // Given
        let rule = BillingCountryCodeRule()
        let countryCode = ""

        // When
        let result = rule.validate(countryCode)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateCountryCode_withNil_returnsInvalid() {
        // Given
        let rule = BillingCountryCodeRule()

        // When
        let result = rule.validate(nil)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Address Field Validation Tests

    func test_validateAddressLine1_withValidAddress_returnsValid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let address = "123 Main Street"

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateAddressLine1_withEmpty_whenRequired_returnsInvalid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let address = ""

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateAddressLine2_withEmpty_whenOptional_returnsValid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine2, isRequired: false)
        let address = ""

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateAddressLine2_withNil_whenOptional_returnsValid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine2, isRequired: false)

        // When
        let result = rule.validate(nil)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCity_withValidCity_returnsValid() {
        // Given
        let rule = AddressFieldRule(inputType: .city, isRequired: true)
        let city = "New York"

        // When
        let result = rule.validate(city)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateState_withValidState_returnsValid() {
        // Given
        // AddressFieldRule uses AddressRule which requires minimum 3 characters
        let rule = AddressFieldRule(inputType: .state, isRequired: true)
        let state = "New York"  // Full state name to meet 3-char minimum

        // When
        let result = rule.validate(state)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateState_withStateRule_allowsAbbreviation() {
        // Given - StateRule specifically allows 2-character abbreviations
        let rule = StateRule()
        let state = "NY"

        // When
        let result = rule.validate(state)

        // Then
        XCTAssertTrue(result.isValid)
    }

    // MARK: - OTP Code Validation Tests

    func test_validateOTPCode_withValidCode_returnsValid() {
        // Given
        let rule = OTPCodeRule(expectedLength: 6)
        let otp = "123456"

        // When
        let result = rule.validate(otp)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateOTPCode_withWrongLength_returnsInvalid() {
        // Given
        let rule = OTPCodeRule(expectedLength: 6)
        let otp = "1234"  // Too short

        // When
        let result = rule.validate(otp)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateOTPCode_withNonNumeric_returnsInvalid() {
        // Given
        let rule = OTPCodeRule(expectedLength: 6)
        let otp = "12345a"

        // When
        let result = rule.validate(otp)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateOTPCode_withEmpty_returnsInvalid() {
        // Given
        let rule = OTPCodeRule(expectedLength: 6)
        let otp = ""

        // When
        let result = rule.validate(otp)

        // Then
        XCTAssertFalse(result.isValid)
    }
}
