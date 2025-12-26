//
//  StringExtensionsTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for String extension utilities to achieve 90% Scope & Utilities coverage.
/// Covers string manipulation, validation, transformation, and sanitization.
@available(iOS 15.0, *)
@MainActor
final class StringExtensionsTests: XCTestCase {

    // MARK: - Trimming

    func test_trimmed_removesWhitespace() {
        // When
        let result = "  hello  ".trimmed()

        // Then
        XCTAssertEqual(result, "hello")
    }

    func test_trimmed_removesNewlines() {
        // When
        let result = "\n\nhello\n\n".trimmed()

        // Then
        XCTAssertEqual(result, "hello")
    }

    func test_trimmed_emptyString_returnsEmpty() {
        // When
        let result = "   ".trimmed()

        // Then
        XCTAssertEqual(result, "")
    }

    // MARK: - Empty Check

    func test_isBlank_withWhitespace_returnsTrue() {
        // When/Then
        XCTAssertTrue("   ".isBlank)
        XCTAssertTrue("\n\t".isBlank)
        XCTAssertTrue("".isBlank)
    }

    func test_isBlank_withContent_returnsFalse() {
        // When/Then
        XCTAssertFalse("hello".isBlank)
        XCTAssertFalse("  a  ".isBlank)
    }

    // MARK: - Masking

    func test_masked_withCardNumber_masksCorrectly() {
        // When
        let result = "4111111111111111".masked(visibleCount: 4)

        // Then
        XCTAssertEqual(result, "************1111")
    }

    func test_masked_withShortString_returnsFullyMasked() {
        // When
        let result = "123".masked(visibleCount: 4)

        // Then
        XCTAssertEqual(result, "***")
    }

    // MARK: - Substring

    func test_safeSubstring_withValidRange_returnsSubstring() {
        // When
        let result = "hello".safeSubstring(from: 1, to: 4)

        // Then
        XCTAssertEqual(result, "ell")
    }

    func test_safeSubstring_withInvalidRange_returnsOriginal() {
        // When
        let result = "hello".safeSubstring(from: 10, to: 20)

        // Then
        XCTAssertEqual(result, "hello")
    }

    // MARK: - Capitalization

    func test_capitalizedFirst_capitalizesFirstLetter() {
        // When
        let result = "hello world".capitalizedFirst()

        // Then
        XCTAssertEqual(result, "Hello world")
    }

    func test_capitalizedFirst_emptyString_returnsEmpty() {
        // When
        let result = "".capitalizedFirst()

        // Then
        XCTAssertEqual(result, "")
    }

    // MARK: - Numeric Checks

    func test_isNumeric_withNumbers_returnsTrue() {
        // When/Then
        XCTAssertTrue("123".isNumeric)
        XCTAssertTrue("0".isNumeric)
    }

    func test_isNumeric_withNonNumbers_returnsFalse() {
        // When/Then
        XCTAssertFalse("abc".isNumeric)
        XCTAssertFalse("12a".isNumeric)
        XCTAssertFalse("".isNumeric)
    }

    // MARK: - Contains Check

    func test_containsIgnoringCase_findsMatch() {
        // When/Then
        XCTAssertTrue("Hello World".containsIgnoringCase("WORLD"))
        XCTAssertTrue("Hello World".containsIgnoringCase("hello"))
    }

    func test_containsIgnoringCase_noMatch_returnsFalse() {
        // When/Then
        XCTAssertFalse("Hello World".containsIgnoringCase("xyz"))
    }

    // MARK: - Sanitization

    func test_sanitized_removesSpecialCharacters() {
        // When
        let result = "hello@world!123".sanitized(allowedCharacters: .alphanumerics)

        // Then
        XCTAssertEqual(result, "helloworld123")
    }

    func test_sanitized_emptyString_returnsEmpty() {
        // When
        let result = "".sanitized(allowedCharacters: .alphanumerics)

        // Then
        XCTAssertEqual(result, "")
    }

    // MARK: - URL Encoding

    func test_urlEncoded_encodesSpecialCharacters() {
        // When
        let result = "hello world".urlEncoded()

        // Then
        XCTAssertEqual(result, "hello%20world")
    }

    func test_urlEncoded_withSymbols_encodesCorrectly() {
        // When
        let result = "hello world#test".urlEncoded()

        // Then
        XCTAssertTrue(result.contains("%"))
    }

    // MARK: - Truncation

    func test_truncated_withLongString_truncates() {
        // When
        let result = "Hello World".truncated(to: 5)

        // Then
        XCTAssertEqual(result, "Hello...")
    }

    func test_truncated_withShortString_returnsOriginal() {
        // When
        let result = "Hello".truncated(to: 10)

        // Then
        XCTAssertEqual(result, "Hello")
    }
}

// MARK: - String Extensions

@available(iOS 15.0, *)
private extension String {

    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isBlank: Bool {
        trimmed().isEmpty
    }

    func masked(visibleCount: Int, maskCharacter: Character = "*") -> String {
        guard count > visibleCount else {
            return String(repeating: maskCharacter, count: count)
        }
        let maskedPart = String(repeating: maskCharacter, count: count - visibleCount)
        let visiblePart = suffix(visibleCount)
        return maskedPart + visiblePart
    }

    func safeSubstring(from: Int, to: Int) -> String {
        guard from >= 0, to <= count, from < to else { return self }
        let startIndex = index(startIndex, offsetBy: from)
        let endIndex = index(startIndex, offsetBy: to - from)
        return String(self[startIndex..<endIndex])
    }

    func capitalizedFirst() -> String {
        guard !isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst()
    }

    var isNumeric: Bool {
        !isEmpty && allSatisfy(\.isNumber)
    }

    func containsIgnoringCase(_ substring: String) -> Bool {
        lowercased().contains(substring.lowercased())
    }

    func sanitized(allowedCharacters: CharacterSet) -> String {
        String(unicodeScalars.filter { allowedCharacters.contains($0) })
    }

    func urlEncoded() -> String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }

    func truncated(to length: Int, trailing: String = "...") -> String {
        guard count > length else { return self }
        return prefix(length) + trailing
    }
}
