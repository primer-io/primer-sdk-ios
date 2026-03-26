//
//  DesignTokensManager.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable cyclomatic_complexity

import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class DesignTokensManager: ObservableObject {
  @Published var tokens: DesignTokens?
  private var themeOverrides: PrimerCheckoutTheme?

  // MARK: - Theme Override API

  func applyTheme(_ theme: PrimerCheckoutTheme) {
    themeOverrides = theme
  }

  // MARK: - Token Loading

  func fetchTokens(for colorScheme: ColorScheme) async throws {
    // Load and merge tokens
    let baseDict = try loadJSON(named: "base")
    let mergedDict =
      colorScheme == .dark
      ? DesignTokensProcessor.mergeDictionaries(baseDict, with: try loadJSON(named: "dark"))
      : baseDict

    // Process tokens through transformation pipeline
    var processedDict = DesignTokensProcessor.resolveReferences(in: mergedDict)
    processedDict = DesignTokensProcessor.convertHexColors(in: processedDict)
    var flatDict = DesignTokensProcessor.flattenTokenDictionary(processedDict)
    flatDict = DesignTokensProcessor.resolveFlattenedReferences(in: flatDict, source: processedDict)
    flatDict = DesignTokensProcessor.evaluateMath(in: flatDict)

    // Decode tokens from JSON
    let data = try JSONSerialization.data(withJSONObject: flatDict)
    let loadedTokens = try JSONDecoder().decode(DesignTokens.self, from: data)

    // Apply merchant theme overrides on top of loaded tokens
    let finalTokens = applyThemeOverrides(to: loadedTokens)

    await MainActor.run {
      self.tokens = finalTokens
    }
  }

  // MARK: - Apply Theme Overrides

  /// Applies merchant theme overrides to the loaded design tokens.
  /// This ensures that CheckoutColors and other direct token accessors respect theme customizations.
  private func applyThemeOverrides(to tokens: DesignTokens) -> DesignTokens {
    guard let theme = themeOverrides else { return tokens }

    if let colors = theme.colors {
      applyColorOverrides(to: tokens, from: colors)
    }
    if let radius = theme.radius {
      applyRadiusOverrides(to: tokens, from: radius)
    }
    if let spacing = theme.spacing {
      applySpacingOverrides(to: tokens, from: spacing)
    }
    if let sizes = theme.sizes {
      applySizeOverrides(to: tokens, from: sizes)
    }
    if let typography = theme.typography {
      applyTypographyOverrides(to: tokens, from: typography)
    }

    return tokens
  }

  private func applyColorOverrides(to tokens: DesignTokens, from colors: ColorOverrides) {
    applyBrandAndGrayColorOverrides(to: tokens, from: colors)
    applySemanticColorOverrides(to: tokens, from: colors)
    applyTextColorOverrides(to: tokens, from: colors)
    applyBorderColorOverrides(to: tokens, from: colors)
    applyIconAndOtherColorOverrides(to: tokens, from: colors)
  }

  private func applyBrandAndGrayColorOverrides(to tokens: DesignTokens, from colors: ColorOverrides) {
    if let value = colors.primerColorBrand { tokens.primerColorBrand = value }
    if let value = colors.primerColorGray000 { tokens.primerColorGray000 = value }
    if let value = colors.primerColorGray100 { tokens.primerColorGray100 = value }
    if let value = colors.primerColorGray200 { tokens.primerColorGray200 = value }
    if let value = colors.primerColorGray300 { tokens.primerColorGray300 = value }
    if let value = colors.primerColorGray400 { tokens.primerColorGray400 = value }
    if let value = colors.primerColorGray500 { tokens.primerColorGray500 = value }
    if let value = colors.primerColorGray600 { tokens.primerColorGray600 = value }
    if let value = colors.primerColorGray700 { tokens.primerColorGray700 = value }
    if let value = colors.primerColorGray900 { tokens.primerColorGray900 = value }
  }

  private func applySemanticColorOverrides(to tokens: DesignTokens, from colors: ColorOverrides) {
    if let value = colors.primerColorGreen500 { tokens.primerColorGreen500 = value }
    if let value = colors.primerColorRed100 { tokens.primerColorRed100 = value }
    if let value = colors.primerColorRed500 { tokens.primerColorRed500 = value }
    if let value = colors.primerColorRed900 { tokens.primerColorRed900 = value }
    if let value = colors.primerColorBlue500 { tokens.primerColorBlue500 = value }
    if let value = colors.primerColorBlue900 { tokens.primerColorBlue900 = value }
    if let value = colors.primerColorBackground { tokens.primerColorBackground = value }
  }

  private func applyTextColorOverrides(to tokens: DesignTokens, from colors: ColorOverrides) {
    if let value = colors.primerColorTextPrimary { tokens.primerColorTextPrimary = value }
    if let value = colors.primerColorTextSecondary { tokens.primerColorTextSecondary = value }
    if let value = colors.primerColorTextPlaceholder { tokens.primerColorTextPlaceholder = value }
    if let value = colors.primerColorTextDisabled { tokens.primerColorTextDisabled = value }
    if let value = colors.primerColorTextNegative { tokens.primerColorTextNegative = value }
    if let value = colors.primerColorTextLink { tokens.primerColorTextLink = value }
  }

  private func applyBorderColorOverrides(to tokens: DesignTokens, from colors: ColorOverrides) {
    applyOutlinedBorderColorOverrides(to: tokens, from: colors)
    applyTransparentBorderColorOverrides(to: tokens, from: colors)
  }

  private func applyOutlinedBorderColorOverrides(
    to tokens: DesignTokens, from colors: ColorOverrides
  ) {
    if let value = colors.primerColorBorderOutlinedDefault {
      tokens.primerColorBorderOutlinedDefault = value
    }
    if let value = colors.primerColorBorderOutlinedHover {
      tokens.primerColorBorderOutlinedHover = value
    }
    if let value = colors.primerColorBorderOutlinedActive {
      tokens.primerColorBorderOutlinedActive = value
    }
    if let value = colors.primerColorBorderOutlinedFocus {
      tokens.primerColorBorderOutlinedFocus = value
    }
    if let value = colors.primerColorBorderOutlinedDisabled {
      tokens.primerColorBorderOutlinedDisabled = value
    }
    if let value = colors.primerColorBorderOutlinedError {
      tokens.primerColorBorderOutlinedError = value
    }
    if let value = colors.primerColorBorderOutlinedSelected {
      tokens.primerColorBorderOutlinedSelected = value
    }
    if let value = colors.primerColorBorderOutlinedLoading {
      tokens.primerColorBorderOutlinedLoading = value
    }
  }

  private func applyTransparentBorderColorOverrides(
    to tokens: DesignTokens, from colors: ColorOverrides
  ) {
    if let value = colors.primerColorBorderTransparentDefault {
      tokens.primerColorBorderTransparentDefault = value
    }
    if let value = colors.primerColorBorderTransparentHover {
      tokens.primerColorBorderTransparentHover = value
    }
    if let value = colors.primerColorBorderTransparentActive {
      tokens.primerColorBorderTransparentActive = value
    }
    if let value = colors.primerColorBorderTransparentFocus {
      tokens.primerColorBorderTransparentFocus = value
    }
    if let value = colors.primerColorBorderTransparentDisabled {
      tokens.primerColorBorderTransparentDisabled = value
    }
    if let value = colors.primerColorBorderTransparentSelected {
      tokens.primerColorBorderTransparentSelected = value
    }
  }

  private func applyIconAndOtherColorOverrides(to tokens: DesignTokens, from colors: ColorOverrides) {
    if let value = colors.primerColorIconPrimary { tokens.primerColorIconPrimary = value }
    if let value = colors.primerColorIconDisabled { tokens.primerColorIconDisabled = value }
    if let value = colors.primerColorIconNegative { tokens.primerColorIconNegative = value }
    if let value = colors.primerColorIconPositive { tokens.primerColorIconPositive = value }
    if let value = colors.primerColorFocus { tokens.primerColorFocus = value }
    if let value = colors.primerColorLoader { tokens.primerColorLoader = value }
  }

  private func applyRadiusOverrides(to tokens: DesignTokens, from radius: RadiusOverrides) {
    if let value = radius.primerRadiusXsmall { tokens.primerRadiusXsmall = value }
    if let value = radius.primerRadiusSmall { tokens.primerRadiusSmall = value }
    if let value = radius.primerRadiusMedium { tokens.primerRadiusMedium = value }
    if let value = radius.primerRadiusLarge { tokens.primerRadiusLarge = value }
    if let value = radius.primerRadiusBase { tokens.primerRadiusBase = value }
  }

  private func applySpacingOverrides(to tokens: DesignTokens, from spacing: SpacingOverrides) {
    if let value = spacing.primerSpaceXxsmall { tokens.primerSpaceXxsmall = value }
    if let value = spacing.primerSpaceXsmall { tokens.primerSpaceXsmall = value }
    if let value = spacing.primerSpaceSmall { tokens.primerSpaceSmall = value }
    if let value = spacing.primerSpaceMedium { tokens.primerSpaceMedium = value }
    if let value = spacing.primerSpaceLarge { tokens.primerSpaceLarge = value }
    if let value = spacing.primerSpaceXlarge { tokens.primerSpaceXlarge = value }
    if let value = spacing.primerSpaceXxlarge { tokens.primerSpaceXxlarge = value }
    if let value = spacing.primerSpaceBase { tokens.primerSpaceBase = value }
  }

  private func applySizeOverrides(to tokens: DesignTokens, from sizes: SizeOverrides) {
    if let value = sizes.primerSizeSmall { tokens.primerSizeSmall = value }
    if let value = sizes.primerSizeMedium { tokens.primerSizeMedium = value }
    if let value = sizes.primerSizeLarge { tokens.primerSizeLarge = value }
    if let value = sizes.primerSizeXlarge { tokens.primerSizeXlarge = value }
    if let value = sizes.primerSizeXxlarge { tokens.primerSizeXxlarge = value }
    if let value = sizes.primerSizeXxxlarge { tokens.primerSizeXxxlarge = value }
    if let value = sizes.primerSizeBase { tokens.primerSizeBase = value }
  }

  private func applyTypographyOverrides(
    to tokens: DesignTokens, from typography: TypographyOverrides
  ) {
    // Title XLarge
    if let style = typography.titleXlarge {
      if let font = style.font { tokens.primerTypographyTitleXlargeFont = font }
      if let size = style.size { tokens.primerTypographyTitleXlargeSize = size }
      if let weight = style.weight {
        tokens.primerTypographyTitleXlargeWeight = fontWeightToCGFloat(weight)
      }
      if let letterSpacing = style.letterSpacing {
        tokens.primerTypographyTitleXlargeLetterSpacing = letterSpacing
      }
      if let lineHeight = style.lineHeight {
        tokens.primerTypographyTitleXlargeLineHeight = lineHeight
      }
    }

    // Title Large
    if let style = typography.titleLarge {
      if let font = style.font { tokens.primerTypographyTitleLargeFont = font }
      if let size = style.size { tokens.primerTypographyTitleLargeSize = size }
      if let weight = style.weight {
        tokens.primerTypographyTitleLargeWeight = fontWeightToCGFloat(weight)
      }
      if let letterSpacing = style.letterSpacing {
        tokens.primerTypographyTitleLargeLetterSpacing = letterSpacing
      }
      if let lineHeight = style.lineHeight {
        tokens.primerTypographyTitleLargeLineHeight = lineHeight
      }
    }

    // Body Large
    if let style = typography.bodyLarge {
      if let font = style.font { tokens.primerTypographyBodyLargeFont = font }
      if let size = style.size { tokens.primerTypographyBodyLargeSize = size }
      if let weight = style.weight {
        tokens.primerTypographyBodyLargeWeight = fontWeightToCGFloat(weight)
      }
      if let letterSpacing = style.letterSpacing {
        tokens.primerTypographyBodyLargeLetterSpacing = letterSpacing
      }
      if let lineHeight = style.lineHeight {
        tokens.primerTypographyBodyLargeLineHeight = lineHeight
      }
    }

    // Body Medium
    if let style = typography.bodyMedium {
      if let font = style.font { tokens.primerTypographyBodyMediumFont = font }
      if let size = style.size { tokens.primerTypographyBodyMediumSize = size }
      if let weight = style.weight {
        tokens.primerTypographyBodyMediumWeight = fontWeightToCGFloat(weight)
      }
      if let letterSpacing = style.letterSpacing {
        tokens.primerTypographyBodyMediumLetterSpacing = letterSpacing
      }
      if let lineHeight = style.lineHeight {
        tokens.primerTypographyBodyMediumLineHeight = lineHeight
      }
    }

    // Body Small
    if let style = typography.bodySmall {
      if let font = style.font { tokens.primerTypographyBodySmallFont = font }
      if let size = style.size { tokens.primerTypographyBodySmallSize = size }
      if let weight = style.weight {
        tokens.primerTypographyBodySmallWeight = fontWeightToCGFloat(weight)
      }
      if let letterSpacing = style.letterSpacing {
        tokens.primerTypographyBodySmallLetterSpacing = letterSpacing
      }
      if let lineHeight = style.lineHeight {
        tokens.primerTypographyBodySmallLineHeight = lineHeight
      }
    }
  }

  private func fontWeightToCGFloat(_ weight: Font.Weight) -> CGFloat {
    switch weight {
    case .ultraLight: 100
    case .thin: 200
    case .light: 300
    case .regular: 400
    case .medium: 500
    case .semibold: 600
    case .bold: 700
    case .heavy: 800
    case .black: 900
    default: 400
    }
  }

  // MARK: - JSON Loading

  private func loadJSON(named fileName: String) throws -> [String: Any] {
    guard let url = Bundle.primerResources.url(forResource: fileName, withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      throw PrimerError.failedToLoadDesignTokens(fileName: fileName)
    }
    return dictionary
  }

}

// swiftlint:enable cyclomatic_complexity
