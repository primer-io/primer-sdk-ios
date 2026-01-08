//
//  ValidationRuleTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class ValidationRuleTests: XCTestCase {

    // MARK: - RequiredFieldRule Tests

    func test_requiredFieldRule_withNilInput_returnsInvalid() {
        // Given
        let rule = RequiredFieldRule(fieldName: "Email")

        // When
        let result = rule.validate(nil)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorCode, "required-email")
        XCTAssertEqual(result.errorMessage, "Email is required")
    }

    func test_requiredFieldRule_withEmptyString_returnsInvalid() {
        // Given
        let rule = RequiredFieldRule(fieldName: "Name")

        // When
        let result = rule.validate("")

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorCode, "required-name")
        XCTAssertEqual(result.errorMessage, "Name is required")
    }

    func test_requiredFieldRule_withWhitespaceOnly_returnsInvalid() {
        // Given
        let rule = RequiredFieldRule(fieldName: "Address")

        // When
        let result = rule.validate("   \n\t  ")

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_requiredFieldRule_withValidInput_returnsValid() {
        // Given
        let rule = RequiredFieldRule(fieldName: "City")

        // When
        let result = rule.validate("New York")

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorCode)
        XCTAssertNil(result.errorMessage)
    }

    func test_requiredFieldRule_withCustomErrorCode_usesCustomCode() {
        // Given
        let rule = RequiredFieldRule(fieldName: "Phone", errorCode: "custom-phone-required")

        // When
        let result = rule.validate(nil)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorCode, "custom-phone-required")
    }

    func test_requiredFieldRule_fieldNameWithSpaces_generatesCorrectErrorCode() {
        // Given
        let rule = RequiredFieldRule(fieldName: "First Name")

        // When
        let result = rule.validate(nil)

        // Then
        XCTAssertEqual(result.errorCode, "required-first-name")
    }

    // MARK: - LengthRule Tests

    func test_lengthRule_belowMinLength_returnsInvalid() {
        // Given
        let rule = LengthRule(fieldName: "Password", minLength: 8)

        // When
        let result = rule.validate("short")

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorCode, "length-password-min")
        XCTAssertEqual(result.errorMessage, "Password must be at least 8 characters")
    }

    func test_lengthRule_aboveMaxLength_returnsInvalid() {
        // Given
        let rule = LengthRule(fieldName: "Username", minLength: 3, maxLength: 10)

        // When
        let result = rule.validate("thisusernameistoolong")

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorCode, "length-username-max")
        XCTAssertEqual(result.errorMessage, "Username must not exceed 10 characters")
    }

    func test_lengthRule_atMinLength_returnsValid() {
        // Given
        let rule = LengthRule(fieldName: "PIN", minLength: 4)

        // When
        let result = rule.validate("1234")

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_lengthRule_atMaxLength_returnsValid() {
        // Given
        let rule = LengthRule(fieldName: "Code", minLength: 1, maxLength: 6)

        // When
        let result = rule.validate("123456")

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_lengthRule_withinRange_returnsValid() {
        // Given
        let rule = LengthRule(fieldName: "Title", minLength: 5, maxLength: 50)

        // When
        let result = rule.validate("This is a valid title")

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_lengthRule_trimsWhitespace_beforeValidation() {
        // Given
        let rule = LengthRule(fieldName: "Input", minLength: 3)

        // When - "ab" with whitespace is only 2 chars when trimmed
        let result = rule.validate("  ab  ")

        // Then - trimmed length is 2, below minimum of 3
        XCTAssertFalse(result.isValid)
    }

    func test_lengthRule_withCustomErrorCodePrefix_usesCustomPrefix() {
        // Given
        let rule = LengthRule(fieldName: "Field", minLength: 5, errorCodePrefix: "custom-field")

        // When
        let result = rule.validate("abc")

        // Then
        XCTAssertEqual(result.errorCode, "custom-field-min")
    }

    func test_lengthRule_noMaxLength_allowsLongInput() {
        // Given
        let rule = LengthRule(fieldName: "Description", minLength: 1)
        let longInput = String(repeating: "a", count: 10000)

        // When
        let result = rule.validate(longInput)

        // Then
        XCTAssertTrue(result.isValid)
    }

    // MARK: - CharacterSetRule Tests

    func test_characterSetRule_withValidCharacters_returnsValid() {
        // Given
        let rule = CharacterSetRule(fieldName: "Digits", allowedCharacterSet: .decimalDigits)

        // When
        let result = rule.validate("1234567890")

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_characterSetRule_withInvalidCharacters_returnsInvalid() {
        // Given
        let rule = CharacterSetRule(fieldName: "Digits", allowedCharacterSet: .decimalDigits)

        // When
        let result = rule.validate("123abc456")

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorCode, "invalid-chars-digits")
        XCTAssertEqual(result.errorMessage, "Digits contains invalid characters")
    }

    func test_characterSetRule_withLettersOnly_validatesAlphanumeric() {
        // Given
        let rule = CharacterSetRule(fieldName: "Name", allowedCharacterSet: .letters)

        // When
        let validResult = rule.validate("JohnDoe")
        let invalidResult = rule.validate("John123")

        // Then
        XCTAssertTrue(validResult.isValid)
        XCTAssertFalse(invalidResult.isValid)
    }

    func test_characterSetRule_withCustomCharacterSet_validates() {
        // Given
        let allowedSet = CharacterSet(charactersIn: "ABCDabcd1234")
        let rule = CharacterSetRule(fieldName: "Custom", allowedCharacterSet: allowedSet)

        // When
        let validResult = rule.validate("ABcd12")
        let invalidResult = rule.validate("ABcdXY")

        // Then
        XCTAssertTrue(validResult.isValid)
        XCTAssertFalse(invalidResult.isValid)
    }

    func test_characterSetRule_withEmptyString_returnsValid() {
        // Given
        let rule = CharacterSetRule(fieldName: "Field", allowedCharacterSet: .letters)

        // When
        let result = rule.validate("")

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_characterSetRule_withCustomErrorCode_usesCustomCode() {
        // Given
        let rule = CharacterSetRule(
            fieldName: "Phone",
            allowedCharacterSet: .decimalDigits,
            errorCode: "phone-invalid-format"
        )

        // When
        let result = rule.validate("555-1234")

        // Then
        XCTAssertEqual(result.errorCode, "phone-invalid-format")
    }

    func test_characterSetRule_fieldNameWithSpaces_generatesCorrectErrorCode() {
        // Given
        let rule = CharacterSetRule(fieldName: "Card Number", allowedCharacterSet: .decimalDigits)

        // When
        let result = rule.validate("1234-5678")

        // Then
        XCTAssertEqual(result.errorCode, "invalid-chars-card-number")
    }

    func test_characterSetRule_withAlphanumericsAndSpaces_validates() {
        // Given
        var allowedSet = CharacterSet.alphanumerics
        allowedSet.insert(charactersIn: " ")
        let rule = CharacterSetRule(fieldName: "Address", allowedCharacterSet: allowedSet)

        // When
        let validResult = rule.validate("123 Main Street")
        let invalidResult = rule.validate("123 Main Street!")

        // Then
        XCTAssertTrue(validResult.isValid)
        XCTAssertFalse(invalidResult.isValid)
    }
}
