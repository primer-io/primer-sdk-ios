//
//  CodingUtilities.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

struct AnyEncodable: Encodable {

    var value: Encodable

    init(_ value: Encodable) {
        self.value = value
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension Encodable {
    var asJSONData: Data? {
        return try? JSONEncoder().encode(AnyEncodable(self))
    }
}
