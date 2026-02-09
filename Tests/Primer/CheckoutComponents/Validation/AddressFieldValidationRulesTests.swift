//
//  AddressFieldValidationRulesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class AddressFieldValidationRulesTests: XCTestCase {

    // MARK: - Address Line 1 (Required) Tests

    func test_validateAddressLine1_withValidAddresses_returnsValid() {
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let validAddresses: [String?] = [
            TestData.Addresses.valid,
            TestData.Addresses.valid100Chars,
            TestData.Addresses.valid3Chars
        ]

        assertAllValid(rule: rule, values: validAddresses)
    }

    func test_validateAddressLine1_withInvalidAddresses_returnsInvalid() {
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let invalidAddresses: [String?] = [
            TestData.Addresses.empty,
            TestData.Addresses.tooLong,
            TestData.Addresses.tooShort,
            nil
        ]

        assertAllInvalid(rule: rule, values: invalidAddresses)
    }

    // MARK: - Address Line 2 (Optional) Tests

    func test_validateAddressLine2_whenOptional_returnsValid() {
        let rule = AddressFieldRule(inputType: .addressLine2, isRequired: false)
        let optionalValues: [String?] = [
            TestData.Addresses.empty,
            nil
        ]

        assertAllValid(rule: rule, values: optionalValues)
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
