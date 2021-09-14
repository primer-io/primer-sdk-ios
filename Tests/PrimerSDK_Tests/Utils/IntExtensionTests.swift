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
    
    let amount: Int = 100
    
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
}
