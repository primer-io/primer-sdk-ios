//
//  SDUITokenResolvers.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerBDCUI
import SwiftUI

enum SDUITokenResolvers {
    static func register() {
        resolveColor = { DesignTokens.value(named: $0) ?? .clear }
        resolveSpacing = { DesignTokens.value(named: $0) ?? 0 }
        resolveFont = { font in
            let tokens = DesignTokens.defaults
            return switch font {
            case "bodySmall": PrimerFont.bodySmall(tokens: tokens)
            case "bodyMedium": PrimerFont.bodyMedium(tokens: tokens)
            case "bodyLarge": PrimerFont.bodyLarge(tokens: tokens)
            case "headingLarge": PrimerFont.titleLarge(tokens: tokens)
            case "headingMedium": PrimerFont.bodyMedium(tokens: tokens)
            case "caption": .caption
            default: .body
            }
        }
    }
}

private extension DesignTokens {
    static let defaults = DesignTokens()

    static func value<T>(named name: String) -> T? {
        Mirror(reflecting: defaults).children.first { $0.label == name }?.value as? T
    }
}
