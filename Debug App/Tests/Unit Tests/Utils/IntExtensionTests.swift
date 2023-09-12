//
//  IntExtensionTests.swift
//  PrimerSDK_Tests
//
//  Created by Carl Eriksson on 14/09/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class IntExtensionTests: XCTestCase {
    
    var amount: Int = 100
    let decimalSeparator = Locale.current.decimalSeparator ?? "."
    let groupingSeparator = Locale.current.groupingSeparator ?? ","
    
    func test_usd_formats_correctly() throws {
        let currency = Currency.USD
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "$1\(decimalSeparator)00", "Formatted amount [\(formattedAmount)] is not correct")
    }
    
    func test_gbp_formats_correctly() throws {
        let currency = Currency.GBP
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "£1\(decimalSeparator)00", "Formatted amount [\(formattedAmount)] is not correct")
    }
    
    func test_eur_formats_correctly() throws {
        let currency = Currency.EUR
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "€1\(decimalSeparator)00", "Formatted amount [\(formattedAmount)] is not correct")
    }
    
    func test_jpy_formats_correctly() throws {
        let currency = Currency.JPY
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "￥100", "Formatted amount [\(formattedAmount)] is not correct")
    }
    
    func test_krw_formats_correctly() throws {
        let currency = Currency.KRW
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "₩100", "Formatted amount [\(formattedAmount)] is not correct")
    }
    
    func test_sek_formats_correctly() throws {
        let currency = Currency.SEK
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "kr1\(decimalSeparator)00", "Formatted amount [\(formattedAmount)] is not correct")
    }
    
    func test_cny_formats_correctly() throws {
        let currency = Currency.CNY
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "CN¥1\(decimalSeparator)00", "Formatted amount [\(formattedAmount)] is not correct")
    }
    
    func test_usd_huge_amount_formats_correctly() throws {
        amount = 999999997
        let currency = Currency.USD
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "$9\(groupingSeparator)999\(groupingSeparator)999\(decimalSeparator)97", "Formatted amount [\(formattedAmount)] is not correct")
    }
    
    func test_jpy_huge_amount_formats_correctly() throws {
        amount = 999999999997
        let currency = Currency.JPY
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "￥999\(groupingSeparator)999\(groupingSeparator)999\(groupingSeparator)997", "Formatted amount [\(formattedAmount)] is not correct")
    }
    
    func test_usd_small_amount_formats_correctly() throws {
        amount = 1
        let currency = Currency.USD
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "$0\(decimalSeparator)01", "Formatted amount [\(formattedAmount)] is not correct")
    }
    
    func test_jpy_small_amount_formats_correctly() throws {
        amount = 1
        let currency = Currency.JPY
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "￥1", "Formatted amount [\(formattedAmount)] is not correct")
    }
}
