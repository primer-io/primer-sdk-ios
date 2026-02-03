//
//  CheckoutColors.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

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
    tokens?.primerColorBackground ?? .white
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

  static func gray700(tokens: DesignTokens?) -> Color {
    tokens?.primerColorGray700 ?? Color(.systemGray)
  }

  static func textPlaceholder(tokens: DesignTokens?) -> Color {
    tokens?.primerColorTextPlaceholder ?? Color(.tertiaryLabel)
  }

  static func iconPositive(tokens: DesignTokens?) -> Color {
    tokens?.primerColorIconPositive ?? Color(.systemGreen)
  }

  static func white(tokens _: DesignTokens?) -> Color {
    .white
  }

  static func gray(tokens _: DesignTokens?) -> Color {
    .gray
  }

  static func blue(tokens _: DesignTokens?) -> Color {
    .blue
  }

  static func green(tokens _: DesignTokens?) -> Color {
    .green
  }

  static func orange(tokens _: DesignTokens?) -> Color {
    .orange
  }

  static func primary(tokens _: DesignTokens?) -> Color {
    .primary
  }

  static func secondary(tokens _: DesignTokens?) -> Color {
    .secondary
  }

  static func clear(tokens _: DesignTokens?) -> Color {
    .clear
  }
}
