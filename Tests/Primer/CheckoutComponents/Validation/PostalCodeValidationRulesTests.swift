//
//  PostalCodeValidationRulesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class PostalCodeValidationRulesTests: XCTestCase {

    // MARK: - Billing Postal Code Tests

    func test_validateBillingPostalCode_withValidCode_returnsValid() {
        let rule = BillingPostalCodeRule()
        let result = rule.validate(TestData.PostalCodes.validUS)
        XCTAssertTrue(result.isValid)
    }

    func test_validateBillingPostalCode_withInvalidCodes_returnsInvalid() {
        let rule = BillingPostalCodeRule()
        let invalidCodes: [String?] = [
            TestData.PostalCodes.empty,
            nil
        ]

        assertAllInvalid(rule: rule, values: invalidCodes)
    }

    // MARK: - US Postal Code Tests

    func test_validatePostalCode_US_withValidCodes_returnsValid() {
        let rule = PostalCodeRule(countryCode: TestData.CountryCodes.us)
        let validCodes: [String] = [
            TestData.PostalCodes.validUS,
            TestData.PostalCodes.validUSExtended
        ]

        assertAllValid(rule: rule, values: validCodes)
    }

    func test_validatePostalCode_US_withInvalidCodes_returnsInvalid() {
        let rule = PostalCodeRule(countryCode: TestData.CountryCodes.us)
        let result = rule.validate(TestData.PostalCodes.usWithLetters)
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Canada Postal Code Tests

    func test_validatePostalCode_CA_withValidCode_returnsValid() {
        let rule = PostalCodeRule(countryCode: TestData.CountryCodes.ca)
        let result = rule.validate(TestData.PostalCodes.validCanada)
        XCTAssertTrue(result.isValid)
    }

    func test_validatePostalCode_CA_withInvalidCode_returnsInvalid() {
        let rule = PostalCodeRule(countryCode: TestData.CountryCodes.ca)
        let result = rule.validate(TestData.PostalCodes.invalidCanadian)
        XCTAssertFalse(result.isValid)
    }

    // MARK: - UK Postal Code Tests

    func test_validatePostalCode_GB_withValidCode_returnsValid() {
        let rule = PostalCodeRule(countryCode: TestData.CountryCodes.gb)
        let result = rule.validate(TestData.PostalCodes.validUK)
        XCTAssertTrue(result.isValid)
    }

    func test_validatePostalCode_GB_withTooShort_returnsInvalid() {
        let rule = PostalCodeRule(countryCode: TestData.CountryCodes.gb)
        let result = rule.validate(TestData.PostalCodes.ukTooShort)
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Generic Postal Code Tests

    func test_validatePostalCode_generic_withValidCodes_returnsValid() {
        let rule = PostalCodeRule(countryCode: nil)
        let validCodes: [String] = [
            TestData.PostalCodes.validGeneric3Chars,
            TestData.PostalCodes.validGeneric10Chars
        ]

        assertAllValid(rule: rule, values: validCodes)
    }

    func test_validatePostalCode_generic_withInvalidCodes_returnsInvalid() {
        let rule = PostalCodeRule(countryCode: nil)
        let invalidCodes: [String] = [
            TestData.PostalCodes.tooShort,
            TestData.PostalCodes.tooLong
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
