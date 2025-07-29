//
//  Currency.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// MARK: - Currency
public struct Currency: Codable {
    public let code: String
    public let decimalDigits: Int

    enum CodingKeys: String, CodingKey {
        case code = "c"
        case decimalDigits = "m"
    }

    internal var symbol: String? {
        let localeIdentifier = Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: code])
        let locale = Locale(identifier: localeIdentifier)
        return locale.currencySymbol
    }

    internal var isZeroDecimal: Bool {
        decimalDigits == 0
    }
}
