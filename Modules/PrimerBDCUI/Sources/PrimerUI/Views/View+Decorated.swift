//
//  View+Decorated.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

extension View {
    func decorated(by props: some Props) -> some View {
        Decorated(props: props, content: self)
    }
}

private struct Decorated<P: Props, V: View>: View {
    @Environment(\.sduiTokens) private var tokens
    let props: P
    let content: V

    var body: some View {
        let radius = props.borderRadius?(tokens.radius) ?? 0
        return content
            .padding(props.padding.flatMap { Spacing.value(of: $0, resolve: tokens.spacing) } ?? .zero)
            .background(props.backgroundColor.map(tokens.color))
            .cornerRadius(radius)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(props.borderColor.map(tokens.color) ?? .clear, lineWidth: props.strokeWidth)
            )
    }
}

extension Props {
    var strokeWidth: CGFloat {
        borderWidth ?? (borderColor == nil ? 0 : 1)
    }
}

enum Spacing {
    static func value(of codableValue: CodableValue, resolve: (String) -> CGFloat) -> CGFloat? {
        switch codableValue {
        case let .string(name): Double(name) ?? resolve(name)
        case let .int(value): CGFloat(value)
        case let .double(value): value
        default: nil
        }
    }
}
