//
//  View+Decorated.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

extension View {
    func decorated(by props: some Props) -> some View {
        let radius = props.borderRadius?(resolveRadius) ?? 0
        return padding(props.padding.flatMap(Spacing.value) ?? .zero)
            .background(props.backgroundColor.map(resolveColor))
            .cornerRadius(radius)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(props.borderColor.map(resolveColor) ?? .clear, lineWidth: props.strokeWidth)
            )
    }
}

extension Props {
    var strokeWidth: CGFloat {
        borderWidth ?? (borderColor == nil ? 0 : 1)
    }
}

enum Spacing {
    static func value(of codableValue: CodableValue) -> CGFloat? {
        switch codableValue {
        case let .string(name): Double(name) ?? resolveSpacing(name)
        case let .int(value): CGFloat(value)
        case let .double(value): value
        default: nil
        }
    }
}
