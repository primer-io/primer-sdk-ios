//
//  MockDesignTokens.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable all

#if DEBUG
    import SwiftUI

    /// Mock design tokens for SwiftUI previews and testing
    /// Provides convenient access to both light and dark theme tokens
    @available(iOS 15.0, *)
    struct MockDesignTokens {
        // MARK: - Static Instances

        /// Light theme design tokens with default Primer values
        static let light: DesignTokens = // Create instance with default values
            .init()

        /// Dark theme design tokens with default Primer dark mode values
        static let dark: DesignTokens = {
            // Create light tokens with defaults
            let lightTokens = DesignTokens()

            // Create dark tokens from empty JSON to override colors
            let emptyJSON = "{}"
            let data = Data(emptyJSON.utf8)
            let decoder = JSONDecoder()
            let darkTokens = try! decoder.decode(DesignTokensDark.self, from: data)

            // Merge dark theme colors into light theme structure
            // Dark theme only overrides colors, everything else stays the same
            lightTokens.primerColorGray100 = darkTokens.primerColorGray100
            lightTokens.primerColorGray200 = darkTokens.primerColorGray200
            lightTokens.primerColorGray300 = darkTokens.primerColorGray300
            lightTokens.primerColorGray400 = darkTokens.primerColorGray400
            lightTokens.primerColorGray500 = darkTokens.primerColorGray500
            lightTokens.primerColorGray600 = darkTokens.primerColorGray600
            lightTokens.primerColorGray900 = darkTokens.primerColorGray900
            lightTokens.primerColorGray000 = darkTokens.primerColorGray000
            lightTokens.primerColorGreen500 = darkTokens.primerColorGreen500
            lightTokens.primerColorBrand = darkTokens.primerColorBrand
            lightTokens.primerColorRed100 = darkTokens.primerColorRed100
            lightTokens.primerColorRed500 = darkTokens.primerColorRed500
            lightTokens.primerColorRed900 = darkTokens.primerColorRed900
            lightTokens.primerColorBlue500 = darkTokens.primerColorBlue500
            lightTokens.primerColorBlue900 = darkTokens.primerColorBlue900

            return lightTokens
        }()

        // MARK: - Custom Token Creation

        /// Creates a custom DesignTokens instance for testing specific scenarios
        /// - Parameter modifications: A closure to modify the default light theme tokens
        /// - Returns: A customized DesignTokens instance
        static func custom(modifications: (DesignTokens) -> Void) -> DesignTokens {
            let tokens = DesignTokens()
            modifications(tokens)
            return tokens
        }
    }

#endif // DEBUG
// swiftlint:enable all
