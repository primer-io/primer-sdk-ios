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

    // MARK: - Additional Name Validation Tests

    func test_validateFirstName_withUnicodeCharacters_returnsValid() {
        // Given - Names with unicode letters (François)
        let rule = FirstNameRule()
        let name = "François"

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateFirstName_withAccentedCharacters_returnsValid() {
        // Given - Names with accents (René)
        let rule = FirstNameRule()
        let name = "René"

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateFirstName_withSingleCharacter_returnsInvalid() {
        // Given - Single character names should be invalid (min 2 chars)
        let rule = FirstNameRule()
        let name = "J"

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateLastName_withApostrophe_returnsValid() {
        // Given - Names like O'Connor should be valid
        let rule = LastNameRule()
        let name = "O'Connor"

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateLastName_withHyphen_returnsValid() {
        // Given - Hyphenated names like Smith-Jones should be valid
        let rule = LastNameRule()
        let name = "Smith-Jones"

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateLastName_withNil_returnsInvalid() {
        // Given
        let rule = LastNameRule()

        // When
        let result = rule.validate(nil)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Additional Email Validation Tests

    func test_validateEmail_withInternationalTLD_returnsValid() {
        // Given - Emails with international TLDs (.co.uk)
        let rule = EmailValidationRule()
        let email = "user@example.co.uk"

        // When
        let result = rule.validate(email)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateEmail_withNumbers_returnsValid() {
        // Given - Emails with numbers in local part
        let rule = EmailValidationRule()
        let email = "user123@test.com"

        // When
        let result = rule.validate(email)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateEmail_withDotsInLocalPart_returnsValid() {
        // Given - Emails with dots in local part
        let rule = EmailValidationRule()
        let email = "user.name@test.com"

        // When
        let result = rule.validate(email)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateEmail_withMultipleAtSymbols_returnsInvalid() {
        // Given - Invalid email with multiple @ symbols
        let rule = EmailValidationRule()
        let email = "user@@test.com"

        // When
        let result = rule.validate(email)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateEmail_withSpaces_returnsInvalid() {
        // Given - Invalid email with spaces
        let rule = EmailValidationRule()
        let email = "user name@test.com"

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

    // MARK: - Additional Phone Number Validation Tests

    func test_validatePhoneNumber_withMinLength7_returnsValid() {
        // Given - Minimum valid length is 7 digits
        let rule = PhoneNumberValidationRule()
        let phone = "1234567"

        // When
        let result = rule.validate(phone)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePhoneNumber_withMaxLength15_returnsValid() {
        // Given - Maximum valid length is 15 digits
        let rule = PhoneNumberValidationRule()
        let phone = "123456789012345"

        // When
        let result = rule.validate(phone)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePhoneNumber_with16Digits_returnsInvalid() {
        // Given - 16 digits exceeds max length
        let rule = PhoneNumberValidationRule()
        let phone = "1234567890123456"

        // When
        let result = rule.validate(phone)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validatePhoneNumber_withInternationalFormat_returnsValid() {
        // Given - International format +44 20 7946 0958
        let rule = PhoneNumberValidationRule()
        let phone = TestData.PhoneNumbers.validInternational

        // When
        let result = rule.validate(phone)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePhoneNumber_withLetters_returnsInvalid() {
        // Given - Phone numbers with letters should be invalid
        let rule = PhoneNumberValidationRule()
        let phone = TestData.PhoneNumbers.withLetters

        // When
        let result = rule.validate(phone)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validatePhoneNumber_withParentheses_cleansAndValidates() {
        // Given - Phone with parentheses should be cleaned
        let rule = PhoneNumberValidationRule()
        let phone = "(123) 456-7890"

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

    // MARK: - Additional Postal Code Validation Tests (Country-Specific)

    func test_validatePostalCode_US_withZipPlus4_returnsValid() {
        // Given - US ZIP+4 format (12345-6789)
        let rule = PostalCodeRule(countryCode: "US")
        let postalCode = TestData.PostalCodes.validUSExtended

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePostalCode_US_withLetters_returnsInvalid() {
        // Given - US ZIP code should be numeric only
        let rule = PostalCodeRule(countryCode: "US")
        let postalCode = "1000A"

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validatePostalCode_CA_withValidFormat_returnsValid() {
        // Given - Canadian postal code format (A1A 1A1)
        let rule = PostalCodeRule(countryCode: "CA")
        let postalCode = TestData.PostalCodes.validCanada

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePostalCode_CA_withInvalidFormat_returnsInvalid() {
        // Given - Invalid Canadian postal code
        let rule = PostalCodeRule(countryCode: "CA")
        let postalCode = "12345"

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validatePostalCode_GB_withValidLength_returnsValid() {
        // Given - UK postcode (SW1A 2AA)
        let rule = PostalCodeRule(countryCode: "GB")
        let postalCode = TestData.PostalCodes.validUK

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePostalCode_GB_withTooShort_returnsInvalid() {
        // Given - UK postcode too short (min 5 chars)
        let rule = PostalCodeRule(countryCode: "GB")
        let postalCode = "SW1"

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validatePostalCode_generic_withMinLength3_required() {
        // Given - Generic postal code needs at least 3 chars
        let rule = PostalCodeRule(countryCode: nil)
        let postalCode = "12"

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validatePostalCode_generic_with3Chars_returnsValid() {
        // Given - 3 chars is minimum for generic
        let rule = PostalCodeRule(countryCode: nil)
        let postalCode = "123"

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePostalCode_generic_withMaxLength10_enforced() {
        // Given - 11+ chars exceeds max
        let rule = PostalCodeRule(countryCode: nil)
        let postalCode = "12345678901"

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validatePostalCode_generic_with10Chars_returnsValid() {
        // Given - 10 chars is max for generic
        let rule = PostalCodeRule(countryCode: nil)
        let postalCode = "1234567890"

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Additional Address Validation Tests

    func test_validateAddress_withMaxLength100_returnsValid() {
        // Given - Address at max length (100 chars)
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let address = String(repeating: "a", count: 100)

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateAddress_exceeding100Characters_returnsInvalid() {
        // Given - Address exceeding 100 chars
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let address = String(repeating: "a", count: 101)

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateAddress_withMinLength3_required() {
        // Given - Address needs at least 3 chars
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let address = "AB"

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateAddress_with3Chars_returnsValid() {
        // Given - 3 chars is minimum
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let address = "ABC"

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

    // MARK: - City and State Validation Tests

    func test_validateCity_withHyphen_returnsValid() {
        // Given - Cities with hyphens (Winston-Salem)
        let rule = CityRule()
        let city = "Winston-Salem"

        // When
        let result = rule.validate(city)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCity_withPeriod_returnsValid() {
        // Given - Cities with periods (St. Louis)
        let rule = CityRule()
        let city = "St. Louis"

        // When
        let result = rule.validate(city)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCity_withEmpty_returnsInvalid() {
        // Given
        let rule = CityRule()
        let city = ""

        // When
        let result = rule.validate(city)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateCity_withSingleChar_returnsInvalid() {
        // Given - City needs at least 2 chars
        let rule = CityRule()
        let city = "A"

        // When
        let result = rule.validate(city)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateState_withEmpty_returnsInvalid() {
        // Given
        let rule = StateRule()
        let state = ""

        // When
        let result = rule.validate(state)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateState_withSingleChar_returnsInvalid() {
        // Given - State needs at least 2 chars
        let rule = StateRule()
        let state = "N"

        // When
        let result = rule.validate(state)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Country Code Validation Tests

    func test_validateCountryCode_with3LetterCode_returnsValid() {
        // Given - 3-letter ISO codes should be valid
        let rule = BillingCountryCodeRule()
        let countryCode = "USA"

        // When
        let result = rule.validate(countryCode)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCountryCode_withSingleChar_returnsInvalid() {
        // Given - Single character is too short
        let rule = BillingCountryCodeRule()
        let countryCode = "U"

        // When
        let result = rule.validate(countryCode)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateCountryCode_with4Letters_returnsInvalid() {
        // Given - 4+ characters is too long
        let rule = BillingCountryCodeRule()
        let countryCode = "USAA"

        // When
        let result = rule.validate(countryCode)

        // Then
        XCTAssertFalse(result.isValid)
    }
}
