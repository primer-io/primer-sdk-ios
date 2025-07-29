//
//  IntExtension.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

extension Int {
    func toCurrencyString(currency: Currency, locale: Locale = Locale.current) -> String {
        let currencySymbol = currency.symbol ?? currency.code

        let numberFormatter = NumberFormatter()
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = locale
        numberFormatter.currencySymbol = currencySymbol
        numberFormatter.minimumFractionDigits = currency.isZeroDecimal ? 0 : 2
        numberFormatter.maximumFractionDigits = currency.isZeroDecimal ? 0 : 2

        // Convert amount to Decimal. If currency is zero decimal, no need to divide by 100
        let amount = currency.isZeroDecimal ? Decimal(self) : Decimal(self) / 100

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
        let numberFormatter = NumberFormatter()

        numberFormatter.usesGroupingSeparator = true
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = .current
        numberFormatter.currencySymbol = currency.symbol ?? currency.code
        numberFormatter.minimumFractionDigits = currency.isZeroDecimal ? 0 : 2
        numberFormatter.maximumFractionDigits = currency.isZeroDecimal ? 0 : 2

        // Convert amount to Decimal. If currency is zero decimal, no need to divide by 100
        return currency.isZeroDecimal ? Decimal(self) : Decimal(self) / 100
    }
}
