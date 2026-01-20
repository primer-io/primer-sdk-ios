//
//  Currency.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// MARK: - Currency
public struct Currency: Codable {
    public let code: String
    public let decimalDigits: Int
    
    private enum CodingKeys: String, CodingKey {
        case code = "c"
        case decimalDigits = "m"
    }
    
    public init(code: String, decimalDigits: Int) {
        self.code = code
        self.decimalDigits = decimalDigits
    }
    
    public var symbol: String? {
        let localeIdentifier = Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: code])
        let locale = Locale(identifier: localeIdentifier)
        return locale.currencySymbol
    }

    public var isZeroDecimal: Bool {
        decimalDigits == 0
    }
}
