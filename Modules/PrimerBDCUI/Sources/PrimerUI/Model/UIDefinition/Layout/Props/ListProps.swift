//
//  ListProps.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

struct ListProps: Selectable {
    let values: Set<String>
    let mode: SelectionMode
    let dataSource: Array<CodableValue>
	
    enum CodingKeys: String, CodingKey {
        case values = "value"
        case mode
        case dataSource
    }
	
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        values = (try? container.decode(Set<String>.self, forKey: .values)) ?? []
        mode = try container.decode(SelectionMode.self, forKey: .mode)
        dataSource = try container.decode(Array<CodableValue>.self, forKey: .dataSource)
    }
}
