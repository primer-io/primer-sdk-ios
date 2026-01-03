//
//  AddressValidationRulesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class AddressValidationRulesTests: XCTestCase {

    // MARK: - Address Field Validation Tests

    func test_validateAddressLine1_withValidAddress_returnsValid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let address = TestData.Addresses.valid

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateAddressLine1_withEmpty_whenRequired_returnsInvalid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let address = TestData.Addresses.empty

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateAddressLine2_withEmpty_whenOptional_returnsValid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine2, isRequired: false)
        let address = TestData.Addresses.empty

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

    func test_validateAddress_withMaxLength100_returnsValid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let address = TestData.Addresses.valid100Chars

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateAddress_exceeding100Characters_returnsInvalid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let address = TestData.Addresses.tooLong

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateAddress_withMinLength3_required() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let address = TestData.Addresses.tooShort

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateAddress_with3Chars_returnsValid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let address = TestData.Addresses.valid3Chars

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateAddressLine1_withNil_whenRequired_returnsInvalid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)

        // When
        let result = rule.validate(nil)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - City Validation Tests

    func test_validateCity_withValidCity_returnsValid() {
        // Given
        let rule = AddressFieldRule(inputType: .city, isRequired: true)
        let city = TestData.Cities.valid

        // When
        let result = rule.validate(city)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCity_withHyphen_returnsValid() {
        // Given
        let rule = CityRule()
        let city = TestData.Cities.withHyphen

        // When
        let result = rule.validate(city)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCity_withPeriod_returnsValid() {
        // Given
        let rule = CityRule()
        let city = TestData.Cities.withPeriod

        // When
        let result = rule.validate(city)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCity_withEmpty_returnsInvalid() {
        // Given
        let rule = CityRule()
        let city = TestData.Cities.empty

        // When
        let result = rule.validate(city)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateCity_withSingleChar_returnsInvalid() {
        // Given
        let rule = CityRule()
        let city = TestData.Cities.singleCharacter

        // When
        let result = rule.validate(city)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - State Validation Tests

    func test_validateState_withValidState_returnsValid() {
        // Given
        let rule = AddressFieldRule(inputType: .state, isRequired: true)
        let state = TestData.States.validFullName

        // When
        let result = rule.validate(state)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateState_withStateRule_allowsAbbreviation() {
        // Given
        let rule = StateRule()
        let state = TestData.States.validAbbreviation

        // When
        let result = rule.validate(state)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateState_withEmpty_returnsInvalid() {
        // Given
        let rule = StateRule()
        let state = TestData.States.empty

        // When
        let result = rule.validate(state)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateState_withSingleChar_returnsInvalid() {
        // Given
        let rule = StateRule()
        let state = TestData.States.singleCharacter

        // When
        let result = rule.validate(state)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Country Code Validation Tests

    func test_validateCountryCode_withValidCode_returnsValid() {
        // Given
        let rule = BillingCountryCodeRule()
        let countryCode = TestData.CountryCodes.us

        // When
        let result = rule.validate(countryCode)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCountryCode_withLowercase_returnsValid() {
        // Given
        let rule = BillingCountryCodeRule()
        let countryCode = TestData.CountryCodes.gbLowercase

        // When
        let result = rule.validate(countryCode)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCountryCode_withEmpty_returnsInvalid() {
        // Given
        let rule = BillingCountryCodeRule()
        let countryCode = TestData.CountryCodes.empty

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

    func test_validateCountryCode_with3LetterCode_returnsValid() {
        // Given
        let rule = BillingCountryCodeRule()
        let countryCode = TestData.CountryCodes.usa3Letter

        // When
        let result = rule.validate(countryCode)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCountryCode_withSingleChar_returnsInvalid() {
        // Given
        let rule = BillingCountryCodeRule()
        let countryCode = TestData.CountryCodes.singleCharacter

        // When
        let result = rule.validate(countryCode)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateCountryCode_with4Letters_returnsInvalid() {
        // Given
        let rule = BillingCountryCodeRule()
        let countryCode = TestData.CountryCodes.tooLong

        // When
        let result = rule.validate(countryCode)

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

    func test_validatePostalCode_US_withZipPlus4_returnsValid() {
        // Given
        let rule = PostalCodeRule(countryCode: "US")
        let postalCode = TestData.PostalCodes.validUSExtended

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePostalCode_US_withLetters_returnsInvalid() {
        // Given
        let rule = PostalCodeRule(countryCode: TestData.CountryCodes.us)
        let postalCode = TestData.PostalCodes.usWithLetters

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validatePostalCode_CA_withValidFormat_returnsValid() {
        // Given
        let rule = PostalCodeRule(countryCode: "CA")
        let postalCode = TestData.PostalCodes.validCanada

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePostalCode_CA_withInvalidFormat_returnsInvalid() {
        // Given
        let rule = PostalCodeRule(countryCode: "CA")
        let postalCode = TestData.PostalCodes.invalidCanadian

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validatePostalCode_GB_withValidLength_returnsValid() {
        // Given
        let rule = PostalCodeRule(countryCode: "GB")
        let postalCode = TestData.PostalCodes.validUK

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePostalCode_GB_withTooShort_returnsInvalid() {
        // Given
        let rule = PostalCodeRule(countryCode: TestData.CountryCodes.gb)
        let postalCode = TestData.PostalCodes.ukTooShort

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validatePostalCode_generic_withMinLength3_required() {
        // Given
        let rule = PostalCodeRule(countryCode: nil)
        let postalCode = TestData.PostalCodes.tooShort

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validatePostalCode_generic_with3Chars_returnsValid() {
        // Given
        let rule = PostalCodeRule(countryCode: nil)
        let postalCode = TestData.PostalCodes.validGeneric3Chars

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePostalCode_generic_withMaxLength10_enforced() {
        // Given
        let rule = PostalCodeRule(countryCode: nil)
        let postalCode = TestData.PostalCodes.tooLong

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validatePostalCode_generic_with10Chars_returnsValid() {
        // Given
        let rule = PostalCodeRule(countryCode: nil)
        let postalCode = TestData.PostalCodes.validGeneric10Chars

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertTrue(result.isValid)
    }

    // MARK: - OTP Code Validation Tests

    func test_validateOTPCode_withValidCode_returnsValid() {
        // Given
        let rule = OTPCodeRule(expectedLength: 6)
        let otp = TestData.OTPCodes.valid6Digit

        // When
        let result = rule.validate(otp)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateOTPCode_withWrongLength_returnsInvalid() {
        // Given
        let rule = OTPCodeRule(expectedLength: 6)
        let otp = TestData.OTPCodes.tooShort

        // When
        let result = rule.validate(otp)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateOTPCode_withNonNumeric_returnsInvalid() {
        // Given
        let rule = OTPCodeRule(expectedLength: 6)
        let otp = TestData.OTPCodes.withNonNumeric

        // When
        let result = rule.validate(otp)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateOTPCode_withEmpty_returnsInvalid() {
        // Given
        let rule = OTPCodeRule(expectedLength: 6)
        let otp = TestData.OTPCodes.empty

        // When
        let result = rule.validate(otp)

        // Then
        XCTAssertFalse(result.isValid)
    }
}
