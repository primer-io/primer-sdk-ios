//
//  DefaultLoadingScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

@available(iOS 15.0, *)
struct DefaultLoadingScreen: View {
  var title = CheckoutComponentsStrings.loading
  var subtitle: String?
  var accessibilityLabel = CheckoutComponentsStrings.a11yLoading
  @Environment(\.designTokens) private var tokens

  var body: some View {
    VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
      ProgressView()
        .progressViewStyle(
          CircularProgressViewStyle(tint: CheckoutColors.loader(tokens: tokens))
        )
        .scaleEffect(PrimerScale.large)
        .accessibility(
          config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.Common.loadingIndicator,
            label: accessibilityLabel
          ))

      makeText()
    }
    .frame(maxWidth: .infinity, minHeight: 300)
    .background(CheckoutColors.background(tokens: tokens))
    .accessibilityIdentifier(AccessibilityIdentifiers.Common.loadingIndicator)
  }

  @ViewBuilder
  private func makeText() -> some View {
    if let subtitle {
      VStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
        Text(title)
          .primerTypography(.bodyLarge, tokens: tokens)
          .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        Text(subtitle)
          .primerTypography(.bodyMedium, tokens: tokens)
          .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
      }
      .multilineTextAlignment(.center)
      .padding(.horizontal, PrimerSpacing.xxlarge(tokens: tokens))
    } else {
      Text(title)
        .primerTypography(.bodyMedium, tokens: tokens)
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
    }
  }
}
