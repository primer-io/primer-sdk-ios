//
//  SelectionGroupProps.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

struct SelectionGroupProps: Selectable {
    let distribution: Distribution
    let values: Set<String>
    let mode: SelectionMode
	
    enum CodingKeys: String, CodingKey {
        case distribution
        case values = "value"
        case mode
    }
	
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.distribution = try container.decode(Distribution.self, forKey: .distribution)
        self.values = (try? container.decode(Set<String>.self, forKey: .values)) ?? []
        self.mode = try container.decode(SelectionMode.self, forKey: .mode)
    }
}
