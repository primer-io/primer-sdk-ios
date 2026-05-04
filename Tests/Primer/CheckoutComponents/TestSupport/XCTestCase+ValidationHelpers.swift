//
//  XCTestCase+ValidationHelpers.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

extension XCTestCase {

    func assertAllValid<R: ValidationRule>(rule: R, values: [String], file: StaticString = #file, line: UInt = #line) where R.Input == String {
        for value in values {
            let result = rule.validate(value)
            XCTAssertTrue(result.isValid, "Expected '\(value)' to be valid", file: file, line: line)
        }
    }

    func assertAllInvalid<R: ValidationRule>(rule: R, values: [String], file: StaticString = #file, line: UInt = #line) where R.Input == String {
        for value in values {
            let result = rule.validate(value)
            XCTAssertFalse(result.isValid, "Expected '\(value)' to be invalid", file: file, line: line)
        }
    }

    func assertAllValid<R: ValidationRule>(rule: R, values: [String?], file: StaticString = #file, line: UInt = #line) where R.Input == String? {
        for value in values {
            let result = rule.validate(value)
            XCTAssertTrue(result.isValid, "Expected '\(value ?? "nil")' to be valid", file: file, line: line)
        }
    }

    func assertAllInvalid<R: ValidationRule>(rule: R, values: [String?], file: StaticString = #file, line: UInt = #line) where R.Input == String? {
        for value in values {
            let result = rule.validate(value)
            XCTAssertFalse(result.isValid, "Expected '\(value ?? "nil")' to be invalid", file: file, line: line)
        }
    }
}
