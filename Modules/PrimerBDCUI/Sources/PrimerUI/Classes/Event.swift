//
//  Event.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

enum Event {
    case input(id: String, value: CodableValue, type: InputEventType)
    case click(id: String)
    case provider(type: String, id: String?, data: [String: CodableValue])

    func callAsFunction() -> CodableValue {
        switch self {
        case let .input(id, value, type):
            .object(["type": .string(type.rawValue), "id": .string(id), "value": value])
        case let .click(id):
            .object(["type": .string("click"), "id": .string(id)])
        case let .provider(type, id, data):
            .object(data.merging(["type": .string(type), "id": id.map(CodableValue.string)].compactMapValues { $0 }) { $1 })
        }
    }
}

enum InputEventType: String {
    case onChange = "change"
}
