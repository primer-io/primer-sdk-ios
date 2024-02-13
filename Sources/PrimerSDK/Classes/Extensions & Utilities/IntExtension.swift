//
//  IntExtension.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 14/09/2021.
//

import Foundation

internal extension Int {
    func toCurrencyString(currency: Currency) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.groupingSeparator = Locale.current.groupingSeparator
        numberFormatter.groupingSize = 3
        numberFormatter.decimalSeparator = Locale.current.decimalSeparator
        numberFormatter.locale = Locale.current

        let amountAsNumber = NSDecimalNumber(value: self)
        var formattedAmountAsNumber = amountAsNumber

        if !currency.isZeroDecimal {
            formattedAmountAsNumber = amountAsNumber.dividing(by: 100)
            numberFormatter.maximumFractionDigits = 2
            numberFormatter.minimumFractionDigits = 2
        } else {
            numberFormatter.maximumFractionDigits = 0
            numberFormatter.minimumFractionDigits = 0
        }

        let formattedValue = numberFormatter.string(from: formattedAmountAsNumber)!

        if let symbol = currency.symbol {
            return "\(symbol)\(formattedValue)"
        } else {
            return "\(currency.code) \(formattedValue)"
        }
    }
}
