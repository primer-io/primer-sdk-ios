//
//  UIElement.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

enum Element: UI {
    case button(ButtonProps)
    case checkbox(CheckboxProps)
    case column(ColumnProps)
    case container(ContainerProps)
    case passwordField(TextFieldProps)
    case row(RowProps)
    case text(TextProps)
    case textField(TextFieldProps)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(ComponentType.self, forKey: .type) {
        case .button: self = .button(try container.decode(ButtonProps.self, forKey: .props))
        case .checkbox: self = .checkbox(try container.decode(CheckboxProps.self, forKey: .props))
        case .column: self = .column(try container.decode(ColumnProps.self, forKey: .props))
        case .container: self = .container(try container.decode(ContainerProps.self, forKey: .props))
        case .passwordField: self = .passwordField(try container.decode(TextFieldProps.self, forKey: .props))
        case .row: self = .row(try container.decode(RowProps.self, forKey: .props))
        case .text: self = .text(try container.decode(TextProps.self, forKey: .props))
        case .textField: self = .textField(try container.decode(TextFieldProps.self, forKey: .props))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .button(props): try container.encode(.button, props: props)
        case let .checkbox(props): try container.encode(.checkbox, props: props)
        case let .column(props): try container.encode(.column, props: props)
        case let .container(props): try container.encode(.container, props: props)
        case let .passwordField(props): try container.encode(.passwordField, props: props)
        case let .row(props): try container.encode(.row, props: props)
        case let .text(props): try container.encode(.text, props: props)
        case let .textField(props): try container.encode(.textField, props: props)
        }
    }
}

private extension KeyedEncodingContainer<Element.CodingKeys> {
    mutating func encode(_ type: Element.ComponentType, props: UI) throws {
        try encode(type, forKey: .type)
        try encode(props, forKey: .props)
    }
}

private extension Element {
    enum CodingKeys: String, CodingKey {
        case type
        case props
    }

    enum ComponentType: String, Codable {
        case button = "Button"
        case checkbox = "Checkbox"
        case column = "Column"
        case container = "Container"
        case passwordField = "PasswordField"
        case row = "Row"
        case text = "Text"
        case textField = "TextField"
    }
}
