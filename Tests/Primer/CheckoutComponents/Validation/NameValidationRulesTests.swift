//
//  NameValidationRulesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class NameValidationRulesTests: XCTestCase {

    // MARK: - First Name Validation Tests

    func test_validateFirstName_withValidNames_returnsValid() {
        let rule = FirstNameRule()
        let validNames: [String?] = [
            TestData.FirstNames.valid,
            TestData.FirstNames.withAccents,
            TestData.FirstNames.withUnicode
        ]

        assertAllValid(rule: rule, values: validNames)
    }

    func test_validateFirstName_withInvalidNames_returnsInvalid() {
        let rule = FirstNameRule()
        let invalidNames: [String?] = [
            TestData.FirstNames.empty,
            TestData.FirstNames.singleCharacter,
            nil
        ]

        assertAllInvalid(rule: rule, values: invalidNames)
    }

    // MARK: - Last Name Validation Tests

    func test_validateLastName_withValidNames_returnsValid() {
        let rule = LastNameRule()
        let validNames: [String?] = [
            TestData.LastNames.valid,
            TestData.LastNames.withApostrophe,
            TestData.LastNames.withHyphen
        ]

        assertAllValid(rule: rule, values: validNames)
    }

    func test_validateLastName_withInvalidNames_returnsInvalid() {
        let rule = LastNameRule()
        let invalidNames: [String?] = [
            TestData.LastNames.empty,
            nil
        ]

        assertAllInvalid(rule: rule, values: invalidNames)
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
