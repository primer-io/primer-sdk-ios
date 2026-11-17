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
    let borderColor: String?
    let enabled: Bool
    let padding: CodableValue?
    let borderRadius: Length?

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        variant = (try? container.decode(ButtonVariant.self, forKey: .variant)) ?? .primary
        let width = (try? container.decode(CodableValue.self, forKey: .width)) ?? .string("wrap")
        let height = (try? container.decode(CodableValue.self, forKey: .height)) ?? .string("wrap")
        self.width = Size(codableValue: width)
        self.height = Size(codableValue: height)
        backgroundColor = try container.decodeIfPresent(String.self, forKey: .backgroundColor)
        borderColor = try container.decodeIfPresent(String.self, forKey: .borderColor)
        enabled = (try? container.decode(Bool.self, forKey: .enabled)) ?? true
        padding = try container.decodeIfPresent(CodableValue.self, forKey: .padding)
        borderRadius = try container.decodeIfPresent(Length.self, forKey: .borderRadius)
    }
}

enum ButtonVariant: String, UI, SingleValueContained {
    case primary
    case secondary
    case tertiary
}

struct ButtonStyling: Equatable {
    let backgroundColor: String?
    let borderColor: String?
    let foregroundColor: String?
    let borderRadius: Length
}

extension ButtonProps {
    var styling: ButtonStyling {
        let radius = borderRadius ?? .token("medium")
        return switch variant {
        case .primary:
            ButtonStyling(
                backgroundColor: backgroundColor ?? "primerColorBrand",
                borderColor: borderColor,
                foregroundColor: "primerColorGray000",
                borderRadius: radius
            )
        case .secondary:
            ButtonStyling(
                backgroundColor: backgroundColor ?? "background-primary",
                borderColor: borderColor ?? "border-outlined-default",
                foregroundColor: "text-primary",
                borderRadius: radius
            )
        case .tertiary:
            ButtonStyling(backgroundColor: backgroundColor, borderColor: borderColor, foregroundColor: nil, borderRadius: radius)
        }
    }
}
