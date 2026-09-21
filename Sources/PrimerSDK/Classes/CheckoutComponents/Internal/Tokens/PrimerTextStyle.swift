//
//  PrimerTextStyle.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// One of the six typography styles a merchant can theme.
///
/// `.font()` carries only family, size and weight. Line height and letter spacing are separate
/// SwiftUI modifiers, so themed text goes through `primerTypography` rather than `.font()`.
@available(iOS 15.0, *)
enum PrimerTextStyle {
  case titleXLarge
  case titleLarge
  case bodyLarge
  case bodyMedium
  case bodySmall
  case error

  // MARK: - Semantic Aliases

  /// Standard body text
  static let body = Self.bodyMedium
  /// Secondary or supporting text
  static let caption = Self.bodySmall
  /// Emphasized text
  static let headline = Self.titleLarge
  /// Section titles
  static let title2 = Self.titleXLarge
  /// Supporting or secondary text
  static let subheadline = Self.bodyMedium

  func uiFont(tokens: DesignTokens?) -> UIFont {
    switch self {
    case .titleXLarge: PrimerFont.uiFontTitleXLarge(tokens: tokens)
    case .titleLarge: PrimerFont.uiFontTitleLarge(tokens: tokens)
    case .bodyLarge: PrimerFont.uiFontBodyLarge(tokens: tokens)
    case .bodyMedium: PrimerFont.uiFontBodyMedium(tokens: tokens)
    case .bodySmall: PrimerFont.uiFontBodySmall(tokens: tokens)
    case .error: PrimerFont.uiFontError(tokens: tokens)
    }
  }

  /// Line height in points, scaled for Dynamic Type so it tracks the font, which is also scaled.
  func lineHeight(tokens: DesignTokens?) -> CGFloat? {
    let tokenValue: CGFloat? = switch self {
    case .titleXLarge: tokens?.primerTypographyTitleXlargeLineHeight
    case .titleLarge: tokens?.primerTypographyTitleLargeLineHeight
    case .bodyLarge: tokens?.primerTypographyBodyLargeLineHeight
    case .bodyMedium: tokens?.primerTypographyBodyMediumLineHeight
    case .bodySmall: tokens?.primerTypographyBodySmallLineHeight
    case .error: tokens?.primerTypographyErrorLineHeight
    }
    return tokenValue.map(UIFontMetrics.default.scaledValue(for:))
  }

  /// Letter spacing in points, scaled alongside the font so the ratio holds at every text size.
  func letterSpacing(tokens: DesignTokens?) -> CGFloat? {
    let tokenValue: CGFloat? = switch self {
    case .titleXLarge: tokens?.primerTypographyTitleXlargeLetterSpacing
    case .titleLarge: tokens?.primerTypographyTitleLargeLetterSpacing
    case .bodyLarge: tokens?.primerTypographyBodyLargeLetterSpacing
    case .bodyMedium: tokens?.primerTypographyBodyMediumLetterSpacing
    case .bodySmall: tokens?.primerTypographyBodySmallLetterSpacing
    case .error: tokens?.primerTypographyErrorLetterSpacing
    }
    return tokenValue.map(UIFontMetrics.default.scaledValue(for:))
  }
}
