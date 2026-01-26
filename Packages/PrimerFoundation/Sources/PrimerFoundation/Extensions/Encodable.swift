//
//  Encodable.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data,
                                                                options: .allowFragments) as? [String: Any] else {
            let error = NSError(domain: "EncodableError",
                                code: 1001,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to serialize object to dictionary"])
            throw error
        }
        return dictionary
    }
}
