//
//  PrimerFont.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Typography utility providing Inter variable fonts with design token integration.
///
/// Architecture:
/// - **Base Function**: Core font creation (`uiFont`)
/// - **UIKit Helpers**: Typography helpers returning `UIFont`
/// - **SwiftUI Helpers**: Typography helpers wrapping UIKit helpers in `Font(...)`
/// - **Semantic Helpers**: Named helpers mapping to typography styles
///
/// Custom Font Support:
/// All typography flows through `uiFont()` → `variableInterFont()` which attempts to load
/// the Inter variable font with proper weight variation. Falls back to system fonts.
@available(iOS 15.0, *)
struct PrimerFont {

    // MARK: - Base Font Function

    /// Creates a UIFont with design token parameters.
    ///
    /// All typography flows through this function to ensure consistent Inter variable font loading.
    ///
    /// - Parameters:
    ///   - family: Font family name (defaults to "Inter")
    ///   - weight: Font weight as numeric value (100-900, defaults to 400)
    ///   - size: Font size in points (defaults to 14)
    ///   - isItalic: Whether to apply italic style (defaults to false)
    /// - Returns: UIFont with Inter variable font or system font fallback
    static func uiFont(
        family: String?,
        weight: CGFloat?,
        size: CGFloat?,
        isItalic: Bool = false
    ) -> UIFont {
        let fontFamily = family ?? "Inter"
        let fontSize = size ?? 14
        let fontWeight = weight ?? 400

        // Attempt to load Inter variable font
        if fontFamily == "Inter" {
            if let customUIFont = variableInterFont(weight: fontWeight, size: fontSize) {
                return customUIFont
            }
        }

        // Fallback to system font
        return .systemFont(ofSize: fontSize, weight: uiFontWeightFromNumber(fontWeight))
    }

    // MARK: - UIKit Typography Helpers

    /// Title extra large (24pt, weight 500) - for major section titles
    static func uiFontTitleXLarge(tokens: DesignTokens?) -> UIFont {
        guard let tokens = tokens else {
            return uiFont(family: "Inter", weight: 500, size: 24)
        }
        return uiFont(
            family: tokens.primerTypographyTitleXlargeFont,
            weight: tokens.primerTypographyTitleXlargeWeight,
            size: tokens.primerTypographyTitleXlargeSize
        )
    }

    /// Title large (16pt, weight 500) - for subsection titles
    static func uiFontTitleLarge(tokens: DesignTokens?) -> UIFont {
        guard let tokens = tokens else {
            return uiFont(family: "Inter", weight: 500, size: 16)
        }
        return uiFont(
            family: tokens.primerTypographyTitleLargeFont,
            weight: tokens.primerTypographyTitleLargeWeight,
            size: tokens.primerTypographyTitleLargeSize
        )
    }

    /// Body large (16pt, weight 400) - for large body text
    static func uiFontBodyLarge(tokens: DesignTokens?) -> UIFont {
        guard let tokens = tokens else {
            return uiFont(family: "Inter", weight: 400, size: 16)
        }
        return uiFont(
            family: tokens.primerTypographyBodyLargeFont,
            weight: tokens.primerTypographyBodyLargeWeight,
            size: tokens.primerTypographyBodyLargeSize
        )
    }

    /// Body medium (14pt, weight 400) - for standard body text
    static func uiFontBodyMedium(tokens: DesignTokens?) -> UIFont {
        guard let tokens = tokens else {
            return uiFont(family: "Inter", weight: 400, size: 14)
        }
        return uiFont(
            family: tokens.primerTypographyBodyMediumFont,
            weight: tokens.primerTypographyBodyMediumWeight,
            size: tokens.primerTypographyBodyMediumSize
        )
    }

    /// Body small (12pt, weight 400) - for small body text and captions
    static func uiFontBodySmall(tokens: DesignTokens?) -> UIFont {
        guard let tokens = tokens else {
            return uiFont(family: "Inter", weight: 400, size: 12)
        }
        return uiFont(
            family: tokens.primerTypographyBodySmallFont,
            weight: tokens.primerTypographyBodySmallWeight,
            size: tokens.primerTypographyBodySmallSize
        )
    }

    /// Large icon font (48pt, weight 400) - for large icon displays
    static func uiFontLargeIcon(tokens: DesignTokens?) -> UIFont {
        return uiFont(family: "Inter", weight: 400, size: 48)
    }

    /// Extra large icon font (56pt, weight 400) - for extra large icon displays
    static func uiFontExtraLargeIcon(tokens: DesignTokens?) -> UIFont {
        let size = tokens?.primerSizeXxxlarge ?? 56
        return uiFont(family: "Inter", weight: 400, size: size)
    }

    /// Small badge font (10pt, weight 500) - for compact badge text
    static func uiFontSmallBadge(tokens: DesignTokens?) -> UIFont {
        return uiFont(family: "Inter", weight: 500, size: 10)
    }

    // MARK: - SwiftUI Typography Helpers

    /// Title extra large (24pt, weight 500) - for major section titles
    static func titleXLarge(tokens: DesignTokens?) -> Font {
        return Font(uiFontTitleXLarge(tokens: tokens))
    }

    /// Title large (16pt, weight 500) - for subsection titles
    static func titleLarge(tokens: DesignTokens?) -> Font {
        return Font(uiFontTitleLarge(tokens: tokens))
    }

    /// Body large (16pt, weight 400) - for large body text
    static func bodyLarge(tokens: DesignTokens?) -> Font {
        return Font(uiFontBodyLarge(tokens: tokens))
    }

    /// Body medium (14pt, weight 400) - for standard body text
    static func bodyMedium(tokens: DesignTokens?) -> Font {
        return Font(uiFontBodyMedium(tokens: tokens))
    }

    /// Body small (12pt, weight 400) - for small body text and captions
    static func bodySmall(tokens: DesignTokens?) -> Font {
        return Font(uiFontBodySmall(tokens: tokens))
    }

    /// Large icon font (48pt, weight 400) - for large icon displays
    static func largeIcon(tokens: DesignTokens?) -> Font {
        return Font(uiFontLargeIcon(tokens: tokens))
    }

    /// Extra large icon font (56pt, weight 400) - for extra large icon displays
    static func extraLargeIcon(tokens: DesignTokens?) -> Font {
        return Font(uiFontExtraLargeIcon(tokens: tokens))
    }

    /// Small badge font (10pt, weight 500) - for compact badge text
    static func smallBadge(tokens: DesignTokens?) -> Font {
        return Font(uiFontSmallBadge(tokens: tokens))
    }

    // MARK: - Semantic Font Helpers

    /// Standard body text - maps to `bodyMedium` (14pt)
    static func body(tokens: DesignTokens?) -> Font {
        return bodyMedium(tokens: tokens)
    }

    /// Secondary or supporting text - maps to `bodySmall` (12pt)
    static func caption(tokens: DesignTokens?) -> Font {
        return bodySmall(tokens: tokens)
    }

    /// Emphasized text - maps to `titleLarge` (16pt, medium weight)
    static func headline(tokens: DesignTokens?) -> Font {
        return titleLarge(tokens: tokens)
    }

    /// Section titles - maps to `titleXLarge` (24pt)
    static func title2(tokens: DesignTokens?) -> Font {
        return titleXLarge(tokens: tokens)
    }

    /// Supporting or secondary text - maps to `bodyMedium` (14pt)
    static func subheadline(tokens: DesignTokens?) -> Font {
        return bodyMedium(tokens: tokens)
    }

    // MARK: - Private Helpers

    /// Loads Inter variable font with specified weight using font descriptor API.
    ///
    /// Variable fonts use font descriptors with variation axes to access different weights.
    /// The weight variation axis is specified using the 'wght' tag (2003265652).
    ///
    /// Returns nil if Inter variable font is not available, allowing fallback to system font.
    ///
    /// - Parameters:
    ///   - weight: Font weight (100-900)
    ///   - size: Font size in points
    /// - Returns: Inter variable font if available, nil otherwise
    private static func variableInterFont(weight: CGFloat, size: CGFloat) -> UIFont? {
        // Use the registered PostScript name for InterVariable.ttf
        let descriptor = UIFontDescriptor(fontAttributes: [
            .name: "InterVariable",
            kCTFontVariationAttribute as UIFontDescriptor.AttributeName: [
                2003265652: weight  // 'wght' variation axis
            ]
        ])

        let font = UIFont(descriptor: descriptor, size: size)

        // Verify Inter font loaded (not system font fallback)
        if font.familyName.contains("Inter") {
            return font
        }

        return nil
    }

    /// Converts numeric font weight to UIFont.Weight enum.
    ///
    /// - Parameter weight: Numeric weight (100-900)
    /// - Returns: Corresponding UIFont.Weight value
    private static func uiFontWeightFromNumber(_ weight: CGFloat) -> UIFont.Weight {
        switch weight {
        case 100: return .ultraLight
        case 200: return .thin
        case 300: return .light
        case 400: return .regular
        case 500: return .medium
        case 550: return .medium  // Design tokens use 550
        case 600: return .semibold
        case 700: return .bold
        case 800: return .heavy
        case 900: return .black
        default: return .regular
        }
    }
}
