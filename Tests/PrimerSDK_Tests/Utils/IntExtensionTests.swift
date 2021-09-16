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
    
    func test_usd_formats_correctly() throws {
        let currency = Currency.USD
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "$1.00")
    }
    
    func test_gbp_formats_correctly() throws {
        let currency = Currency.GBP
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "£1.00")
    }
    
    func test_eur_formats_correctly() throws {
        let currency = Currency.EUR
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "€1.00")
    }
    
    func test_jpy_formats_correctly() throws {
        let currency = Currency.JPY
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "¥100")
    }
    
    func test_krw_formats_correctly() throws {
        let currency = Currency.KRW
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "₩100")
    }
    
    func test_sek_formats_correctly() throws {
        let currency = Currency.SEK
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "1.00 SEK")
    }
    
    func test_cny_formats_correctly() throws {
        let currency = Currency.CNY
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "1.00 CNY")
    }
    
    func test_usd_huge_amount_formats_correctly() throws {
        amount = 999999997
        let currency = Currency.USD
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "$9999999.97")
    }
    
    func test_krw_huge_amount_formats_correctly() throws {
        amount = 999999999997
        let currency = Currency.JPY
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "¥999999999997")
    }
    
    func test_usd_small_amount_formats_correctly() throws {
        amount = 1
        let currency = Currency.USD
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "$0.01")
    }
    
    func test_jpy_small_amount_formats_correctly() throws {
        amount = 1
        let currency = Currency.JPY
        let formattedAmount = amount.toCurrencyString(currency: currency)
        XCTAssertEqual(formattedAmount, "¥1")
    }
}
