//
//  TestData+Amounts.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
extension TestData {

    // MARK: - Payment Amounts

    enum Amounts {
        static let standard = 1000          // $10.00
        static let small = 100              // $1.00
        static let large = 100000           // $1,000.00
        static let withSurcharge = 2000     // $20.00
        static let zero = 0
    }

    // MARK: - Formatted Amounts

    enum FormattedAmounts {
        static let tenDollars = "$10.00"
        static let oneDollar = "$1.00"
        static let hundredDollars = "$100.00"
    }

    // MARK: - Currencies

    enum Currencies {
        static let usd = "USD"
        static let eur = "EUR"
        static let gbp = "GBP"
        static let jpy = "JPY"
        static let defaultDecimalDigits = 2
    }
}
