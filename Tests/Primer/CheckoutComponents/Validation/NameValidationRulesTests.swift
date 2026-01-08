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

    func test_validateFirstName_withValidName_returnsValid() {
        // Given
        let rule = FirstNameRule()
        let name = TestData.FirstNames.valid

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateFirstName_withEmpty_returnsInvalid() {
        // Given
        let rule = FirstNameRule()
        let name = TestData.FirstNames.empty

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateFirstName_withNil_returnsInvalid() {
        // Given
        let rule = FirstNameRule()

        // When
        let result = rule.validate(nil)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateFirstName_withUnicodeCharacters_returnsValid() {
        // Given
        let rule = FirstNameRule()
        let name = TestData.FirstNames.withAccents

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateFirstName_withAccentedCharacters_returnsValid() {
        // Given
        let rule = FirstNameRule()
        let name = TestData.FirstNames.withUnicode

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateFirstName_withSingleCharacter_returnsInvalid() {
        // Given
        let rule = FirstNameRule()
        let name = TestData.FirstNames.singleCharacter

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Last Name Validation Tests

    func test_validateLastName_withValidName_returnsValid() {
        // Given
        let rule = LastNameRule()
        let name = TestData.LastNames.valid

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateLastName_withEmpty_returnsInvalid() {
        // Given
        let rule = LastNameRule()
        let name = TestData.LastNames.empty

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateLastName_withApostrophe_returnsValid() {
        // Given
        let rule = LastNameRule()
        let name = TestData.LastNames.withApostrophe

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateLastName_withHyphen_returnsValid() {
        // Given
        let rule = LastNameRule()
        let name = TestData.LastNames.withHyphen

        // When
        let result = rule.validate(name)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateLastName_withNil_returnsInvalid() {
        // Given
        let rule = LastNameRule()

        // When
        let result = rule.validate(nil)

        // Then
        XCTAssertFalse(result.isValid)
    }
}
