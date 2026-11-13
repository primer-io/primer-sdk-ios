//
//  SDUITokenResolvers.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerBDCUI
import SwiftUI

enum SDUITokenResolvers {
    static func register() {
        resolveColor = { DesignTokens.value(named: SDUITokenNames.color($0)) ?? DesignTokens.value(named: $0) ?? .clear }
        resolveSpacing = { DesignTokens.value(named: SDUITokenNames.spacing($0)) ?? DesignTokens.value(named: $0) ?? 0 }
        resolveRadius = { DesignTokens.value(named: SDUITokenNames.radius($0)) ?? DesignTokens.value(named: $0) ?? 0 }
        resolveSize = { DesignTokens.value(named: SDUITokenNames.size($0)) ?? DesignTokens.value(named: $0) }
        resolveFont = { font in
            let tokens = DesignTokens.defaults
            return switch font {
            case "bodySmall": PrimerFont.bodySmall(tokens: tokens)
            case "bodyMedium": PrimerFont.bodyMedium(tokens: tokens)
            case "bodyLarge": PrimerFont.bodyLarge(tokens: tokens)
            case "headingLarge", "titleLarge": PrimerFont.titleLarge(tokens: tokens)
            case "headingMedium": PrimerFont.bodyMedium(tokens: tokens)
            case "caption": .caption
            default: .body
            }
        }
    }
}

enum SDUITokenNames {
    static func color(_ name: String) -> String { "primerColor" + pascal(name) }
    static func spacing(_ name: String) -> String { "primerSpace" + pascal(name) }
    static func radius(_ name: String) -> String { "primerRadius" + pascal(name) }
    static func size(_ name: String) -> String { "primerSize" + pascal(name) }

    private static func pascal(_ name: String) -> String {
        name.split(separator: "-").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
    }
}

private extension DesignTokens {
    static let defaults = DesignTokens()

    static func value<T>(named name: String) -> T? {
        Mirror(reflecting: defaults).children.first { $0.label == name }?.value as? T
    }
}
