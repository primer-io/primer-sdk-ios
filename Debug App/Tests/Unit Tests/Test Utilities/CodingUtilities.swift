//
//  CodingUtilities.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 18/03/2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import Foundation

struct AnyEncodable : Encodable {

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
