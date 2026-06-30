//
//  ButtonProps.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

struct ButtonProps: UI {
    let variant: ButtonVariant
    let width: Size
    let height: Size
    let backgroundColor: String?
    let enabled: Bool
    let padding: CodableValue?
	
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.variant = (try? container.decode(ButtonVariant.self, forKey: .variant)) ?? .primary
        let width = (try? container.decode(CodableValue.self, forKey: .width)) ?? .string("wrap")
        let height = (try? container.decode(CodableValue.self, forKey: .height)) ?? .string("wrap")
        self.width = Size(codableValue: width)
        self.height = Size(codableValue: height)
        self.backgroundColor = try container.decodeIfPresent(String.self, forKey: .backgroundColor)
        self.enabled = (try? container.decode(Bool.self, forKey: .enabled)) ?? true
        self.padding = try container.decodeIfPresent(CodableValue.self, forKey: .padding)
    }
}

enum ButtonVariant: String, UI, SingleValueContained {
    case primary
    case secondary
    case tertiary
	
    func callAsFunction() -> any PrimitiveButtonStyle {
        switch self {
        case .primary: .automatic
        case .secondary: .plain
        case .tertiary: .plain
        }
    }
}
