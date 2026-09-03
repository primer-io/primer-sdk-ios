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

  static func textLink(tokens: DesignTokens?) -> Color {
    tokens?.primerColorTextLink ?? .blue
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

  static func background(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBackgroundPrimary ?? .white
  }

  static func backgroundSecondary(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBackgroundSecondary ?? Color(red: 0.961, green: 0.961, blue: 0.961)
  }

  static func gray100(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBackgroundOutlinedDefault ?? .white
  }

  static func gray200(tokens: DesignTokens?) -> Color {
    tokens?.primerColorGray200 ?? Color(.systemGray5)
  }

  static func gray300(tokens: DesignTokens?) -> Color {
    tokens?.primerColorGray300 ?? Color(.systemGray4)
  }

  static func textPlaceholder(tokens: DesignTokens?) -> Color {
    tokens?.primerColorTextPlaceholder ?? Color(.tertiaryLabel)
  }

  static func borderSelected(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBorderOutlinedSelected ?? .blue
  }

  static func iconPositive(tokens: DesignTokens?) -> Color {
    tokens?.primerColorIconPositive ?? Color(.systemGreen)
  }

  static func orange(tokens _: DesignTokens?) -> Color { .orange }

  // MARK: - Screen & Input Colors

  static func screenBackground(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBackgroundPrimary ?? Color(.systemBackground)
  }

  static func inputBackground(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBackgroundOutlinedDefault ?? .white
  }

  static func inputBorder(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBorderOutlinedDefault ?? Color(.systemGray4)
  }

  static func inputBorderFocused(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBorderOutlinedFocus ?? .blue
  }

  // MARK: - Button Colors

  static func buttonPrimary(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBrand ?? .blue
  }

  static func buttonDisabled(tokens: DesignTokens?) -> Color {
    tokens?.primerColorGray300 ?? Color(.systemGray4)
  }

  static func blue(tokens _: DesignTokens?) -> Color { .blue }

  static func green(tokens _: DesignTokens?) -> Color { .green }

  static func error(tokens: DesignTokens?) -> Color {
    tokens?.primerColorTextNegative ?? .red
  }

  static func inputText(tokens: DesignTokens?) -> Color {
    tokens?.primerColorTextOutlinedDefault ?? .primary
  }

  /// Label/spinner colour on a surface filled with `textPrimary`, which the label inverts with; a
  /// disabled surface is light, so the label follows web and Android onto `textDisabled`.
  /// Primary buttons are brand-filled and use `onBrand` instead.
  static func onPrimary(tokens: DesignTokens?, isEnabled: Bool = true) -> Color {
    isEnabled
      ? (tokens?.primerColorBackgroundPrimary ?? .white)
      : (tokens?.primerColorTextDisabled ?? Color(.tertiaryLabel))
  }

  /// Label/spinner colour on a brand-filled surface, which is every primary button. Brand is a fixed
  /// blue in both modes, so the enabled label is fixed white too; a disabled button loses the brand
  /// fill and takes `textDisabled`. A loading button is still brand-filled, so pass `isEnabled: true`.
  static func onBrand(tokens: DesignTokens?, isEnabled: Bool = true) -> Color {
    isEnabled ? .white : (tokens?.primerColorTextDisabled ?? Color(.tertiaryLabel))
  }
}
