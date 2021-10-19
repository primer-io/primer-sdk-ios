//
//  AmountViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 14/10/21.
//

import Foundation

struct AmountViewModel {
    let amount: Int
    let currency: Currency

    var disabled = false

    var formattedAmount: String {
        return String(format: "%.2f", (Double(amount) / 100))
    }
    func toLocal() -> String {
        if disabled { return "" }
        switch currency {
        case .USD:
            return "$\(formattedAmount)"
        case .GBP:
            return "£\(formattedAmount)"
        case .EUR:
            return "€\(formattedAmount)"
        case .JPY:
            return "¥\(amount)"
        case .SEK:
            return "\(amount) SEK"
        case .NOK:
            return "$\(amount) NOK"
        case .DKK:
            return "$\(amount) DKK"
        default:
            return "\(amount)"
        }
    }
}
