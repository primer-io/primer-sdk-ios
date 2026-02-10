//
//  Event.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation

public enum Event: Encodable {
    case input(id: String, value: CodableValue, type: InputEventType)
    case click(id: String)
    case custom(id: String, value: String)
    
    public var id: String {
        switch self {
        case let .input(id, _, _), let .click(id), let .custom(id, _): id
        }
    }
    
    public var value: Any? {
        switch self {
        case let .input(_, value, _): value
        case let .custom(_, value): value
        default: nil
        }
    }
    
    public var eventType: String {
        switch self {
        case let .input(_, _, eventType): eventType.rawValue
        case .click: "onClick"
        case .custom: "custom"
        }
    }
}

public enum InputEventType: String, Encodable {
    case onChange
    case onBlur
}
