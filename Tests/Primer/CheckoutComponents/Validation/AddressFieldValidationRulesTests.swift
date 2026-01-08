//
//  AddressFieldValidationRulesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class AddressFieldValidationRulesTests: XCTestCase {

    // MARK: - Address Field Validation Tests

    func test_validateAddressLine1_withValidAddress_returnsValid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let address = TestData.Addresses.valid

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateAddressLine1_withEmpty_whenRequired_returnsInvalid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let address = TestData.Addresses.empty

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateAddressLine2_withEmpty_whenOptional_returnsValid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine2, isRequired: false)
        let address = TestData.Addresses.empty

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateAddressLine2_withNil_whenOptional_returnsValid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine2, isRequired: false)

        // When
        let result = rule.validate(nil)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateAddress_withMaxLength100_returnsValid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let address = TestData.Addresses.valid100Chars

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateAddress_exceeding100Characters_returnsInvalid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let address = TestData.Addresses.tooLong

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateAddress_withMinLength3_required() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let address = TestData.Addresses.tooShort

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateAddress_with3Chars_returnsValid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)
        let address = TestData.Addresses.valid3Chars

        // When
        let result = rule.validate(address)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateAddressLine1_withNil_whenRequired_returnsInvalid() {
        // Given
        let rule = AddressFieldRule(inputType: .addressLine1, isRequired: true)

        // When
        let result = rule.validate(nil)

        // Then
        XCTAssertFalse(result.isValid)
    }
}
