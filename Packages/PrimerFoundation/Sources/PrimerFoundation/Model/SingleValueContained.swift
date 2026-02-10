//
//  SingleValueContained.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

public protocol SingleValueContained: Codable & Equatable, RawRepresentable where RawValue == String {}

public extension SingleValueContained {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard let value = Self(rawValue: try container.decode(String.self)) else {
            throw DecodingError.unexpectedValue(type: SingleValueContained.self, decoder: decoder)
        }
        self = value
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
