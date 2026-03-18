//
//  SplashScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct SplashScreen: View {
  @Environment(\.designTokens) private var tokens
  @Environment(\.sizeCategory) private var sizeCategory  // Observes Dynamic Type changes

  var body: some View {
    ZStack {
      CheckoutColors.background(tokens: tokens)
        .ignoresSafeArea()

      VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
        ProgressView()
          .progressViewStyle(
            CircularProgressViewStyle(tint: CheckoutColors.borderFocus(tokens: tokens))
          )
          .scaleEffect(PrimerScale.large)
          .frame(
            width: PrimerComponentHeight.progressIndicator,
            height: PrimerComponentHeight.progressIndicator
          )
          .accessibility(
            config: AccessibilityConfiguration(
              identifier: AccessibilityIdentifiers.Common.loadingIndicator,
              label: CheckoutComponentsStrings.a11yLoading
            ))

        VStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
          // Primary loading message
          Text(CheckoutComponentsStrings.loadingSecureCheckout)
            .font(PrimerFont.bodyLarge(tokens: tokens))
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isStaticText)

          // Secondary loading message
          Text(CheckoutComponentsStrings.loadingWontTakeLong)
            .font(PrimerFont.bodyMedium(tokens: tokens))
            .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isStaticText)
        }
      }
      .padding(.horizontal, PrimerSpacing.xxlarge(tokens: tokens))
    }
  }
}
