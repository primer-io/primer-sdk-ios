//
//  EncodingDecodingContainerExtensions.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// Inspired by https://gist.github.com/mbuchetics/c9bc6c22033014aa0c550d3b4324411a

struct JSONCodingKeys: CodingKey {
    var stringValue: String

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?

    init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}

extension KeyedEncodingContainer {

    mutating func encodeIfPresent(_ dictionary: [String: Any]?, forKey key: KeyedEncodingContainer<K>.Key, mapNilToUndefined: Bool = false) throws {
        guard let dictionary = dictionary else {
            if !mapNilToUndefined {
                try encodeNil(forKey: key)
            }
            return
        }
        try encode(dictionary, forKey: key, mapNilToUndefined: mapNilToUndefined)
    }

    mutating func encode(_ dictionary: [String: Any], forKey key: KeyedEncodingContainer<K>.Key, mapNilToUndefined: Bool = false) throws {
        var nestedContainer = nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)

        for (entryKey, entryVal) in dictionary {
            guard let key = JSONCodingKeys(stringValue: entryKey) else {
                PrimerLogging.shared.logger.warn(message:
                                                    "Expected to encode value in container of type \(K.self), but key '\(entryKey) was not valid"
                )
                continue
            }
            if let boolVal = entryVal as? Bool {
                try nestedContainer.encode(boolVal, forKey: key)
            } else if let intVal = entryVal as? Int {
                try nestedContainer.encode(intVal, forKey: key)
            } else if let floatVal = entryVal as? Float {
                try nestedContainer.encode(floatVal, forKey: key)
            } else if let doubleVal = entryVal as? Double {
                try nestedContainer.encode(doubleVal, forKey: key)
            } else if let stringVal = entryVal as? String {
                try nestedContainer.encode(stringVal, forKey: key)
            } else if let dictVal = entryVal as? [String: Any] {
                try nestedContainer.encode(dictVal, forKey: key)
            } else if let arrayVal = entryVal as? [Any] {
                try nestedContainer.encode(arrayVal, forKey: key)
            } else if !mapNilToUndefined {
                try nestedContainer.encodeNil(forKey: key)
            }
        }
    }

    mutating func encode(_ array: [Any], forKey key: KeyedEncodingContainer<K>.Key, mapNilToUndefined: Bool = false) throws {
        var nestedContainer = nestedUnkeyedContainer(forKey: key)

        for entryVal in array {
            if let boolVal = entryVal as? Bool {
                try nestedContainer.encode(boolVal)
            } else if let intVal = entryVal as? Int {
                try nestedContainer.encode(intVal)
            } else if let floatVal = entryVal as? Float {
                try nestedContainer.encode(floatVal)
            } else if let doubleVal = entryVal as? Double {
                try nestedContainer.encode(doubleVal)
            } else if let stringVal = entryVal as? String {
                try nestedContainer.encode(stringVal)
            } else if !mapNilToUndefined {
                try nestedContainer.encodeNil()
            }
        }
    }
}

extension KeyedDecodingContainer {

    func decode(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> [String: Any] {
        let container = try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.decode()
    }

    func decodeIfPresent(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> [String: Any]? {
        guard contains(key) else {
            return nil
        }
        guard try decodeNil(forKey: key) == false else {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decode(forKey key: K) throws -> [Any] {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode()
    }

    func decode() throws -> [String: Any] {
        var dictionary = [String: Any]()

        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            } else if let nestedDictionary = try? decode(Dictionary<String, Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            } else if let nestedArray = try? decode(forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
        }
        return dictionary
    }
}

extension UnkeyedDecodingContainer {

    mutating func decode() throws -> [Any] {
        var array: [Any] = []
        while isAtEnd == false {
            // See if the current value in the JSON array is `null` first and prevent infite recursion with nested arrays.
            if try decodeNil() {
                continue
            } else if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(Int.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let nestedDictionary = try? decode(Dictionary<String, Any>.self) {
                array.append(nestedDictionary)
            } else if let nestedArray = try? decode() {
                array.append(nestedArray)
            }
        }
        return array
    }

    mutating func decode(_ type: Dictionary<String, Any>.Type) throws -> [String: Any] {
        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKeys.self)
        return try nestedContainer.decode()
    }
}
