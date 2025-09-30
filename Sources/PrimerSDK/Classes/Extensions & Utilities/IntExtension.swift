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
		numberFormatter.minimumFractionDigits = currency.decimalDigits
		numberFormatter.maximumFractionDigits = currency.decimalDigits

		let factor = pow(10, currency.decimalDigits)
		let amount = Decimal(self) / factor

		guard let formattedValue = numberFormatter.string(from: amount as NSDecimalNumber) else {
			return "\(currencySymbol) \(self)"
		}

		// Respect locale’s symbol placement instead of forcing left/right
		return formattedValue
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
