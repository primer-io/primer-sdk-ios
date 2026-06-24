//
//  Int.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@_spi(PrimerInternal)
public extension Int {
    func toCurrencyString(currency: Currency, locale: Locale = Locale.current) -> String {
        let currencySymbol = currency.symbol ?? currency.code

        let numberFormatter = NumberFormatter()
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = locale
        numberFormatter.currencySymbol = currencySymbol
        numberFormatter.minimumFractionDigits = currency.decimalDigits
        numberFormatter.maximumFractionDigits = currency.decimalDigits

        let amount = Decimal(self) / currency.minorUnitDivisor

        // Get formatted value with currency symbol
        guard let formattedValue = numberFormatter.string(from: amount as NSDecimalNumber) else {
            return "\(currencySymbol) \(self)"
        }

        // Determine symbol placement
        let isSymbolOnLeft = formattedValue.hasPrefix(currencySymbol)

        // Return properly formatted string
        if isSymbolOnLeft {
            return "\(currencySymbol)\(formattedValue.dropFirst(currencySymbol.count).trimmingCharacters(in: .whitespaces))"
        } else {
            return "\(formattedValue.dropLast(currencySymbol.count).trimmingCharacters(in: .whitespaces))\(currencySymbol)"
        }
    }

    func formattedCurrencyAmount(currency: Currency) -> Decimal {
        Decimal(self) / currency.minorUnitDivisor
    }
}
