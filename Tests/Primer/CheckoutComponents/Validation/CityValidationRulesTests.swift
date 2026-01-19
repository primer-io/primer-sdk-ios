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

    func test_validateCity_withValidCities_returnsValid() {
        let rule = CityRule()
        let validCities: [String] = [
            TestData.Cities.valid,
            TestData.Cities.withHyphen,
            TestData.Cities.withPeriod
        ]

        assertAllValid(rule: rule, values: validCities)
    }

    func test_validateCity_withInvalidCities_returnsInvalid() {
        let rule = CityRule()
        let invalidCities: [String] = [
            TestData.Cities.empty,
            TestData.Cities.singleCharacter
        ]

        assertAllInvalid(rule: rule, values: invalidCities)
    }

    func test_validateCity_withAddressFieldRule_returnsValid() {
        let rule = AddressFieldRule(inputType: .city, isRequired: true)
        let result = rule.validate(TestData.Cities.valid)
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Helpers

    private func assertAllValid<R: ValidationRule>(rule: R, values: [String], file: StaticString = #file, line: UInt = #line) where R.Input == String {
        for value in values {
            let result = rule.validate(value)
            XCTAssertTrue(result.isValid, "Expected '\(value)' to be valid", file: file, line: line)
        }
    }

    private func assertAllInvalid<R: ValidationRule>(rule: R, values: [String], file: StaticString = #file, line: UInt = #line) where R.Input == String {
        for value in values {
            let result = rule.validate(value)
            XCTAssertFalse(result.isValid, "Expected '\(value)' to be invalid", file: file, line: line)
        }
    }
}
