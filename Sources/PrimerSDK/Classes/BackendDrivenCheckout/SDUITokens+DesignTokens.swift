//
//  SDUITokens+DesignTokens.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerBDCUI
@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

extension SDUITokens {
    init(_ tokens: DesignTokens) {
        let values = Dictionary(
            Mirror(reflecting: tokens).children.compactMap { child in child.label.map { ($0, child.value) } },
            uniquingKeysWith: { first, _ in first }
        )
        func value<T>(_ tokenName: String, or name: String) -> T? {
            values[tokenName] as? T ?? values[name] as? T
        }
        self.init(
            color: { value(SDUITokenNames.color($0), or: $0) ?? .clear },
            spacing: { value(SDUITokenNames.spacing($0), or: $0) ?? 0 },
            radius: { value(SDUITokenNames.radius($0), or: $0) ?? 0 },
            size: { value(SDUITokenNames.size($0), or: $0) },
            font: { font in
                switch font {
                case "bodySmall": PrimerFont.bodySmall(tokens: tokens)
                case "bodyMedium": PrimerFont.bodyMedium(tokens: tokens)
                case "bodyLarge": PrimerFont.bodyLarge(tokens: tokens)
                case "headingLarge", "titleLarge": PrimerFont.titleLarge(tokens: tokens)
                case "headingMedium": PrimerFont.bodyMedium(tokens: tokens)
                case "caption": .caption
                default: .body
                }
            }
        )
    }
}

@available(iOS 15.0, *)
struct SDUIDesignTokens: ViewModifier {
    @StateObject private var manager = DesignTokensManager()
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .environment(\.sduiTokens, SDUITokens(manager.tokens ?? DesignTokens()))
            .task(id: colorScheme) {
                do {
                    try await manager.fetchTokens(for: colorScheme)
                } catch {
                    PrimerLogging.shared.logger.error(message: "[SDUI] Design tokens failed to load: \(error)")
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
