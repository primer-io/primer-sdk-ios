//
//  KWD_CurrencyFormattingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
@testable import PrimerSDK
import XCTest

final class KWD_CurrencyFormattingTests: XCTestCase {
    private let kwd = Currency(code: "KWD", decimalDigits: 3)

    func test_minorUnitDivisor_matchesDecimalDigits() {
        XCTAssertEqual(Currency(code: "JPY", decimalDigits: 0).minorUnitDivisor, 1)
        XCTAssertEqual(Currency(code: "USD", decimalDigits: 2).minorUnitDivisor, 100)
        XCTAssertEqual(kwd.minorUnitDivisor, 1000)
    }

    func test_formattedCurrencyAmount_dividesByTenToTheDecimalDigits() {
        XCTAssertEqual(8000.formattedCurrencyAmount(currency: kwd), Decimal(string: "8.000")!)
        XCTAssertEqual(1234.formattedCurrencyAmount(currency: kwd), Decimal(string: "1.234")!)
        XCTAssertEqual(1.formattedCurrencyAmount(currency: kwd), Decimal(string: "0.001")!)
    }

    func test_formattedCurrencyAmount_unchangedForZeroAndTwoDecimalCurrencies() {
        XCTAssertEqual(8000.formattedCurrencyAmount(currency: Currency(code: "USD", decimalDigits: 2)), Decimal(80))
        XCTAssertEqual(8000.formattedCurrencyAmount(currency: Currency(code: "ALL", decimalDigits: 2)), Decimal(80))
        XCTAssertEqual(8000.formattedCurrencyAmount(currency: Currency(code: "JPY", decimalDigits: 0)), Decimal(8000))
    }

    func test_toCurrencyString_usesThreeFractionDigits() {
        let formatted = 8000.toCurrencyString(currency: kwd, locale: Locale(identifier: "en_US"))
        XCTAssertTrue(formatted.contains("8.000"), "Expected three fraction digits, got [\(formatted)]")
    }
}
