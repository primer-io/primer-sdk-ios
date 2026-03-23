//
//  PrimerCheckoutTheme.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
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

  public let colors: ColorOverrides?
  public let radius: RadiusOverrides?
  public let spacing: SpacingOverrides?
  public let sizes: SizeOverrides?
  public let typography: TypographyOverrides?
  public let borderWidth: BorderWidthOverrides?

  /// Creates a new theme configuration with optional overrides.
  /// - Parameters:
  ///   - colors: Color token overrides. Default: nil (uses internal defaults)
  ///   - radius: Radius token overrides. Default: nil (uses internal defaults)
  ///   - spacing: Spacing token overrides. Default: nil (uses internal defaults)
  ///   - sizes: Size token overrides. Default: nil (uses internal defaults)
  ///   - typography: Typography token overrides. Default: nil (uses internal defaults)
  ///   - borderWidth: Border width token overrides. Default: nil (uses internal defaults)
  public init(
    colors: ColorOverrides? = nil,
    radius: RadiusOverrides? = nil,
    spacing: SpacingOverrides? = nil,
    sizes: SizeOverrides? = nil,
    typography: TypographyOverrides? = nil,
    borderWidth: BorderWidthOverrides? = nil
  ) {
    self.colors = colors
    self.radius = radius
    self.spacing = spacing
    self.sizes = sizes
    self.typography = typography
    self.borderWidth = borderWidth
  }
}

// MARK: - ColorOverrides

/// Optional color token overrides.
/// Property names match internal `DesignTokens` for consistency.
/// All properties are optional - nil values use internal defaults.
@available(iOS 15.0, *)
public struct ColorOverrides {

  // MARK: Brand & Primary Colors

  public let primerColorBrand: Color?

  // MARK: Grays (matching internal DesignTokens)

  public let primerColorGray000: Color?
  public let primerColorGray100: Color?
  public let primerColorGray200: Color?
  public let primerColorGray300: Color?
  public let primerColorGray400: Color?
  public let primerColorGray500: Color?
  public let primerColorGray600: Color?
  public let primerColorGray700: Color?
  public let primerColorGray900: Color?

  // MARK: Semantic Colors (matching internal DesignTokens)

  /// Success color (internal: primerColorGreen500)
  public let primerColorGreen500: Color?
  /// Error colors (internal: primerColorRed100, primerColorRed500, primerColorRed900)
  public let primerColorRed100: Color?
  public let primerColorRed500: Color?
  public let primerColorRed900: Color?
  /// Info/link colors (internal: primerColorBlue500, primerColorBlue900)
  public let primerColorBlue500: Color?
  public let primerColorBlue900: Color?

  // MARK: Semantic UI Colors (matching internal DesignTokens)

  public let primerColorBackground: Color?
  public let primerColorTextPrimary: Color?
  public let primerColorTextSecondary: Color?
  public let primerColorTextPlaceholder: Color?
  public let primerColorTextDisabled: Color?
  public let primerColorTextNegative: Color?
  public let primerColorTextLink: Color?

  // MARK: Border Colors (matching internal DesignTokens)

  public let primerColorBorderOutlinedDefault: Color?
  public let primerColorBorderOutlinedHover: Color?
  public let primerColorBorderOutlinedActive: Color?
  public let primerColorBorderOutlinedFocus: Color?
  public let primerColorBorderOutlinedDisabled: Color?
  public let primerColorBorderOutlinedError: Color?
  public let primerColorBorderOutlinedSelected: Color?
  public let primerColorBorderOutlinedLoading: Color?

  // MARK: Border Transparent Colors

  public let primerColorBorderTransparentDefault: Color?
  public let primerColorBorderTransparentHover: Color?
  public let primerColorBorderTransparentActive: Color?
  public let primerColorBorderTransparentFocus: Color?
  public let primerColorBorderTransparentDisabled: Color?
  public let primerColorBorderTransparentSelected: Color?

  // MARK: Icon Colors

  public let primerColorIconPrimary: Color?
  public let primerColorIconDisabled: Color?
  public let primerColorIconNegative: Color?
  public let primerColorIconPositive: Color?

  // MARK: Other

  public let primerColorFocus: Color?
  public let primerColorLoader: Color?

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
    primerColorBorderOutlinedLoading: Color? = nil,
    primerColorBorderTransparentDefault: Color? = nil,
    primerColorBorderTransparentHover: Color? = nil,
    primerColorBorderTransparentActive: Color? = nil,
    primerColorBorderTransparentFocus: Color? = nil,
    primerColorBorderTransparentDisabled: Color? = nil,
    primerColorBorderTransparentSelected: Color? = nil,
    primerColorIconPrimary: Color? = nil,
    primerColorIconDisabled: Color? = nil,
    primerColorIconNegative: Color? = nil,
    primerColorIconPositive: Color? = nil,
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
    self.primerColorBorderOutlinedLoading = primerColorBorderOutlinedLoading
    self.primerColorBorderTransparentDefault = primerColorBorderTransparentDefault
    self.primerColorBorderTransparentHover = primerColorBorderTransparentHover
    self.primerColorBorderTransparentActive = primerColorBorderTransparentActive
    self.primerColorBorderTransparentFocus = primerColorBorderTransparentFocus
    self.primerColorBorderTransparentDisabled = primerColorBorderTransparentDisabled
    self.primerColorBorderTransparentSelected = primerColorBorderTransparentSelected
    self.primerColorIconPrimary = primerColorIconPrimary
    self.primerColorIconDisabled = primerColorIconDisabled
    self.primerColorIconNegative = primerColorIconNegative
    self.primerColorIconPositive = primerColorIconPositive
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
  public let primerRadiusXsmall: CGFloat?
  /// Internal: primerRadiusSmall (default: 4)
  public let primerRadiusSmall: CGFloat?
  /// Internal: primerRadiusMedium (default: 8)
  public let primerRadiusMedium: CGFloat?
  /// Internal: primerRadiusLarge (default: 12)
  public let primerRadiusLarge: CGFloat?
  /// Internal: primerRadiusBase (default: 4)
  public let primerRadiusBase: CGFloat?

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
  public let primerSpaceXxsmall: CGFloat?
  /// Internal: primerSpaceXsmall (default: 4)
  public let primerSpaceXsmall: CGFloat?
  /// Internal: primerSpaceSmall (default: 8)
  public let primerSpaceSmall: CGFloat?
  /// Internal: primerSpaceMedium (default: 12)
  public let primerSpaceMedium: CGFloat?
  /// Internal: primerSpaceLarge (default: 16)
  public let primerSpaceLarge: CGFloat?
  /// Internal: primerSpaceXlarge (default: 20)
  public let primerSpaceXlarge: CGFloat?
  /// Internal: primerSpaceXxlarge (default: 24)
  public let primerSpaceXxlarge: CGFloat?
  /// Internal: primerSpaceBase (default: 4)
  public let primerSpaceBase: CGFloat?

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
  public let primerSizeSmall: CGFloat?
  /// Internal: primerSizeMedium (default: 20)
  public let primerSizeMedium: CGFloat?
  /// Internal: primerSizeLarge (default: 24)
  public let primerSizeLarge: CGFloat?
  /// Internal: primerSizeXlarge (default: 32)
  public let primerSizeXlarge: CGFloat?
  /// Internal: primerSizeXxlarge (default: 44)
  public let primerSizeXxlarge: CGFloat?
  /// Internal: primerSizeXxxlarge (default: 56)
  public let primerSizeXxxlarge: CGFloat?
  /// Internal: primerSizeBase (default: 4)
  public let primerSizeBase: CGFloat?

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

// MARK: - TypographyOverrides

/// Optional typography token overrides for customizing text styles.
@available(iOS 15.0, *)
public struct TypographyOverrides {

  // MARK: - Typography Style

  /// Individual typography style configuration.
  public struct TypographyStyle {
    /// Custom font family name (e.g., "Inter")
    public let font: String?
    /// Letter spacing in points
    public let letterSpacing: CGFloat?
    /// Font weight
    public let weight: Font.Weight?
    /// Font size in points
    public let size: CGFloat?
    /// Line height in points
    public let lineHeight: CGFloat?

    /// Creates a typography style with optional properties.
    public init(
      font: String? = nil,
      letterSpacing: CGFloat? = nil,
      weight: Font.Weight? = nil,
      size: CGFloat? = nil,
      lineHeight: CGFloat? = nil
    ) {
      self.font = font
      self.letterSpacing = letterSpacing
      self.weight = weight
      self.size = size
      self.lineHeight = lineHeight
    }
  }

  // MARK: - Token Properties

  /// Title extra large: Inter, -0.6 letter spacing, weight 550, size 24, line height 32
  public let titleXlarge: TypographyStyle?

  /// Title large: Inter, -0.2 letter spacing, weight 550, size 16, line height 20
  public let titleLarge: TypographyStyle?

  /// Body large: Inter, -0.2 letter spacing, weight 400, size 16, line height 20
  public let bodyLarge: TypographyStyle?

  /// Body medium: Inter, 0 letter spacing, weight 400, size 14, line height 20
  public let bodyMedium: TypographyStyle?

  /// Body small: Inter, 0 letter spacing, weight 400, size 12, line height 16
  public let bodySmall: TypographyStyle?

  /// Creates typography overrides with all optional properties.
  public init(
    titleXlarge: TypographyStyle? = nil,
    titleLarge: TypographyStyle? = nil,
    bodyLarge: TypographyStyle? = nil,
    bodyMedium: TypographyStyle? = nil,
    bodySmall: TypographyStyle? = nil
  ) {
    self.titleXlarge = titleXlarge
    self.titleLarge = titleLarge
    self.bodyLarge = bodyLarge
    self.bodyMedium = bodyMedium
    self.bodySmall = bodySmall
  }
}

// MARK: - BorderWidthOverrides

/// Optional border width token overrides.
@available(iOS 15.0, *)
public struct BorderWidthOverrides {
  /// Internal: primerBorderWidthThin (default: 1)
  public let primerBorderWidthThin: CGFloat?

  /// Internal: primerBorderWidthMedium (default: 2)
  public let primerBorderWidthMedium: CGFloat?

  /// Internal: primerBorderWidthThick (default: 3)
  public let primerBorderWidthThick: CGFloat?

  /// Creates border width overrides with all optional properties.
  public init(
    primerBorderWidthThin: CGFloat? = nil,
    primerBorderWidthMedium: CGFloat? = nil,
    primerBorderWidthThick: CGFloat? = nil
  ) {
    self.primerBorderWidthThin = primerBorderWidthThin
    self.primerBorderWidthMedium = primerBorderWidthMedium
    self.primerBorderWidthThick = primerBorderWidthThick
  }
}
