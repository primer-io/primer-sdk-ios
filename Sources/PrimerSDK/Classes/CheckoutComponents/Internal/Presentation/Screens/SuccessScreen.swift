//
//  SuccessScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
struct SuccessScreen: View {
  let title: String
  let message: String
  let onDismiss: (() -> Void)?

  @Environment(\.designTokens) private var tokens
  @State private var iconScale: CGFloat = 0.3

  init(
    title: String = CheckoutComponentsStrings.paymentSuccessful,
    message: String = CheckoutComponentsStrings.redirectConfirmationMessage,
    onDismiss: (() -> Void)? = nil
  ) {
    self.title = title
    self.message = message
    self.onDismiss = onDismiss
  }

  var body: some View {
    ZStack {
      CheckoutColors.background(tokens: tokens)
        .ignoresSafeArea()

      VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
        Image(systemName: "checkmark.circle.fill")
          .font(PrimerFont.extraLargeIcon(tokens: tokens))
          .foregroundColor(CheckoutColors.green(tokens: tokens))
          .scaleEffect(iconScale)
          .accessibilityIdentifier(AccessibilityIdentifiers.Success.icon)
          .accessibilityHidden(true)

        VStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
          // Primary success message
          Text(title)
            .font(PrimerFont.bodyLarge(tokens: tokens))
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
            .multilineTextAlignment(.center)
            .accessibilityIdentifier(AccessibilityIdentifiers.Success.title)
            .accessibilityAddTraits(.isHeader)

          // Secondary redirect message
          Text(message)
            .font(PrimerFont.bodyMedium(tokens: tokens))
            .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
            .multilineTextAlignment(.center)
            .accessibilityIdentifier(AccessibilityIdentifiers.Success.description)
        }
      }
      .padding(.horizontal, PrimerSpacing.xxlarge(tokens: tokens))
      // Without a container element the identifier propagates to every child and hides theirs.
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier(AccessibilityIdentifiers.Success.container)
    }
    .task {
      withAnimation(AnimationConstants.successSpringAnimation) {
        iconScale = 1.0
      }
      try? await Task.sleep(nanoseconds: UInt64(AnimationConstants.autoDismissDelay * 1_000_000_000))
      onDismiss?()
    }
  }
}
