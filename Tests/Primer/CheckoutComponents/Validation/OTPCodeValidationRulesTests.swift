//
//  OTPCodeValidationRulesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class OTPCodeValidationRulesTests: XCTestCase {

    // MARK: - OTP Code Validation Tests

    func test_validateOTPCode_withValidCode_returnsValid() {
        let rule = OTPCodeRule(expectedLength: TestData.OTPCodes.expectedLength6)
        let result = rule.validate(TestData.OTPCodes.valid6Digit)
        XCTAssertTrue(result.isValid)
    }

    func test_validateOTPCode_withInvalidCodes_returnsInvalid() {
        let rule = OTPCodeRule(expectedLength: TestData.OTPCodes.expectedLength6)
        let invalidCodes: [String] = [
            TestData.OTPCodes.tooShort,
            TestData.OTPCodes.withNonNumeric,
            TestData.OTPCodes.empty
        ]

        assertAllInvalid(rule: rule, values: invalidCodes)
    }

    // MARK: - Helpers

    private func assertAllInvalid<R: ValidationRule>(rule: R, values: [String], file: StaticString = #file, line: UInt = #line) where R.Input == String {
        for value in values {
            let result = rule.validate(value)
            XCTAssertFalse(result.isValid, "Expected '\(value)' to be invalid", file: file, line: line)
        }
    }
}
