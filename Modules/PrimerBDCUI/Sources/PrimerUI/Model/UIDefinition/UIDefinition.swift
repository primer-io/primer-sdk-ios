//
//  UIDefinition.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

typealias Slots = [String: UIDefinition]

public struct UIDefinition: Hashable, Decodable, Sendable {
    let component: Component
    let componentID: ComponentID?
    let visible: CodableValue?
    let children: [UIDefinition]?
    let slots: Slots?
    
    enum CodingKeys: String, CodingKey {
        case componentID = "id"
        case visible
        case children
        case slots
    }
    
    public var initialScreenID: String? {
        if case let .navigation(_, props) = component {
            props.initialScreenId
        } else {
            nil
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        component = try Component(from: decoder)
        componentID = try container.decodeIfPresent(String.self, forKey: .componentID)
        visible = try container.decodeIfPresent(CodableValue.self, forKey: .visible)
        children = try container.decodeIfPresent([UIDefinition].self, forKey: .children)
        slots = try container.decodeIfPresent(Slots.self, forKey: .slots)
    }
}
