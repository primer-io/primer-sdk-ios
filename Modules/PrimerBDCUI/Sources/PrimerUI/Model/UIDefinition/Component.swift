//
//  Component.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

enum Component: Decodable, Hashable {
    case box(BoxProps)
    case button(Content, ButtonProps)
    case checkbox(CheckboxProps)
    case column(ColumnProps)
    case container(ContainerProps)
    case image(ImageProps)
    case navigation([UIDefinition], NavigationContainerProps)
    case progressIndicator(ProgressIndicatorProps)
    case radioButton(RadioButtonProps)
    case row(RowProps)
    case selectionOption(SelectionOptionProps)
    case list(Content, ListProps)
    case selectionGroup(SelectionGroupProps)
    case text(TextProps)
    case textField(TextFieldProps)
    case spacer
    case custom(type: String, props: CodableValue?)

    enum CodingKeys: String, CodingKey {
        case type
        case props
        case content
        case screens
    }
	
    enum ComponentType: String, Codable {
        case box = "Box"
        case button = "Button"
        case checkbox = "Checkbox"
        case column = "Column"
        case container = "Container"
        case list = "List"
        case navigation = "NavigationContainer"
        case progressIndicator = "ProgressIndicator"
        case radioButton = "RadioButton"
        case selectionOption = "SelectionOption"
        case selectionGroup = "SelectionGroup"
        case image = "Image"
        case textField = "TextField"
        case row = "Row"
        case text = "Text"
        case spacer = "Spacer"
    }
	
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawType = try container.decode(String.self, forKey: .type)
        guard let type = ComponentType(rawValue: rawType) else {
            self = .custom(
                type: rawType,
                props: try container.decodeIfPresent(CodableValue.self, forKey: .props)
            )
            return
        }
        switch type {
        case .box: self = .box(try container.decodeProps(BoxProps.self))
        case .button: self = .button(try container.decodeContent(), try container.decodeProps(ButtonProps.self))
        case .checkbox: self = .checkbox(try container.decodeProps(CheckboxProps.self))
        case .column: self = .column(try container.decodeProps(ColumnProps.self))
        case .container: self = .container(try container.decodeProps(ContainerProps.self))
        case .list: self = .list(try container.decodeContent(), try container.decodeProps(ListProps.self))
        case .navigation: self = .navigation(try container.decodeScreens(), try container.decodeProps(NavigationContainerProps.self))
        case .image: self = .image(try container.decodeProps(ImageProps.self))
        case .progressIndicator: self = .progressIndicator(try container.decodeProps(ProgressIndicatorProps.self))
        case .radioButton: self = .radioButton(try container.decodeProps(RadioButtonProps.self))
        case .row: self = .row(try container.decodeProps(RowProps.self))
        case .selectionOption: self = .selectionOption(try container.decodeProps(SelectionOptionProps.self))
        case .selectionGroup: self = .selectionGroup(try container.decodeProps(SelectionGroupProps.self))
        case .text: self = .text(try container.decodeProps(TextProps.self))
        case .textField: self = .textField(try container.decodeProps(TextFieldProps.self))
        case .spacer: self = .spacer
        }
    }
	
}

private extension KeyedDecodingContainer<Component.CodingKeys> {
    func decodeProps<T>(_ type: T.Type) throws -> T where T: Decodable { try decode(T.self, forKey: .props) }
    func decodeContent() throws -> Content { try decode(Content.self, forKey: .content) }
    func decodeScreens() throws -> [UIDefinition] { try decode([UIDefinition].self, forKey: .screens) }
}
