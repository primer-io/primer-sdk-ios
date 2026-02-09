//
//  StateValidationRulesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class StateValidationRulesTests: XCTestCase {

    // MARK: - State Validation Tests

    func test_validateState_withValidStates_returnsValid() {
        let rule = StateRule()
        let validStates: [String] = [
            TestData.States.validFullName,
            TestData.States.validAbbreviation
        ]

        assertAllValid(rule: rule, values: validStates)
    }

    func test_validateState_withInvalidStates_returnsInvalid() {
        let rule = StateRule()
        let invalidStates: [String] = [
            TestData.States.empty,
            TestData.States.singleCharacter
        ]

        assertAllInvalid(rule: rule, values: invalidStates)
    }

    func test_validateState_withAddressFieldRule_returnsValid() {
        let rule = AddressFieldRule(inputType: .state, isRequired: true)
        let result = rule.validate(TestData.States.validFullName)
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
