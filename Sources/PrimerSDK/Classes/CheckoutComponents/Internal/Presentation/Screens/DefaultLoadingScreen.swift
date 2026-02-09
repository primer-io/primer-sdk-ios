//
//  DefaultLoadingScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Default loading screen shown during payment processing.
/// Displays a centered loading indicator with "Loading" text.
/// Merchants can replace this with a custom view via `checkoutScope.loading`.
@available(iOS 15.0, *)
struct DefaultLoadingScreen: View {
  @Environment(\.designTokens) private var tokens

  var body: some View {
    VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
      ProgressView()
        .progressViewStyle(
          CircularProgressViewStyle(tint: CheckoutColors.borderFocus(tokens: tokens))
        )
        .scaleEffect(PrimerScale.large)
        .accessibility(
          config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.Common.loadingIndicator,
            label: CheckoutComponentsStrings.a11yLoading
          ))

      Text(CheckoutComponentsStrings.loading)
        .font(PrimerFont.bodyMedium(tokens: tokens))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
    }
    .frame(height: 300)
    .frame(maxWidth: .infinity)
    .background(CheckoutColors.background(tokens: tokens))
  }
}
