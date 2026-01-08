//
//  PostalCodeValidationRulesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class PostalCodeValidationRulesTests: XCTestCase {

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
        let rule = PostalCodeRule(countryCode: TestData.CountryCodes.us)
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
        let rule = PostalCodeRule(countryCode: TestData.CountryCodes.ca)
        let postalCode = TestData.PostalCodes.validCanada

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validatePostalCode_CA_withInvalidFormat_returnsInvalid() {
        // Given
        let rule = PostalCodeRule(countryCode: TestData.CountryCodes.ca)
        let postalCode = TestData.PostalCodes.invalidCanadian

        // When
        let result = rule.validate(postalCode)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validatePostalCode_GB_withValidLength_returnsValid() {
        // Given
        let rule = PostalCodeRule(countryCode: TestData.CountryCodes.gb)
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
}
