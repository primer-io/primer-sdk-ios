//
//  PrimerFont.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Style Dictionary Generator on 30.6.25.
//

import SwiftUI

/// Font utility for CheckoutComponents that provides Inter variable fonts
/// with fallback to system fonts based on design tokens.
@available(iOS 15.0, *)
struct PrimerFont {

    // MARK: - Font Family Names

    private static let interVariableFont = "InterVariable"
    private static let interVariableItalicFont = "InterVariable-Italic"

    // MARK: - Design Token Integration

    /// Get font based on design tokens with proper weight and size
    static func font(
        family: String?,
        weight: CGFloat?,
        size: CGFloat?,
        isItalic: Bool = false
    ) -> Font {
        let fontFamily = family ?? "Inter"
        let fontSize = size ?? 14
        let fontWeight = weight ?? 400

        // Convert numeric weight to Font.Weight
        let swiftUIWeight = weightFromNumber(fontWeight)

        // Try to use custom Inter font if family matches
        if fontFamily == "Inter" {
            let fontName = isItalic ? interVariableItalicFont : interVariableFont

            if let customFont = customFont(name: fontName, size: fontSize) {
                return customFont
            }
        }

        // Fallback to system font with appropriate weight
        return .system(size: fontSize, weight: swiftUIWeight, design: .default)
    }

    // MARK: - Typography Design Token Helpers

    /// Font for title extra large based on design tokens
    static func titleXLarge(tokens: DesignTokens?) -> Font {
        guard let tokens = tokens else {
            return font(family: "Inter", weight: 500, size: 24)
        }
        return font(
            family: tokens.primerTypographyTitleXlargeFont,
            weight: tokens.primerTypographyTitleXlargeWeight,
            size: tokens.primerTypographyTitleXlargeSize
        )
    }

    /// Font for title large based on design tokens
    static func titleLarge(tokens: DesignTokens?) -> Font {
        guard let tokens = tokens else {
            return font(family: "Inter", weight: 500, size: 16)
        }
        return font(
            family: tokens.primerTypographyTitleLargeFont,
            weight: tokens.primerTypographyTitleLargeWeight,
            size: tokens.primerTypographyTitleLargeSize
        )
    }

    /// Font for body large based on design tokens
    static func bodyLarge(tokens: DesignTokens?) -> Font {
        guard let tokens = tokens else {
            return font(family: "Inter", weight: 400, size: 16)
        }
        return font(
            family: tokens.primerTypographyBodyLargeFont,
            weight: tokens.primerTypographyBodyLargeWeight,
            size: tokens.primerTypographyBodyLargeSize
        )
    }

    /// Font for body medium based on design tokens
    static func bodyMedium(tokens: DesignTokens?) -> Font {
        guard let tokens = tokens else {
            return font(family: "Inter", weight: 400, size: 14)
        }
        return font(
            family: tokens.primerTypographyBodyMediumFont,
            weight: tokens.primerTypographyBodyMediumWeight,
            size: tokens.primerTypographyBodyMediumSize
        )
    }

    /// Font for body small based on design tokens
    static func bodySmall(tokens: DesignTokens?) -> Font {
        guard let tokens = tokens else {
            return font(family: "Inter", weight: 400, size: 12)
        }
        return font(
            family: tokens.primerTypographyBodySmallFont,
            weight: tokens.primerTypographyBodySmallWeight,
            size: tokens.primerTypographyBodySmallSize
        )
    }

    // MARK: - Semantic Font Helpers

    /// Standard body font (for main content text) - maps to bodyMedium (14pt)
    static func body(tokens: DesignTokens?) -> Font {
        return bodyMedium(tokens: tokens)
    }

    /// Caption font (for secondary/supporting text) - maps to bodySmall (12pt)
    static func caption(tokens: DesignTokens?) -> Font {
        return bodySmall(tokens: tokens)
    }

    /// Headline font (for emphasized text) - maps to titleLarge (16pt medium)
    static func headline(tokens: DesignTokens?) -> Font {
        return titleLarge(tokens: tokens)
    }

    /// Title2 font (for section titles) - maps to titleXLarge (24pt)
    static func title2(tokens: DesignTokens?) -> Font {
        return titleXLarge(tokens: tokens)
    }

    /// Large icon font (48pt) - no matching token, using explicit size
    static func largeIcon(tokens: DesignTokens?) -> Font {
        return font(family: "Inter", weight: 400, size: 48)
    }

    /// Extra large icon font - maps to primerSizeXxxlarge (56pt)
    static func extraLargeIcon(tokens: DesignTokens?) -> Font {
        let size = tokens?.primerSizeXxxlarge ?? 56
        return font(family: "Inter", weight: 400, size: size)
    }

    /// Subheadline font (for supporting text) - maps to bodyMedium (14pt)
    static func subheadline(tokens: DesignTokens?) -> Font {
        return bodyMedium(tokens: tokens)
    }

    /// Small badge font (10pt medium) - no matching token, using explicit size
    static func smallBadge(tokens: DesignTokens?) -> Font {
        return font(family: "Inter", weight: 500, size: 10)
    }

    // MARK: - Private Helpers

    private static func customFont(name: String, size: CGFloat) -> Font? {
        // Try to create custom font from bundle
        if UIFont(name: name, size: size) != nil {
            return Font.custom(name, size: size)
        }
        return nil
    }

    private static func weightFromNumber(_ weight: CGFloat) -> Font.Weight {
        switch weight {
        case 100: return .ultraLight
        case 200: return .thin
        case 300: return .light
        case 400: return .regular
        case 500: return .medium
        case 550: return .medium  // Design tokens use 550, map to medium
        case 600: return .semibold
        case 700: return .bold
        case 800: return .heavy
        case 900: return .black
        default: return .regular
        }
    }
}

// MARK: - SwiftUI Font Extension

@available(iOS 15.0, *)
extension Font {

    /// Create Inter font with specific weight and size
    static func inter(size: CGFloat, weight: Font.Weight = .regular, italic: Bool = false) -> Font {
        return PrimerFont.font(
            family: "Inter",
            weight: weightToNumber(weight),
            size: size,
            isItalic: italic
        )
    }

    private static func weightToNumber(_ weight: Font.Weight) -> CGFloat {
        switch weight {
        case .ultraLight: return 100
        case .thin: return 200
        case .light: return 300
        case .regular: return 400
        case .medium: return 500
        case .semibold: return 600
        case .bold: return 700
        case .heavy: return 800
        case .black: return 900
        default: return 400
        }
    }
}
