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

    /// Returns an accessibility-friendly currency string for VoiceOver
    /// Uses period as decimal separator to avoid VoiceOver misreading comma as thousands separator
    func toAccessibilityCurrencyString(currency: Currency, locale: Locale = Locale.current) -> String {
        let amount = Decimal(self) / currency.minorUnitDivisor

        // Get currency name in current locale (e.g., "euros", "dollars")
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = locale
        currencyFormatter.currencyCode = currency.code

        // Format with period as decimal separator for VoiceOver clarity
        let accessibilityFormatter = NumberFormatter()
        accessibilityFormatter.numberStyle = .decimal
        accessibilityFormatter.locale = Locale(identifier: "en_US") // Force period as decimal separator
        accessibilityFormatter.usesGroupingSeparator = false // No grouping separator for clarity
        accessibilityFormatter.minimumFractionDigits = currency.decimalDigits
        accessibilityFormatter.maximumFractionDigits = currency.decimalDigits

        guard let formattedNumber = accessibilityFormatter.string(from: amount as NSDecimalNumber) else {
            return "\(self) \(currency.code)"
        }

        // Get currency name from locale (e.g., "euro", "US dollar")
        let currencyName = locale.localizedString(forCurrencyCode: currency.code) ?? currency.code

        return "\(formattedNumber) \(currencyName)"
    }
}
