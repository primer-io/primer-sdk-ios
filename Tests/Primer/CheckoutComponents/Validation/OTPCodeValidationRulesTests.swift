//
//  OTPCodeValidationRulesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class OTPCodeValidationRulesTests: XCTestCase {

    // MARK: - OTP Code Validation Tests

    func test_validateOTPCode_withValidCode_returnsValid() {
        // Given
        let rule = OTPCodeRule(expectedLength: TestData.OTPCodes.expectedLength6)
        let otp = TestData.OTPCodes.valid6Digit

        // When
        let result = rule.validate(otp)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateOTPCode_withWrongLength_returnsInvalid() {
        // Given
        let rule = OTPCodeRule(expectedLength: TestData.OTPCodes.expectedLength6)
        let otp = TestData.OTPCodes.tooShort

        // When
        let result = rule.validate(otp)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateOTPCode_withNonNumeric_returnsInvalid() {
        // Given
        let rule = OTPCodeRule(expectedLength: TestData.OTPCodes.expectedLength6)
        let otp = TestData.OTPCodes.withNonNumeric

        // When
        let result = rule.validate(otp)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateOTPCode_withEmpty_returnsInvalid() {
        // Given
        let rule = OTPCodeRule(expectedLength: TestData.OTPCodes.expectedLength6)
        let otp = TestData.OTPCodes.empty

        // When
        let result = rule.validate(otp)

        // Then
        XCTAssertFalse(result.isValid)
    }
}
