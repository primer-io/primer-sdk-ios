//
//  Metadata.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

enum Metadata: Codable {
    case string(String)
    case bool(Bool)
    case dictionary([String: Metadata])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let dict = try? container.decode([String: Metadata].self) {
            self = .dictionary(dict)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid metadata type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .dictionary(let value): try container.encode(value)
        }
    }

    mutating func add(_ value: Metadata, forKey key: String) throws {
        if case .dictionary(var dict) = self {
            dict[key] = value
            self = .dictionary(dict)
        } else {
            throw MetadataError.notDictionary
        }
    }

    enum MetadataError: Error {
        case notDictionary
    }
}
