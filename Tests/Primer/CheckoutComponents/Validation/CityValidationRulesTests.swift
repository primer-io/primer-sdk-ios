//
//  CityValidationRulesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class CityValidationRulesTests: XCTestCase {

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
}
