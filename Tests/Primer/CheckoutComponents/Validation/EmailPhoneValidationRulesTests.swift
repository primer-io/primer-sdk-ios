//
//  EmailPhoneValidationRulesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class EmailPhoneValidationRulesTests: XCTestCase {

    // MARK: - Email Validation Tests

    func test_validateEmail_withValidEmails_returnsValid() {
        let rule = EmailValidationRule()
        let validEmails: [String?] = [
            TestData.EmailAddresses.valid,
            TestData.EmailAddresses.validWithSubdomain,
            TestData.EmailAddresses.validWithPlus
        ]

        assertAllValid(rule: rule, values: validEmails)
    }

    func test_validateEmail_withInvalidEmails_returnsInvalid() {
        let rule = EmailValidationRule()
        let invalidEmails: [String?] = [
            TestData.EmailAddresses.missingAt,
            TestData.EmailAddresses.empty,
            TestData.EmailAddresses.invalidFormat,
            TestData.EmailAddresses.missingDomain,
            nil
        ]

        assertAllInvalid(rule: rule, values: invalidEmails)
    }

    // MARK: - Phone Number Validation Tests

    func test_validatePhoneNumber_withValidNumbers_returnsValid() {
        let rule = PhoneNumberValidationRule()
        let validPhones: [String?] = [
            TestData.PhoneNumbers.validUS,
            TestData.PhoneNumbers.validWithCountryCode,
            TestData.PhoneNumbers.validInternational
        ]

        assertAllValid(rule: rule, values: validPhones)
    }

    func test_validatePhoneNumber_withInvalidNumbers_returnsInvalid() {
        let rule = PhoneNumberValidationRule()
        let invalidPhones: [String?] = [
            TestData.PhoneNumbers.tooShort,
            TestData.PhoneNumbers.empty,
            TestData.PhoneNumbers.withLetters,
            nil
        ]

        assertAllInvalid(rule: rule, values: invalidPhones)
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
