//
//  Width.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation

enum Size: UI {
    case fill
    case wrap
    case literal(CGFloat)
    case token(String)
    
    func callAsFunction() -> CGFloat? {
        switch self {
        case .fill: .infinity
        case .wrap: nil
        case let .literal(value): value
        case let .token(name): resolveSize(name)
        }
    }
	
    init(codableValue: CodableValue) {
        switch codableValue {
        case .string("fill"): self = .fill
        case .string("wrap"): self = .wrap
        case let .string(string): self = Double(string).map { Size.literal($0) } ?? .token(string)
        case let .int(int): self = .literal(CGFloat(int))
        case let .double(double): self = .literal(double)
        default: self = .wrap
        }
    }
}
