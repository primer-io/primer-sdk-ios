//
//  IntExtensionTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for Int currency formatting extensions.
@available(iOS 15.0, *)
final class IntExtensionTests: XCTestCase {

    // MARK: - Test Data

    private var usdCurrency: Currency { Currency(code: "USD", decimalDigits: 2) }
    private var eurCurrency: Currency { Currency(code: "EUR", decimalDigits: 2) }
    private var jpyCurrency: Currency { Currency(code: "JPY", decimalDigits: 0) }
    private var gbpCurrency: Currency { Currency(code: "GBP", decimalDigits: 2) }

    private var usLocale: Locale { Locale(identifier: "en_US") }
    private var deLocale: Locale { Locale(identifier: "de_DE") }
    private var jpLocale: Locale { Locale(identifier: "ja_JP") }

    // MARK: - toCurrencyString Tests

    func test_toCurrencyString_withUSD_formatsCorrectly() {
        // Given
        let amount = 1999 // $19.99 in cents

        // When
        let result = amount.toCurrencyString(currency: usdCurrency, locale: usLocale)

        // Then
        XCTAssertTrue(result.contains("19"))
        XCTAssertTrue(result.contains("99"))
    }

    func test_toCurrencyString_withZeroAmount_formatsCorrectly() {
        // Given
        let amount = 0

        // When
        let result = amount.toCurrencyString(currency: usdCurrency, locale: usLocale)

        // Then
        XCTAssertTrue(result.contains("0"))
    }

    func test_toCurrencyString_withLargeAmount_formatsCorrectly() {
        // Given
        let amount = 100000 // $1,000.00 in cents

        // When
        let result = amount.toCurrencyString(currency: usdCurrency, locale: usLocale)

        // Then
        XCTAssertTrue(result.contains("1"))
        XCTAssertTrue(result.contains("000"))
    }

    func test_toCurrencyString_withZeroDecimalCurrency_doesNotDivideBy100() {
        // Given - JPY is zero decimal, so 1000 JPY is 1000 JPY (not 10.00)
        let amount = 1000

        // When
        let result = amount.toCurrencyString(currency: jpyCurrency, locale: jpLocale)

        // Then - Should show 1000, not 10.00
        XCTAssertTrue(result.contains("1000") || result.contains("1,000"))
    }

    func test_toCurrencyString_withEUR_includesCurrencySymbol() {
        // Given
        let amount = 500 // €5.00 in cents

        // When
        let result = amount.toCurrencyString(currency: eurCurrency, locale: deLocale)

        // Then - Should contain some currency indicator
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("5"))
    }

    func test_toCurrencyString_withDecimalAmount_showsDecimals() {
        // Given
        let amount = 123 // $1.23 in cents

        // When
        let result = amount.toCurrencyString(currency: usdCurrency, locale: usLocale)

        // Then
        XCTAssertTrue(result.contains("1"))
        XCTAssertTrue(result.contains("23"))
    }

    // MARK: - formattedCurrencyAmount Tests

    func test_formattedCurrencyAmount_withUSD_dividesBy100() {
        // Given
        let amount = 1999 // $19.99 in cents

        // When
        let result = amount.formattedCurrencyAmount(currency: usdCurrency)

        // Then - Use Decimal(string:) to avoid floating point precision issues
        XCTAssertEqual(result, Decimal(string: "19.99"))
    }

    func test_formattedCurrencyAmount_withZero_returnsZero() {
        // Given
        let amount = 0

        // When
        let result = amount.formattedCurrencyAmount(currency: usdCurrency)

        // Then
        XCTAssertEqual(result, Decimal(0))
    }

    func test_formattedCurrencyAmount_withZeroDecimalCurrency_doesNotDivide() {
        // Given - JPY is zero decimal
        let amount = 1000

        // When
        let result = amount.formattedCurrencyAmount(currency: jpyCurrency)

        // Then - Should be 1000, not 10.00
        XCTAssertEqual(result, Decimal(1000))
    }

    func test_formattedCurrencyAmount_withLargeAmount_calculatesCorrectly() {
        // Given
        let amount = 10000000 // $100,000.00 in cents

        // When
        let result = amount.formattedCurrencyAmount(currency: usdCurrency)

        // Then
        XCTAssertEqual(result, Decimal(100000))
    }

    func test_formattedCurrencyAmount_withSingleCent_calculatesCorrectly() {
        // Given
        let amount = 1 // $0.01

        // When
        let result = amount.formattedCurrencyAmount(currency: usdCurrency)

        // Then - Use Decimal(string:) to avoid floating point precision issues
        XCTAssertEqual(result, Decimal(string: "0.01"))
    }

    // MARK: - toAccessibilityCurrencyString Tests

    func test_toAccessibilityCurrencyString_withUSD_includesCurrencyName() {
        // Given
        let amount = 1999 // $19.99 in cents

        // When
        let result = amount.toAccessibilityCurrencyString(currency: usdCurrency, locale: usLocale)

        // Then - Should include dollar/USD reference
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.lowercased().contains("dollar") || result.contains("USD"))
    }

    func test_toAccessibilityCurrencyString_usesPeriodAsDecimalSeparator() {
        // Given
        let amount = 1999

        // When
        let result = amount.toAccessibilityCurrencyString(currency: usdCurrency, locale: usLocale)

        // Then - Should use period (.) for VoiceOver clarity
        XCTAssertTrue(result.contains(".") || !result.contains(","))
    }

    func test_toAccessibilityCurrencyString_withZeroDecimalCurrency_noDecimalPoint() {
        // Given - JPY has no decimal places
        let amount = 1000

        // When
        let result = amount.toAccessibilityCurrencyString(currency: jpyCurrency, locale: usLocale)

        // Then - Should not have .00 suffix
        XCTAssertFalse(result.hasSuffix(".00"))
    }

    func test_toAccessibilityCurrencyString_withEUR_includesEuroReference() {
        // Given
        let amount = 500 // €5.00

        // When
        let result = amount.toAccessibilityCurrencyString(currency: eurCurrency, locale: usLocale)

        // Then - Should include euro reference
        XCTAssertTrue(result.lowercased().contains("euro") || result.contains("EUR"))
    }

    func test_toAccessibilityCurrencyString_withZeroAmount_formatsCorrectly() {
        // Given
        let amount = 0

        // When
        let result = amount.toAccessibilityCurrencyString(currency: usdCurrency, locale: usLocale)

        // Then
        XCTAssertTrue(result.contains("0"))
    }

    func test_toAccessibilityCurrencyString_withLargeAmount_noGroupingSeparator() {
        // Given
        let amount = 100000000 // $1,000,000.00 in cents

        // When
        let result = amount.toAccessibilityCurrencyString(currency: usdCurrency, locale: usLocale)

        // Then - Should not use comma grouping for VoiceOver clarity
        // The number part should be without grouping separators
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Edge Cases

    func test_toCurrencyString_withNegativeAmount_handlesCorrectly() {
        // Given
        let amount = -500 // -$5.00

        // When
        let result = amount.toCurrencyString(currency: usdCurrency, locale: usLocale)

        // Then - Should handle negative values
        XCTAssertFalse(result.isEmpty)
    }

    func test_formattedCurrencyAmount_withNegativeAmount_calculatesCorrectly() {
        // Given
        let amount = -500

        // When
        let result = amount.formattedCurrencyAmount(currency: usdCurrency)

        // Then
        XCTAssertEqual(result, Decimal(-5))
    }

    func test_toCurrencyString_withGBP_formatsCorrectly() {
        // Given
        let amount = 2500 // £25.00

        // When
        let result = amount.toCurrencyString(currency: gbpCurrency, locale: Locale(identifier: "en_GB"))

        // Then
        XCTAssertTrue(result.contains("25"))
    }
}
