//
//  ExpiryDateFormatter.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

import Foundation

public struct ExpiryDateFormatter: FieldFormatter {
    public init() {}
    public func format(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        let prefix = String(digits.prefix(4))
        if prefix.count > 2 {
            let month = prefix.prefix(2)
            let year = prefix.suffix(prefix.count - 2)
            return "\(month)/\(year)"
        }
        return prefix
    }
}
