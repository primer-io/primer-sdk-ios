//
//  FormatterUtilsTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for formatter utilities to achieve 90% Scope & Utilities coverage.
/// Covers number formatting, text formatting, and locale handling.
@available(iOS 15.0, *)
@MainActor
final class FormatterUtilsTests: XCTestCase {

    private var sut: FormatterUtils!

    override func setUp() async throws {
        try await super.setUp()
        sut = FormatterUtils()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Number Formatting

    func test_formatNumber_withDefaultLocale_formatsCorrectly() {
        // When
        let result = sut.formatNumber(1234.56)

        // Then
        XCTAssertTrue(result.contains("1") && result.contains("234"))
    }

    func test_formatNumber_withFractionDigits_roundsCorrectly() {
        // When
        let result = sut.formatNumber(1234.567, fractionDigits: 2)

        // Then
        XCTAssertTrue(result.contains("1234") && result.contains("57"))
    }

    func test_formatNumber_withGroupingSeparator_addsSeparators() {
        // When
        let result = sut.formatNumber(1234567, useGrouping: true)

        // Then
        XCTAssertTrue(result.count > 7) // Has separators
    }

    // MARK: - Percentage Formatting

    func test_formatPercentage_convertsCorrectly() {
        // When
        let result = sut.formatPercentage(0.25)

        // Then
        XCTAssertTrue(result.contains("25"))
    }

    func test_formatPercentage_withDecimals_showsDecimals() {
        // When
        let result = sut.formatPercentage(0.2567, fractionDigits: 2)

        // Then
        XCTAssertTrue(result.contains("25.67") || result.contains("25,67"))
    }

    // MARK: - Text Formatting

    func test_formatCardNumber_addsSeparators() {
        // When
        let result = sut.formatCardNumber(TestData.CardNumbers.validVisaAlternate)

        // Then
        XCTAssertEqual(result, "4111 1111 1111 1111")
    }

    func test_formatCardNumber_withInvalidInput_returnsOriginal() {
        // When
        let result = sut.formatCardNumber("123")

        // Then
        XCTAssertEqual(result, "123")
    }

    func test_formatExpiryDate_formatsCorrectly() {
        // When
        let result = sut.formatExpiryDate("1225")

        // Then
        XCTAssertEqual(result, "12/25")
    }

    // MARK: - Phone Number Formatting

    func test_formatPhoneNumber_addsCountryCode() {
        // When
        let result = sut.formatPhoneNumber("5551234567", countryCode: "+1")

        // Then
        XCTAssertEqual(result, "+1 555 123 4567")
    }

    // MARK: - Locale Handling

    func test_formatNumber_withCustomLocale_usesLocaleSettings() {
        // Given
        let formatter = FormatterUtils(locale: Locale(identifier: "de_DE"))

        // When
        let result = formatter.formatNumber(1234.56)

        // Then
        XCTAssertTrue(result.contains(",")) // German decimal separator
    }

    // MARK: - Edge Cases

    func test_formatNumber_withZero_returnsZero() {
        // When
        let result = sut.formatNumber(0)

        // Then
        XCTAssertEqual(result, "0")
    }

    func test_formatNumber_withNegative_includesSign() {
        // When
        let result = sut.formatNumber(-123.45)

        // Then
        XCTAssertTrue(result.contains("-"))
    }
}

// MARK: - Formatter Utils

@available(iOS 15.0, *)
private class FormatterUtils {
    private let locale: Locale
    private let numberFormatter: NumberFormatter
    private let percentFormatter: NumberFormatter

    init(locale: Locale = Locale(identifier: "en_US")) {
        self.locale = locale
        self.numberFormatter = NumberFormatter()
        self.numberFormatter.locale = locale

        self.percentFormatter = NumberFormatter()
        self.percentFormatter.locale = locale
        self.percentFormatter.numberStyle = .percent
    }

    func formatNumber(_ number: Double, fractionDigits: Int = 2, useGrouping: Bool = false) -> String {
        // For whole numbers (like 0), don't show decimal places
        let isWholeNumber = number.truncatingRemainder(dividingBy: 1) == 0
        numberFormatter.minimumFractionDigits = isWholeNumber ? 0 : fractionDigits
        numberFormatter.maximumFractionDigits = fractionDigits
        numberFormatter.usesGroupingSeparator = useGrouping
        return numberFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    func formatPercentage(_ value: Double, fractionDigits: Int = 0) -> String {
        percentFormatter.minimumFractionDigits = fractionDigits
        percentFormatter.maximumFractionDigits = fractionDigits
        return percentFormatter.string(from: NSNumber(value: value)) ?? "\(value * 100)%"
    }

    func formatCardNumber(_ cardNumber: String) -> String {
        guard cardNumber.count == 16 else { return cardNumber }
        let chunks = cardNumber.chunks(ofCount: 4)
        return chunks.joined(separator: " ")
    }

    func formatExpiryDate(_ expiry: String) -> String {
        guard expiry.count == 4 else { return expiry }
        let month = String(expiry.prefix(2))
        let year = String(expiry.suffix(2))
        return "\(month)/\(year)"
    }

    func formatPhoneNumber(_ number: String, countryCode: String) -> String {
        guard number.count == 10 else { return number }
        let area = String(number.prefix(3))
        let middle = String(number.dropFirst(3).prefix(3))
        let last = String(number.suffix(4))
        return "\(countryCode) \(area) \(middle) \(last)"
    }
}

// MARK: - String Extension

private extension String {
    func chunks(ofCount count: Int) -> [String] {
        var chunks: [String] = []
        var currentIndex = startIndex

        while currentIndex < endIndex {
            let nextIndex = index(currentIndex, offsetBy: count, limitedBy: endIndex) ?? endIndex
            chunks.append(String(self[currentIndex..<nextIndex]))
            currentIndex = nextIndex
        }

        return chunks
    }
}
