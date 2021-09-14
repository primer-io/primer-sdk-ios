//
//  IntExtension.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 14/09/2021.
//

internal extension Int {
    func toCurrencyString(currency: Currency) -> String {
        switch currency {
        case .USD: return String(format: "$%.2f", Float(self) / 100)
        case .EUR: return String(format: "€%.2f", Float(self) / 100)
        case .GBP: return String(format: "£%.2f", Float(self) / 100)
        // supported zero decimal currencies
        case .JPY: return "¥\(self)"
        case .KRW: return "₩\(self)"
        case .CLP: return "\(self) \(currency.rawValue)"
        // default to non-zero-decimal currency
        default:
            let formatted = String(format: "%.2f", Float(self) / 100)
            return "\(formatted) \(currency.rawValue)"
        }
    }
}
