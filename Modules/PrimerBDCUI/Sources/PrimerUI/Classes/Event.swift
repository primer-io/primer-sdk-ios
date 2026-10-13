//
//  Event.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

enum Event {
    case input(id: String, value: CodableValue, type: InputEventType)
    case click(id: String)

    func callAsFunction() -> CodableValue {
        switch self {
        case let .input(id, value, type):
            .object(["type": .string(type.rawValue), "id": .string(id), "value": value])
        case let .click(id):
            .object(["type": .string("click"), "id": .string(id)])
        }
    }
}

enum InputEventType: String {
    case onChange = "change"
}
