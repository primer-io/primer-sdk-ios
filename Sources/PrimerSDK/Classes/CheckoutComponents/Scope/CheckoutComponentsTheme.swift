//
//  CheckoutComponentsTheme.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - PrimerCheckoutTheme

/// Theme configuration providing optional overrides for internal design tokens.
///
/// Internal `DesignTokens` and `DesignTokensDark` classes (auto-generated from JSON)
/// remain the source of truth. `PrimerCheckoutTheme` allows merchants to override specific
/// token values without replacing the entire token system.
///
/// When a merchant provides an override, `DesignTokensManager` merges it with
/// internal defaults. Nil values fall back to internal token values.
@available(iOS 15.0, *)
public struct PrimerCheckoutTheme {

    /// Optional color token overrides
    public let colors: ColorOverrides?

    /// Optional radius token overrides
    public let radius: RadiusOverrides?

    /// Optional spacing token overrides
    public let spacing: SpacingOverrides?

    /// Optional size token overrides
    public let sizes: SizeOverrides?

    /// Creates a new theme configuration with optional overrides.
    /// - Parameters:
    ///   - colors: Color token overrides. Default: nil (uses internal defaults)
    ///   - radius: Radius token overrides. Default: nil (uses internal defaults)
    ///   - spacing: Spacing token overrides. Default: nil (uses internal defaults)
    ///   - sizes: Size token overrides. Default: nil (uses internal defaults)
    public init(
        colors: ColorOverrides? = nil,
        radius: RadiusOverrides? = nil,
        spacing: SpacingOverrides? = nil,
        sizes: SizeOverrides? = nil
    ) {
        self.colors = colors
        self.radius = radius
        self.spacing = spacing
        self.sizes = sizes
    }
}

// MARK: - ColorOverrides

/// Optional color token overrides.
/// Property names match internal `DesignTokens` for consistency.
/// All properties are optional - nil values use internal defaults.
@available(iOS 15.0, *)
public struct ColorOverrides {

    // MARK: Brand & Primary Colors

    /// Primary brand color (internal: primerColorBrand)
    public var primerColorBrand: Color?

    // MARK: Grays (matching internal DesignTokens)

    public var primerColorGray000: Color?
    public var primerColorGray100: Color?
    public var primerColorGray200: Color?
    public var primerColorGray300: Color?
    public var primerColorGray400: Color?
    public var primerColorGray500: Color?
    public var primerColorGray600: Color?
    public var primerColorGray700: Color?
    public var primerColorGray900: Color?

    // MARK: Semantic Colors (matching internal DesignTokens)

    /// Success color (internal: primerColorGreen500)
    public var primerColorGreen500: Color?
    /// Error colors (internal: primerColorRed100, primerColorRed500, primerColorRed900)
    public var primerColorRed100: Color?
    public var primerColorRed500: Color?
    public var primerColorRed900: Color?
    /// Info/link colors (internal: primerColorBlue500, primerColorBlue900)
    public var primerColorBlue500: Color?
    public var primerColorBlue900: Color?

    // MARK: Semantic UI Colors (matching internal DesignTokens)

    public var primerColorBackground: Color?
    public var primerColorTextPrimary: Color?
    public var primerColorTextSecondary: Color?
    public var primerColorTextPlaceholder: Color?
    public var primerColorTextDisabled: Color?
    public var primerColorTextNegative: Color?
    public var primerColorTextLink: Color?

    // MARK: Border Colors (matching internal DesignTokens)

    public var primerColorBorderOutlinedDefault: Color?
    public var primerColorBorderOutlinedHover: Color?
    public var primerColorBorderOutlinedActive: Color?
    public var primerColorBorderOutlinedFocus: Color?
    public var primerColorBorderOutlinedDisabled: Color?
    public var primerColorBorderOutlinedError: Color?
    public var primerColorBorderOutlinedSelected: Color?

    // MARK: Other

    public var primerColorFocus: Color?
    public var primerColorLoader: Color?

    /// Creates color overrides with all optional properties.
    public init(
        primerColorBrand: Color? = nil,
        primerColorGray000: Color? = nil,
        primerColorGray100: Color? = nil,
        primerColorGray200: Color? = nil,
        primerColorGray300: Color? = nil,
        primerColorGray400: Color? = nil,
        primerColorGray500: Color? = nil,
        primerColorGray600: Color? = nil,
        primerColorGray700: Color? = nil,
        primerColorGray900: Color? = nil,
        primerColorGreen500: Color? = nil,
        primerColorRed100: Color? = nil,
        primerColorRed500: Color? = nil,
        primerColorRed900: Color? = nil,
        primerColorBlue500: Color? = nil,
        primerColorBlue900: Color? = nil,
        primerColorBackground: Color? = nil,
        primerColorTextPrimary: Color? = nil,
        primerColorTextSecondary: Color? = nil,
        primerColorTextPlaceholder: Color? = nil,
        primerColorTextDisabled: Color? = nil,
        primerColorTextNegative: Color? = nil,
        primerColorTextLink: Color? = nil,
        primerColorBorderOutlinedDefault: Color? = nil,
        primerColorBorderOutlinedHover: Color? = nil,
        primerColorBorderOutlinedActive: Color? = nil,
        primerColorBorderOutlinedFocus: Color? = nil,
        primerColorBorderOutlinedDisabled: Color? = nil,
        primerColorBorderOutlinedError: Color? = nil,
        primerColorBorderOutlinedSelected: Color? = nil,
        primerColorFocus: Color? = nil,
        primerColorLoader: Color? = nil
    ) {
        self.primerColorBrand = primerColorBrand
        self.primerColorGray000 = primerColorGray000
        self.primerColorGray100 = primerColorGray100
        self.primerColorGray200 = primerColorGray200
        self.primerColorGray300 = primerColorGray300
        self.primerColorGray400 = primerColorGray400
        self.primerColorGray500 = primerColorGray500
        self.primerColorGray600 = primerColorGray600
        self.primerColorGray700 = primerColorGray700
        self.primerColorGray900 = primerColorGray900
        self.primerColorGreen500 = primerColorGreen500
        self.primerColorRed100 = primerColorRed100
        self.primerColorRed500 = primerColorRed500
        self.primerColorRed900 = primerColorRed900
        self.primerColorBlue500 = primerColorBlue500
        self.primerColorBlue900 = primerColorBlue900
        self.primerColorBackground = primerColorBackground
        self.primerColorTextPrimary = primerColorTextPrimary
        self.primerColorTextSecondary = primerColorTextSecondary
        self.primerColorTextPlaceholder = primerColorTextPlaceholder
        self.primerColorTextDisabled = primerColorTextDisabled
        self.primerColorTextNegative = primerColorTextNegative
        self.primerColorTextLink = primerColorTextLink
        self.primerColorBorderOutlinedDefault = primerColorBorderOutlinedDefault
        self.primerColorBorderOutlinedHover = primerColorBorderOutlinedHover
        self.primerColorBorderOutlinedActive = primerColorBorderOutlinedActive
        self.primerColorBorderOutlinedFocus = primerColorBorderOutlinedFocus
        self.primerColorBorderOutlinedDisabled = primerColorBorderOutlinedDisabled
        self.primerColorBorderOutlinedError = primerColorBorderOutlinedError
        self.primerColorBorderOutlinedSelected = primerColorBorderOutlinedSelected
        self.primerColorFocus = primerColorFocus
        self.primerColorLoader = primerColorLoader
    }
}

// MARK: - RadiusOverrides

/// Optional radius token overrides.
/// Property names match internal `DesignTokens`.
@available(iOS 15.0, *)
public struct RadiusOverrides {
    /// Internal: primerRadiusXsmall (default: 2)
    public var primerRadiusXsmall: CGFloat?
    /// Internal: primerRadiusSmall (default: 4)
    public var primerRadiusSmall: CGFloat?
    /// Internal: primerRadiusMedium (default: 8)
    public var primerRadiusMedium: CGFloat?
    /// Internal: primerRadiusLarge (default: 12)
    public var primerRadiusLarge: CGFloat?
    /// Internal: primerRadiusBase (default: 4)
    public var primerRadiusBase: CGFloat?

    /// Creates radius overrides with all optional properties.
    public init(
        primerRadiusXsmall: CGFloat? = nil,
        primerRadiusSmall: CGFloat? = nil,
        primerRadiusMedium: CGFloat? = nil,
        primerRadiusLarge: CGFloat? = nil,
        primerRadiusBase: CGFloat? = nil
    ) {
        self.primerRadiusXsmall = primerRadiusXsmall
        self.primerRadiusSmall = primerRadiusSmall
        self.primerRadiusMedium = primerRadiusMedium
        self.primerRadiusLarge = primerRadiusLarge
        self.primerRadiusBase = primerRadiusBase
    }
}

// MARK: - SpacingOverrides

/// Optional spacing token overrides.
/// Property names match internal `DesignTokens`.
@available(iOS 15.0, *)
public struct SpacingOverrides {
    /// Internal: primerSpaceXxsmall (default: 2)
    public var primerSpaceXxsmall: CGFloat?
    /// Internal: primerSpaceXsmall (default: 4)
    public var primerSpaceXsmall: CGFloat?
    /// Internal: primerSpaceSmall (default: 8)
    public var primerSpaceSmall: CGFloat?
    /// Internal: primerSpaceMedium (default: 12)
    public var primerSpaceMedium: CGFloat?
    /// Internal: primerSpaceLarge (default: 16)
    public var primerSpaceLarge: CGFloat?
    /// Internal: primerSpaceXlarge (default: 20)
    public var primerSpaceXlarge: CGFloat?
    /// Internal: primerSpaceXxlarge (default: 24)
    public var primerSpaceXxlarge: CGFloat?
    /// Internal: primerSpaceBase (default: 4)
    public var primerSpaceBase: CGFloat?

    /// Creates spacing overrides with all optional properties.
    public init(
        primerSpaceXxsmall: CGFloat? = nil,
        primerSpaceXsmall: CGFloat? = nil,
        primerSpaceSmall: CGFloat? = nil,
        primerSpaceMedium: CGFloat? = nil,
        primerSpaceLarge: CGFloat? = nil,
        primerSpaceXlarge: CGFloat? = nil,
        primerSpaceXxlarge: CGFloat? = nil,
        primerSpaceBase: CGFloat? = nil
    ) {
        self.primerSpaceXxsmall = primerSpaceXxsmall
        self.primerSpaceXsmall = primerSpaceXsmall
        self.primerSpaceSmall = primerSpaceSmall
        self.primerSpaceMedium = primerSpaceMedium
        self.primerSpaceLarge = primerSpaceLarge
        self.primerSpaceXlarge = primerSpaceXlarge
        self.primerSpaceXxlarge = primerSpaceXxlarge
        self.primerSpaceBase = primerSpaceBase
    }
}

// MARK: - SizeOverrides

/// Optional size token overrides.
/// Property names match internal `DesignTokens`.
@available(iOS 15.0, *)
public struct SizeOverrides {
    /// Internal: primerSizeSmall (default: 16)
    public var primerSizeSmall: CGFloat?
    /// Internal: primerSizeMedium (default: 20)
    public var primerSizeMedium: CGFloat?
    /// Internal: primerSizeLarge (default: 24)
    public var primerSizeLarge: CGFloat?
    /// Internal: primerSizeXlarge (default: 32)
    public var primerSizeXlarge: CGFloat?
    /// Internal: primerSizeXxlarge (default: 44)
    public var primerSizeXxlarge: CGFloat?
    /// Internal: primerSizeXxxlarge (default: 56)
    public var primerSizeXxxlarge: CGFloat?
    /// Internal: primerSizeBase (default: 4)
    public var primerSizeBase: CGFloat?

    /// Creates size overrides with all optional properties.
    public init(
        primerSizeSmall: CGFloat? = nil,
        primerSizeMedium: CGFloat? = nil,
        primerSizeLarge: CGFloat? = nil,
        primerSizeXlarge: CGFloat? = nil,
        primerSizeXxlarge: CGFloat? = nil,
        primerSizeXxxlarge: CGFloat? = nil,
        primerSizeBase: CGFloat? = nil
    ) {
        self.primerSizeSmall = primerSizeSmall
        self.primerSizeMedium = primerSizeMedium
        self.primerSizeLarge = primerSizeLarge
        self.primerSizeXlarge = primerSizeXlarge
        self.primerSizeXxlarge = primerSizeXxlarge
        self.primerSizeXxxlarge = primerSizeXxxlarge
        self.primerSizeBase = primerSizeBase
    }
}
