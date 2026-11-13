//
//  Length.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

enum Length: UI {
    case literal(CGFloat)
    case token(String)

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let number = try? container.decode(Double.self) {
            self = .literal(number)
        } else {
            let string = try container.decode(String.self)
            self = Double(string).map { .literal($0) } ?? .token(string)
        }
    }

    func callAsFunction(_ resolve: (String) -> CGFloat?) -> CGFloat? {
        switch self {
        case let .literal(value): value
        case let .token(name): resolve(name)
        }
    }
}
