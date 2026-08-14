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

  static func gray100(tokens: DesignTokens?) -> Color {
    tokens?.primerColorGray100 ?? Color(.systemGray6)
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

  static func loader(tokens: DesignTokens?) -> Color {
    tokens?.primerColorLoader ?? .blue
  }

  static func borderSelected(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBorderOutlinedSelected ?? .blue
  }

  static func iconPositive(tokens: DesignTokens?) -> Color {
    tokens?.primerColorIconPositive ?? Color(.systemGreen)
  }

  static func white(tokens _: DesignTokens?) -> Color { .white }

  static func blue(tokens _: DesignTokens?) -> Color { .blue }

  static func orange(tokens _: DesignTokens?) -> Color { .orange }

  // MARK: - Screen & Input Colors

  static func screenBackground(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBackgroundPrimary ?? Color(.systemBackground)
  }

  static func inputBackground(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBackgroundOutlinedDefault ?? Color(.systemGray6)
  }

  static func inputText(tokens: DesignTokens?) -> Color {
    tokens?.primerColorTextOutlinedDefault ?? .primary
  }

  static func inputBorder(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBorderOutlinedDefault ?? Color(.systemGray4)
  }

  static func inputBorderFocused(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBorderOutlinedFocus ?? .blue
  }

  static func error(tokens: DesignTokens?) -> Color {
    tokens?.primerColorTextNegative ?? .red
  }

  // MARK: - Button Colors

  static func buttonPrimary(tokens: DesignTokens?) -> Color {
    tokens?.primerColorBrand ?? .blue
  }

  static func buttonDisabled(tokens: DesignTokens?) -> Color {
    tokens?.primerColorGray300 ?? Color(.systemGray4)
  }

  static func buttonTextPrimary(tokens _: DesignTokens?) -> Color {
    .white
  }
}
