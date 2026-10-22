//
//  PrimerTypographyModifier.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Applies a typography style's family, size, weight, line height and letter spacing.
@available(iOS 15.0, *)
private struct PrimerTypographyModifier: ViewModifier {
  let style: PrimerTextStyle
  let tokens: DesignTokens?
  let fillsLineHeight: Bool

  func body(content: Content) -> some View {
    let font = style.uiFont(tokens: tokens)
    let leading = extraLeading(over: font)
    return
      content
      .font(Font(font))
      .lineSpacing(leading)
      // lineSpacing only sits between lines, so half the leading goes above and below to give a
      // single line the same box height Android and web give it.
      .padding(.vertical, leading / 2)
      .primerLetterSpacing(style.letterSpacing(tokens: tokens))
  }

  /// What the token line height asks for beyond the space the font already occupies.
  private func extraLeading(over font: UIFont) -> CGFloat {
    guard fillsLineHeight, let lineHeight = style.lineHeight(tokens: tokens) else { return 0 }
    return max(0, lineHeight - font.lineHeight)
  }
}

@available(iOS 15.0, *)
extension View {
  /// Applies all five settings of a typography style.
  func primerTypography(_ style: PrimerTextStyle, tokens: DesignTokens?) -> some View {
    modifier(PrimerTypographyModifier(style: style, tokens: tokens, fillsLineHeight: true))
  }

  /// Applies every setting but line height, for a single-line input whose height belongs to the
  /// field around it rather than to the text.
  func primerFieldTypography(_ style: PrimerTextStyle, tokens: DesignTokens?) -> some View {
    modifier(PrimerTypographyModifier(style: style, tokens: tokens, fillsLineHeight: false))
  }
}

@available(iOS 15.0, *)
private extension View {
  /// `tracking` arrived in iOS 16, so on iOS 15 letter spacing reaches only the UIKit-backed fields.
  @ViewBuilder
  func primerLetterSpacing(_ letterSpacing: CGFloat?) -> some View {
    if #available(iOS 16.0, *), let letterSpacing {
      tracking(letterSpacing)
    } else {
      self
    }
  }
}
