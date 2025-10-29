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

    // MARK: - Typography Design Token Helpers with Dynamic Type Support

    /// Font for title extra large based on design tokens with Dynamic Type scaling
    static func titleXLarge(tokens: DesignTokens) -> Font {
        let baseSize = tokens.primerTypographyTitleXlargeSize ?? 24
        return font(
            family: tokens.primerTypographyTitleXlargeFont,
            weight: tokens.primerTypographyTitleXlargeWeight,
            size: baseSize
        )
        .dynamicallyScaled(baseSize: baseSize, textStyle: .title)
    }

    /// Font for title large based on design tokens with Dynamic Type scaling
    static func titleLarge(tokens: DesignTokens) -> Font {
        let baseSize = tokens.primerTypographyTitleLargeSize ?? 20
        return font(
            family: tokens.primerTypographyTitleLargeFont,
            weight: tokens.primerTypographyTitleLargeWeight,
            size: baseSize
        )
        .dynamicallyScaled(baseSize: baseSize, textStyle: .title2)
    }

    /// Font for body large based on design tokens with Dynamic Type scaling
    static func bodyLarge(tokens: DesignTokens) -> Font {
        let baseSize = tokens.primerTypographyBodyLargeSize ?? 16
        return font(
            family: tokens.primerTypographyBodyLargeFont,
            weight: tokens.primerTypographyBodyLargeWeight,
            size: baseSize
        )
        .dynamicallyScaled(baseSize: baseSize, textStyle: .body)
    }

    /// Font for body medium based on design tokens with Dynamic Type scaling
    static func bodyMedium(tokens: DesignTokens) -> Font {
        let baseSize = tokens.primerTypographyBodyMediumSize ?? 14
        return font(
            family: tokens.primerTypographyBodyMediumFont,
            weight: tokens.primerTypographyBodyMediumWeight,
            size: baseSize
        )
        .dynamicallyScaled(baseSize: baseSize, textStyle: .subheadline)
    }

    /// Font for body small based on design tokens with Dynamic Type scaling
    static func bodySmall(tokens: DesignTokens) -> Font {
        let baseSize = tokens.primerTypographyBodySmallSize ?? 12
        return font(
            family: tokens.primerTypographyBodySmallFont,
            weight: tokens.primerTypographyBodySmallWeight,
            size: baseSize
        )
        .dynamicallyScaled(baseSize: baseSize, textStyle: .caption)
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
