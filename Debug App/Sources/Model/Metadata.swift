//
//  Metadata.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

enum Metadata: Codable {
    case string(String)
    case bool(Bool)
    case int(Int)
    case double(Double)
    case array([Metadata])
    case dictionary([String: Metadata])
    case null
    
    init?(jsonObject string: String) {
        guard
            let data = string.data(using: .utf8),
            let metadata = try? JSONDecoder().decode(Metadata.self, from: data),
            case .dictionary = metadata else {
            return nil
        }
        self = metadata
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([Metadata].self) {
            self = .array(array)
        } else if let dict = try? container.decode([String: Metadata].self) {
            self = .dictionary(dict)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid metadata type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value): try container.encode(value)
        case let .bool(value): try container.encode(value)
        case let .int(value): try container.encode(value)
        case let .double(value): try container.encode(value)
        case let .array(value): try container.encode(value)
        case let .dictionary(value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    mutating func add(_ value: Metadata, forKey key: String) throws {
        if case var .dictionary(dict) = self {
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
