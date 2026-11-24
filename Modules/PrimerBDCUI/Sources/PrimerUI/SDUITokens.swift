//
//  SDUITokens.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import SwiftUI

@_spi(PrimerInternal)
public struct SDUITokens {
    public var color: (String) -> Color
    public var spacing: (String) -> CGFloat
    public var radius: (String) -> CGFloat
    public var size: (String) -> CGFloat?
    public var font: (String) -> Font

    public init(
        color: @escaping (String) -> Color,
        spacing: @escaping (String) -> CGFloat,
        radius: @escaping (String) -> CGFloat,
        size: @escaping (String) -> CGFloat?,
        font: @escaping (String) -> Font
    ) {
        self.color = color
        self.spacing = spacing
        self.radius = radius
        self.size = size
        self.font = font
    }

    static var unprovided: SDUITokens {
        SDUITokens(
            color: { missing("color", token: $0, fallback: .clear) },
            spacing: { missing("spacing", token: $0, fallback: 0) },
            radius: { missing("radius", token: $0, fallback: 0) },
            size: { missing("size", token: $0, fallback: nil) },
            font: { missing("font", token: $0, fallback: .body) }
        )
    }
}

private struct SDUITokensKey: EnvironmentKey {
    static var defaultValue: SDUITokens { .unprovided }
}

@_spi(PrimerInternal)
public extension EnvironmentValues {
    var sduiTokens: SDUITokens {
        get { self[SDUITokensKey.self] }
        set { self[SDUITokensKey.self] = newValue }
    }
}

private func missing<T>(_ kind: String, token: String, fallback: T) -> T {
    let message = "No SDUITokens in the environment — cannot resolve \(kind) token '\(token)'"
    log(message, type: .error)
    assertionFailure(message)
    return fallback
}
