//
//  EncodingDecodingContainerExtensions.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 4/3/23.
//

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
            if let boolVal = entryVal as? Bool {
                try nestedContainer.encode(boolVal, forKey: JSONCodingKeys(stringValue: entryKey)!)
            } else if let intVal = entryVal as? Int {
                try nestedContainer.encode(intVal, forKey: JSONCodingKeys(stringValue: entryKey)!)
            } else if let floatVal = entryVal as? Float {
                try nestedContainer.encode(floatVal, forKey: JSONCodingKeys(stringValue: entryKey)!)
            } else if let doubleVal = entryVal as? Double {
                try nestedContainer.encode(doubleVal, forKey: JSONCodingKeys(stringValue: entryKey)!)
            } else if let stringVal = entryVal as? String {
                try nestedContainer.encode(stringVal, forKey: JSONCodingKeys(stringValue: entryKey)!)
            } else {
                if !mapNilToUndefined {
                    try nestedContainer.encodeNil(forKey: JSONCodingKeys(stringValue: entryKey)!)
                }
            }
        }
    }
}

extension KeyedDecodingContainer {

    func decode(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> [String: Any] {
        let container = try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.decode(type)
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

    func decode(_ type: Array<Any>.Type, forKey key: K) throws -> [Any] {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }

    func decodeIfPresent(_ type: Array<Any>.Type, forKey key: K) throws -> [Any]? {
        guard contains(key) else {
            return nil
        }
        guard try decodeNil(forKey: key) == false else {
            return nil
        }
        return try decode(type, forKey: key)
    }

    func decode(_ type: Dictionary<String, Any>.Type) throws -> [String: Any] {
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
            } else if let nestedArray = try? decode(Array<Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
        }
        return dictionary
    }
}

extension UnkeyedDecodingContainer {

    mutating func decode(_ type: Array<Any>.Type) throws -> [Any] {
        var array: [Any] = []
        while isAtEnd == false {
            // See if the current value in the JSON array is `null` first and prevent infite recursion with nested arrays.
            if try decodeNil() {
                continue
            } else if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let nestedDictionary = try? decode(Dictionary<String, Any>.self) {
                array.append(nestedDictionary)
            } else if let nestedArray = try? decode(Array<Any>.self) {
                array.append(nestedArray)
            }
        }
        return array
    }

    mutating func decode(_ type: Dictionary<String, Any>.Type) throws -> [String: Any] {
        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKeys.self)
        return try nestedContainer.decode(type)
    }
}
