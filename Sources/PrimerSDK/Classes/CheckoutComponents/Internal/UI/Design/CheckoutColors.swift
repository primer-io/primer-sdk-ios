//
//  CheckoutColors.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

// MARK: - Primer Colors

enum CheckoutColors {

  static func textPrimary(tokens: DesignTokens?) -> Color {
    tokens?.primerColorTextPrimary ?? .primary
  }

  static func textSecondary(tokens: DesignTokens?) -> Color {
    tokens?.primerColorTextSecondary ?? .secondary
  }

  static func textNegative(tokens: DesignTokens?) -> Color {
    tokens?.primerColorTextNegative ?? .red
  }

  static func textDisabled(tokens: DesignTokens?) -> Color {
    tokens?.primerColorTextDisabled ?? Color(.tertiaryLabel)
  }

  static func iconPrimary(tokens: DesignTokens?) -> Color {
    tokens?.primerColorIconPrimary ?? .primary
  }

  static func iconNegative(tokens: DesignTokens?) -> Color {
    tokens?.primerColorIconNegative ?? .red
  }

  static func borderDefault(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBorderOutlinedDefault ?? .gray
  }

  static func borderError(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBorderOutlinedError ?? .red
  }

  static func borderFocus(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBorderOutlinedFocus ?? .blue
  }

  /// A locked field's fill, the same token Android and React Native use for it.
  static func backgroundOutlinedDisabled(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBackgroundOutlinedDisabled ?? Color(.systemGray6)
  }

  static func borderDisabled(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBorderOutlinedDisabled ?? Color(.systemGray4)
  }

  static func background(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBackgroundPrimary ?? .white
  }

  static func backgroundSecondary(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBackgroundSecondary ?? Color(red: 0.961, green: 0.961, blue: 0.961)
  }

  static func gray300(tokens: DesignTokens?) -> Color {
    tokens?.primerColorGray300 ?? Color(.systemGray4)
  }

  static func textPlaceholder(tokens: DesignTokens?) -> Color {
    tokens?.primerColorTextPlaceholder ?? Color(.tertiaryLabel)
  }

  static func loader(tokens: DesignTokens?) -> Color {
    tokens?.primerColorLoader ?? .blue
  }

  static func borderSelected(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBorderOutlinedSelected ?? .blue
  }

  static func iconPositive(tokens: DesignTokens?) -> Color {
    tokens?.primerColorIconPositive ?? Color(.systemGreen)
  }

  /// Label/spinner colour on a brand-filled surface, which is every primary button: the merchant's
  /// `onBrand`, else the sheet colour, as on the other platforms. A disabled button loses the brand
  /// fill and takes `textDisabled`. A loading button is still brand-filled, so pass `isEnabled: true`.
  static func onBrand(tokens: DesignTokens?, isEnabled: Bool = true) -> Color {
    isEnabled
      ? (tokens?.primerColorOnBrand ?? tokens?.primerColorBackgroundPrimary ?? .white)
      : (tokens?.primerColorTextDisabled ?? Color(.tertiaryLabel))
  }

  static func orange(tokens _: DesignTokens?) -> Color { .orange }

  // MARK: - Screen & Input Colors

  static func screenBackground(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBackgroundPrimary ?? Color(.systemBackground)
  }

  static func inputBackground(tokens: DesignTokens?, isEnabled: Bool = true) -> Color {
    isEnabled
      ? tokens?.primerColorBackgroundOutlinedDefault ?? .white
      : backgroundOutlinedDisabled(tokens: tokens)
  }

  static func inputText(tokens: DesignTokens?, isEnabled: Bool = true) -> Color {
    isEnabled ? tokens?.primerColorTextOutlinedDefault ?? .primary : textDisabled(tokens: tokens)
  }

  // MARK: - Button Colors

  static func buttonPrimary(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBrand ?? .blue
  }

  static func buttonDisabled(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBackgroundOutlinedDisabled ?? Color(.systemGray6)
  }
}
