//
//  EncodingDecodingContainerExtensions.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation

public extension KeyedEncodingContainer {
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
}
