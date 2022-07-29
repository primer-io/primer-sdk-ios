//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import Foundation

internal extension Int {
    func toCurrencyString(currency: Currency) -> String {
        let nf = NumberFormatter()
        nf.usesGroupingSeparator = true
        nf.groupingSeparator = Locale.current.groupingSeparator
        nf.groupingSize = 3
        nf.decimalSeparator = Locale.current.decimalSeparator
        nf.locale = Locale.current
        
        let amountAsNumber = NSDecimalNumber(value: self)
        var formattedAmountAsNumber = amountAsNumber
        
        if !currency.isZeroDecimal {
            formattedAmountAsNumber = amountAsNumber.dividing(by: 100)
            nf.maximumFractionDigits = 2
            nf.minimumFractionDigits = 2
        } else {
            nf.maximumFractionDigits = 0
            nf.minimumFractionDigits = 0
        }
        
        let formattedValue = nf.string(from: formattedAmountAsNumber)!
        
        if let symbol = currency.symbol {
            return "\(symbol)\(formattedValue)"
        } else {
            return "\(currency.rawValue) \(formattedValue)"
        }
    }
}

#endif
