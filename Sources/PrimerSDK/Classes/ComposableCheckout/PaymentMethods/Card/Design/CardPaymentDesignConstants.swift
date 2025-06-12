//
//  CardPaymentDesignConstants.swift
//  PrimerSDK
//
//  Created by Claude Code on 25.03.2025.
//

import SwiftUI

@available(iOS 15.0, *)
internal struct CardPaymentDesign {
    // MARK: - Spacing (using design tokens as reference)
    static func containerPadding(from tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSpaceLarge ?? 16
    }

    static func fieldVerticalSpacing(from tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSpaceLarge ?? 16
    }

    static func fieldHorizontalSpacing(from tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSpaceMedium ?? 12
    }

    static func headerBottomSpacing(from tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSpaceXlarge ?? 20
    }

    static func cardNetworkIconsSpacing(from tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSpaceSmall ?? 8
    }

    static func buttonTopSpacing(from tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSpaceXlarge ?? 20
    }

    // MARK: - Layout (configurable heights)
    static func fieldHeight(from tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSizeXxxlarge ?? 56
    }

    static func buttonHeight(from tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSizeXxxlarge ?? 56
    }

    static func cardNetworkIconSize(from tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerSizeXlarge ?? 32
    }

    static func cardNetworkIconCornerRadius(from tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerRadiusXsmall ?? 4
    }

    // MARK: - Typography Styles (using design tokens)
    static func titleFont(from tokens: DesignTokens?) -> Font {
        guard let tokens = tokens else { return .title2 }

        if let fontName = tokens.primerTypographyTitleLargeFont,
           let fontSize = tokens.primerTypographyTitleLargeSize,
           let fontWeight = tokens.primerTypographyTitleLargeWeight {
            return Font.custom(fontName, size: fontSize)
                .weight(mapCGFloatToFontWeight(fontWeight))
        }

        return Font.title2.weight(.semibold)
    }

    static func fieldLabelFont(from tokens: DesignTokens?) -> Font {
        guard let tokens = tokens else { return .caption }

        if let fontName = tokens.primerTypographyBodyMediumFont,
           let fontSize = tokens.primerTypographyBodyMediumSize,
           let fontWeight = tokens.primerTypographyBodyMediumWeight {
            return Font.custom(fontName, size: fontSize)
                .weight(mapCGFloatToFontWeight(fontWeight))
        }

        return Font.caption.weight(.medium)
    }

    static func buttonFont(from tokens: DesignTokens?) -> Font {
        guard let tokens = tokens else { return .body }

        if let fontName = tokens.primerTypographyBodyLargeFont,
           let fontSize = tokens.primerTypographyBodyLargeSize,
           let fontWeight = tokens.primerTypographyBodyLargeWeight {
            return Font.custom(fontName, size: fontSize)
                .weight(mapCGFloatToFontWeight(fontWeight))
        }

        return Font.body.weight(.medium)
    }

    static func bodyFont(from tokens: DesignTokens?) -> Font {
        guard let tokens = tokens else { return .body }

        if let fontName = tokens.primerTypographyBodyLargeFont,
           let fontSize = tokens.primerTypographyBodyLargeSize,
           let fontWeight = tokens.primerTypographyBodyLargeWeight {
            return Font.custom(fontName, size: fontSize)
                .weight(mapCGFloatToFontWeight(fontWeight))
        }

        return Font.body
    }

    // MARK: - Colors (design token references)
    static func titleColor(from tokens: DesignTokens?) -> Color {
        return tokens?.primerColorTextPrimary ?? Color.primary
    }

    static func fieldLabelColor(from tokens: DesignTokens?) -> Color {
        return tokens?.primerColorTextSecondary ?? Color.secondary
    }

    static func buttonBackgroundColor(from tokens: DesignTokens?, enabled: Bool) -> Color {
        if enabled {
            return tokens?.primerColorBrand ?? Color.blue
        } else {
            return tokens?.primerColorGray400 ?? Color.gray
        }
    }

    static func buttonTextColor(from tokens: DesignTokens?) -> Color {
        return tokens?.primerColorGray000 ?? Color.white
    }

    static func backgroundColor(from tokens: DesignTokens?) -> Color {
        return tokens?.primerColorBackground ?? Color(UIColor.systemBackground)
    }

    // MARK: - Border Radius (design token references)
    static func fieldCornerRadius(from tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerRadiusMedium ?? 8
    }

    static func buttonCornerRadius(from tokens: DesignTokens?) -> CGFloat {
        return tokens?.primerRadiusMedium ?? 8
    }

    // MARK: - Helper Functions

    /// Maps CGFloat font weight values to SwiftUI Font.Weight enum cases
    private static func mapCGFloatToFontWeight(_ weight: CGFloat) -> Font.Weight {
        switch weight {
        case ...200: return .ultraLight
        case 200..<300: return .thin
        case 300..<400: return .light
        case 400..<500: return .regular
        case 500..<600: return .medium
        case 600..<700: return .semibold
        case 700..<800: return .bold
        case 800..<900: return .heavy
        default: return .black
        }
    }
}

// MARK: - Configuration for Merchant Customization
@available(iOS 15.0, *)
public struct CardPaymentDesignConfiguration {
    public let customSpacing: CardPaymentSpacingConfig?
    public let customSizing: CardPaymentSizingConfig?
    public let customTypography: CardPaymentTypographyConfig?

    public static let `default` = CardPaymentDesignConfiguration(
        customSpacing: nil,
        customSizing: nil,
        customTypography: nil
    )
}

@available(iOS 15.0, *)
public struct CardPaymentSpacingConfig {
    public let containerPadding: CGFloat?
    public let fieldVerticalSpacing: CGFloat?
    public let fieldHorizontalSpacing: CGFloat?
    public let headerBottomSpacing: CGFloat?
    public let cardNetworkIconsSpacing: CGFloat?
    public let buttonTopSpacing: CGFloat?

    public init(
        containerPadding: CGFloat? = nil,
        fieldVerticalSpacing: CGFloat? = nil,
        fieldHorizontalSpacing: CGFloat? = nil,
        headerBottomSpacing: CGFloat? = nil,
        cardNetworkIconsSpacing: CGFloat? = nil,
        buttonTopSpacing: CGFloat? = nil
    ) {
        self.containerPadding = containerPadding
        self.fieldVerticalSpacing = fieldVerticalSpacing
        self.fieldHorizontalSpacing = fieldHorizontalSpacing
        self.headerBottomSpacing = headerBottomSpacing
        self.cardNetworkIconsSpacing = cardNetworkIconsSpacing
        self.buttonTopSpacing = buttonTopSpacing
    }
}

@available(iOS 15.0, *)
public struct CardPaymentSizingConfig {
    public let fieldHeight: CGFloat?
    public let buttonHeight: CGFloat?
    public let cardNetworkIconSize: CGFloat?

    public init(
        fieldHeight: CGFloat? = nil,
        buttonHeight: CGFloat? = nil,
        cardNetworkIconSize: CGFloat? = nil
    ) {
        self.fieldHeight = fieldHeight
        self.buttonHeight = buttonHeight
        self.cardNetworkIconSize = cardNetworkIconSize
    }
}

@available(iOS 15.0, *)
public struct CardPaymentTypographyConfig {
    public let titleFont: Font?
    public let fieldLabelFont: Font?
    public let buttonFont: Font?
    public let bodyFont: Font?

    public init(
        titleFont: Font? = nil,
        fieldLabelFont: Font? = nil,
        buttonFont: Font? = nil,
        bodyFont: Font? = nil
    ) {
        self.titleFont = titleFont
        self.fieldLabelFont = fieldLabelFont
        self.buttonFont = buttonFont
        self.bodyFont = bodyFont
    }
}
