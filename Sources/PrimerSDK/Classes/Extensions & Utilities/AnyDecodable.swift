//
//  AnyDecodable.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

//
//  AnyDecodable.swift
//
//  Created Flight-School
//
//  License: https://github.com/Flight-School/AnyCodable/blob/master/LICENSE.md
//

// swiftlint:disable type_name
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
struct AnyDecodable: Decodable {
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
            self.init(array.map { $0.value })
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
		if lhs.value is NSNull, rhs.value is NSNull || lhs.value is Void, rhs.value is Void { return true }

		if let lDict = lhs.value as? [String: AnyDecodable],
		   let rDict = rhs.value as? [String: AnyDecodable] {
			return lDict == rDict
		}

		if let lArray = lhs.value as? [AnyDecodable],
		   let rArray = rhs.value as? [AnyDecodable] {
			return lArray == rArray
		}
		
		return (lhs.value as? Bool) == (rhs.value as? Bool) ||
		(lhs.value as? String) == (rhs.value as? String) ||
		(lhs.value as? Double) == (rhs.value as? Double) ||
		(lhs.value as? Float) == (rhs.value as? Float) ||
		(lhs.value as? Int) == (rhs.value as? Int) ||
		(lhs.value as? Int8) == (rhs.value as? Int8) ||
		(lhs.value as? Int16) == (rhs.value as? Int16) ||
		(lhs.value as? Int32) == (rhs.value as? Int32) ||
		(lhs.value as? Int64) == (rhs.value as? Int64) ||
		(lhs.value as? UInt) == (rhs.value as? UInt) ||
		(lhs.value as? UInt8) == (rhs.value as? UInt8) ||
		(lhs.value as? UInt16) == (rhs.value as? UInt16) ||
		(lhs.value as? UInt32) == (rhs.value as? UInt32) ||
		(lhs.value as? UInt64) == (rhs.value as? UInt64)
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
