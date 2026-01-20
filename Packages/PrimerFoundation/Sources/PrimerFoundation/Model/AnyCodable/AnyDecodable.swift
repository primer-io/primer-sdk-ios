//
//  AnyDecodable.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

//
//  AnyDecodable.swift
//
//  Created Flight-School
//
//  License: https://github.com/Flight-School/AnyCodable/blob/master/LICENSE.md
//

// swiftlint:disable type_name
// swiftlint:disable cyclomatic_complexity
import Foundation

/**
 A type-erased `Decodable` value.
 The `AnyDecodable` type forwards decoding responsibilities
 to an underlying value, hiding its specific underlying type.
 You can decode mixed-type values in dictionaries
 and other collections that require `Decodable` conformance
 by declaring their contained type to be `AnyDecodable`:
 let json = """
 {
 "boolean": true,
 "integer": 42,
 "double": 3.141592653589793,
 "string": "string",
 "array": [1, 2, 3],
 "nested": {
 "a": "alpha",
 "b": "bravo",
 "c": "charlie"
 },
 "null": null
 }
 """.data(using: .utf8)!
 let decoder = JSONDecoder()
 let dictionary = try! decoder.decode([String: AnyDecodable].self, from: json)
 */
public struct AnyDecodable: Decodable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

@usableFromInline
protocol _AnyDecodable {
    var value: Any { get }
    init<T>(_ value: T?)
}

extension AnyDecodable: _AnyDecodable {}

extension _AnyDecodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.init(Self?.none)
        } else if let bool = try? container.decode(Bool.self) {
            self.init(bool)
        } else if let int = try? container.decode(Int.self) {
            self.init(int)
        } else if let uint = try? container.decode(UInt.self) {
            self.init(uint)
        } else if let double = try? container.decode(Double.self) {
            self.init(double)
        } else if let string = try? container.decode(String.self) {
            self.init(string)
        } else if let array = try? container.decode([AnyDecodable].self) {
            self.init(array.map(\.value))
        } else if let dictionary = try? container.decode([String: AnyDecodable].self) {
            self.init(dictionary.mapValues { $0.value })
        } else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "AnyDecodable value cannot be decoded")
        }
    }
}

extension AnyDecodable: Equatable {
    public static func == (lhs: AnyDecodable, rhs: AnyDecodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case is (NSNull, NSNull), is (Void, Void): true
        case let (lhs as Bool, rhs as Bool): lhs == rhs
        case let (lhs as Int, rhs as Int): lhs == rhs
        case let (lhs as Int8, rhs as Int8): lhs == rhs
        case let (lhs as Int16, rhs as Int16): lhs == rhs
        case let (lhs as Int32, rhs as Int32): lhs == rhs
        case let (lhs as Int64, rhs as Int64): lhs == rhs
        case let (lhs as UInt, rhs as UInt): lhs == rhs
        case let (lhs as UInt8, rhs as UInt8): lhs == rhs
        case let (lhs as UInt16, rhs as UInt16): lhs == rhs
        case let (lhs as UInt32, rhs as UInt32): lhs == rhs
        case let (lhs as UInt64, rhs as UInt64): lhs == rhs
        case let (lhs as Float, rhs as Float): lhs == rhs
        case let (lhs as Double, rhs as Double): lhs == rhs
        case let (lhs as String, rhs as String): lhs == rhs
        case let (lhs as [String: AnyDecodable], rhs as [String: AnyDecodable]): lhs == rhs
        case let (lhs as [AnyDecodable], rhs as [AnyDecodable]): lhs == rhs
        default: false
        }
    }
}

extension AnyDecodable: CustomStringConvertible {
    public var description: String {
        switch value {
        case is Void:
            return String(describing: nil as Any?)
        case let value as CustomStringConvertible:
            return value.description
        default:
            return String(describing: value)
        }
    }
}

extension AnyDecodable: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            return "AnyDecodable(\(value.debugDescription))"
        default:
            return "AnyDecodable(\(description))"
        }
    }
}

extension AnyDecodable: Hashable {
    public func hash(into hasher: inout Hasher) {
		if let value = value as? (any Hashable) {
			hasher.combine(value)
		}
    }
}
// swiftlint:enable type_name
// swiftlint:enable cyclomatic_complexity
