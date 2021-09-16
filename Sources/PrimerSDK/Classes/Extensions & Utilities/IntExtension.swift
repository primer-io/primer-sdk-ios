//
//  IntExtension.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 14/09/2021.
//

internal extension Int {
    func toCurrencyString(currency: Currency) -> String {
        var double = Double(self)
        if (!currency.isZeroDecimal) {
            double /= 100
        }
        let formattedValue = currency.format(value: double)
        return currency.withSymbol(for: formattedValue)
    }
}
