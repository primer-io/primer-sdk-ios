//
//  CodableValue.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public enum CodableValue: Codable, Equatable, Hashable, Sendable, CustomStringConvertible {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([CodableValue])
    case set(Set<CodableValue>)
    case object([String: CodableValue])
    case null
	
	public var string: String? {
		switch self {
		case let .string(string): string
		case let .int(int): String(int)
		case let .array(array): array.first.flatMap(\.string)
		default: nil
		}
	}
    
    public var description: String {
        do {
            return try jsonString
        } catch {
            return String(describing: self)
        }
    }
    
    public var jsonString: String {
        get throws {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8)!
        }

    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let int = try? container.decode(Int.self) { self = .int(int) }
        else if let double = try? container.decode(Double.self) { self = .double(double) }
        else if let bool = try? container.decode(Bool.self) { self = .bool(bool) }
        else if let string = try? container.decode(String.self) { self = .string(string) }
        else if let array = try? container.decode([CodableValue].self) { self = .array(array) }
        else if let object = try? container.decode([String: CodableValue].self) { self = .object(object) }
        else { throw DecodingError.unexpectedValue(type: CodableValue.self, decoder: decoder) }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(raw): try container.encode(raw)
        case let .int(raw): try container.encode(raw)
        case let .double(raw): try container.encode(raw)
        case let .bool(raw): try container.encode(raw)
        case let .set(raw): try container.encode(raw)
        case let .array(raw): try container.encode(raw)
        case let .object(raw): try container.encode(raw)
        case .null: try container.encodeNil()
        }
    }
}
