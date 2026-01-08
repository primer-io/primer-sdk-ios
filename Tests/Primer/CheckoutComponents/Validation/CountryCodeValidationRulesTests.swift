//
//  CountryCodeValidationRulesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class CountryCodeValidationRulesTests: XCTestCase {

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
}
