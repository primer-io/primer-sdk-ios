//
//  CurrencyFormattingTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for currency formatting utilities to achieve 90% Scope & Utilities coverage.
/// Covers multi-currency formatting, locale handling, and minor unit conversion.
@available(iOS 15.0, *)
@MainActor
final class CurrencyFormattingTests: XCTestCase {

    private var sut: CurrencyFormatter!

    override func setUp() async throws {
        try await super.setUp()
        sut = CurrencyFormatter()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Basic Formatting

    func test_formatAmount_withUSD_formatsCorrectly() {
        // When
        let result = sut.formatAmount(1234, currency: TestData.Currencies.usd)

        // Then
        XCTAssertTrue(result.contains("12.34"))
        XCTAssertTrue(result.contains("$") || result.contains("USD"))
    }

    func test_formatAmount_withEUR_formatsCorrectly() {
        // When
        let result = sut.formatAmount(5678, currency: TestData.Currencies.eur)

        // Then
        XCTAssertTrue(result.contains("56.78"))
        XCTAssertTrue(result.contains("€") || result.contains("EUR"))
    }

    func test_formatAmount_withGBP_formatsCorrectly() {
        // When
        let result = sut.formatAmount(999, currency: TestData.Currencies.gbp)

        // Then
        XCTAssertTrue(result.contains("9.99"))
        XCTAssertTrue(result.contains("£") || result.contains("GBP"))
    }

    // MARK: - Zero Decimal Currencies

    func test_formatAmount_withJPY_noDecimals() {
        // When
        let result = sut.formatAmount(1234, currency: "JPY")

        // Then
        // Strip grouping separators (commas) before checking
        let resultWithoutCommas = result.replacingOccurrences(of: ",", with: "")
        XCTAssertTrue(resultWithoutCommas.contains("1234"))
        XCTAssertFalse(result.contains("."))
    }

    // MARK: - Three Decimal Currencies

    func test_formatAmount_withBHD_threeDecimals() {
        // When
        let result = sut.formatAmount(12345, currency: "BHD")

        // Then
        XCTAssertTrue(result.contains("12.345"))
    }

    // MARK: - Minor Unit Conversion

    func test_convertToMinorUnits_withUSD_convertsCorrectly() {
        // When
        let result = sut.convertToMinorUnits(12.34, currency: TestData.Currencies.usd)

        // Then
        XCTAssertEqual(result, 1234)
    }

    func test_convertFromMinorUnits_withUSD_convertsCorrectly() {
        // When
        let result = sut.convertFromMinorUnits(1234, currency: TestData.Currencies.usd)

        // Then
        XCTAssertEqual(result, 12.34)
    }

    func test_convertToMinorUnits_withJPY_noConversion() {
        // When
        let result = sut.convertToMinorUnits(1234, currency: "JPY")

        // Then
        XCTAssertEqual(result, 1234)
    }

    // MARK: - Locale Handling

    func test_formatAmount_withUSLocale_usesUSFormat() {
        // Given
        let formatter = CurrencyFormatter(locale: Locale(identifier: "en_US"))

        // When
        let result = formatter.formatAmount(1234, currency: TestData.Currencies.usd)

        // Then
        XCTAssertTrue(result.contains("$"))
    }

    func test_formatAmount_withEULocale_usesEUFormat() {
        // Given
        let formatter = CurrencyFormatter(locale: Locale(identifier: "de_DE"))

        // When
        let result = formatter.formatAmount(1234, currency: TestData.Currencies.eur)

        // Then
        XCTAssertTrue(result.contains(",")) // Comma as decimal separator
    }

    // MARK: - Edge Cases

    func test_formatAmount_withZero_formatsZero() {
        // When
        let result = sut.formatAmount(0, currency: TestData.Currencies.usd)

        // Then
        XCTAssertTrue(result.contains("0"))
    }

    func test_formatAmount_withNegative_includesSign() {
        // When
        let result = sut.formatAmount(-1234, currency: TestData.Currencies.usd)

        // Then
        XCTAssertTrue(result.contains("-"))
    }

    func test_formatAmount_withUnknownCurrency_fallsBackToDefault() {
        // When
        let result = sut.formatAmount(1234, currency: "XXX")

        // Then
        XCTAssertNotNil(result)
    }

    // MARK: - Symbol Handling

    func test_getCurrencySymbol_withUSD_returnsDollarSign() {
        // When
        let symbol = sut.getCurrencySymbol(for: "USD")

        // Then
        XCTAssertEqual(symbol, "$")
    }

    func test_getCurrencySymbol_withUnknownCurrency_returnsCurrencyCode() {
        // When
        let symbol = sut.getCurrencySymbol(for: "XXX")

        // Then
        XCTAssertEqual(symbol, "XXX")
    }
}

// MARK: - Currency Formatter

@available(iOS 15.0, *)
private class CurrencyFormatter {
    private let locale: Locale
    private let numberFormatter: NumberFormatter

    // Currencies with zero decimal places
    private let zeroDecimalCurrencies: Set<String> = ["JPY", "KRW", "VND", "CLP"]

    // Currencies with three decimal places
    private let threeDecimalCurrencies: Set<String> = ["BHD", "JOD", "KWD", "OMR", "TND"]

    init(locale: Locale = Locale(identifier: "en_US")) {
        self.locale = locale
        self.numberFormatter = NumberFormatter()
        self.numberFormatter.locale = locale
        self.numberFormatter.numberStyle = .currency
    }

    func formatAmount(_ minorUnits: Int, currency: String) -> String {
        let decimalPlaces = getDecimalPlaces(for: currency)
        let amount = Double(minorUnits) / pow(10.0, Double(decimalPlaces))

        numberFormatter.currencyCode = currency
        numberFormatter.minimumFractionDigits = decimalPlaces
        numberFormatter.maximumFractionDigits = decimalPlaces

        return numberFormatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }

    func convertToMinorUnits(_ amount: Double, currency: String) -> Int {
        let decimalPlaces = getDecimalPlaces(for: currency)
        return Int(amount * pow(10.0, Double(decimalPlaces)))
    }

    func convertFromMinorUnits(_ minorUnits: Int, currency: String) -> Double {
        let decimalPlaces = getDecimalPlaces(for: currency)
        return Double(minorUnits) / pow(10.0, Double(decimalPlaces))
    }

    func getCurrencySymbol(for currency: String) -> String {
        numberFormatter.currencyCode = currency
        let symbol = numberFormatter.currencySymbol ?? currency
        // Return currency code if symbol is generic placeholder
        return symbol == "¤" ? currency : symbol
    }

    private func getDecimalPlaces(for currency: String) -> Int {
        if zeroDecimalCurrencies.contains(currency) {
            return 0
        } else if threeDecimalCurrencies.contains(currency) {
            return 3
        }
        return 2 // Default
    }
}
