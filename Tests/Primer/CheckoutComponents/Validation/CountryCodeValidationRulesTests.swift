//
//  CountryCodeValidationRulesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class CountryCodeValidationRulesTests: XCTestCase {

    // MARK: - Country Code Validation Tests

    func test_validateCountryCode_withValidCodes_returnsValid() {
        let rule = BillingCountryCodeRule()
        let validCodes: [String?] = [
            TestData.CountryCodes.us,
            TestData.CountryCodes.gbLowercase,
            TestData.CountryCodes.usa3Letter
        ]

        assertAllValid(rule: rule, values: validCodes)
    }

    func test_validateCountryCode_withInvalidCodes_returnsInvalid() {
        let rule = BillingCountryCodeRule()
        let invalidCodes: [String?] = [
            TestData.CountryCodes.empty,
            TestData.CountryCodes.singleCharacter,
            TestData.CountryCodes.tooLong,
            nil
        ]

        assertAllInvalid(rule: rule, values: invalidCodes)
    }

    // MARK: - Helpers

    private func assertAllValid<R: ValidationRule>(rule: R, values: [String?], file: StaticString = #file, line: UInt = #line) where R.Input == String? {
        for value in values {
            let result = rule.validate(value)
            XCTAssertTrue(result.isValid, "Expected '\(value ?? "nil")' to be valid", file: file, line: line)
        }
    }

    private func assertAllInvalid<R: ValidationRule>(rule: R, values: [String?], file: StaticString = #file, line: UInt = #line) where R.Input == String? {
        for value in values {
            let result = rule.validate(value)
            XCTAssertFalse(result.isValid, "Expected '\(value ?? "nil")' to be invalid", file: file, line: line)
        }
    }
}
