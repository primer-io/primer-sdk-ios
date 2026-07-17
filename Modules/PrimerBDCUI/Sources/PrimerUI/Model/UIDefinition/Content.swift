//
//  Content.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

struct Content: Hashable, Decodable {
    let children: [UIDefinition]

    private enum CodingKeys: String, CodingKey { case children }

    init(from decoder: Decoder) throws {
        if let keyed = try? decoder.container(keyedBy: CodingKeys.self), keyed.contains(.children) {
            self.children = try keyed.decode([UIDefinition].self, forKey: .children)
        } else {
            self.children = [try UIDefinition(from: decoder)]
        }
    }
}
