//
//  IntExtension.swift
//  HeadlessUniversalCheckoutExample
//
//  Created by Evangelos on 16/2/22.
//

import Foundation

extension Int {
    func toCurrencyString(currencySymbol: String) -> String {
        let nf = NumberFormatter()
        nf.usesGroupingSeparator = true
        nf.groupingSeparator = Locale.current.groupingSeparator
        nf.groupingSize = 3
        nf.decimalSeparator = Locale.current.decimalSeparator
        nf.locale = Locale.current
        
        let amountAsNumber = NSDecimalNumber(value: self)
        var formattedAmountAsNumber = amountAsNumber
        
        formattedAmountAsNumber = amountAsNumber.dividing(by: 100)
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 2
        
        let formattedValue = nf.string(from: formattedAmountAsNumber)!
        
        return "\(currencySymbol) \(formattedValue)"
    }
}
