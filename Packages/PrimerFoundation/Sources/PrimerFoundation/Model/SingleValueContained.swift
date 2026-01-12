//
//  SingleValueContained.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public protocol SingleValueContained: Codable & Hashable & Equatable, RawRepresentable where RawValue == String {}

public extension SingleValueContained {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = .init(rawValue: try container.decode(String.self))!
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(describing: self))
    }
}
