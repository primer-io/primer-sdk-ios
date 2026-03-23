//
//  SuccessScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct SuccessScreen: View {
  let result: PaymentResult
  let onDismiss: (() -> Void)?

  @Environment(\.designTokens) private var tokens
  @State private var iconScale: CGFloat = 0.3

  init(result: PaymentResult, onDismiss: (() -> Void)? = nil) {
    self.result = result
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

        VStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
          // Primary success message
          Text(CheckoutComponentsStrings.paymentSuccessful)
            .font(PrimerFont.bodyLarge(tokens: tokens))
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
            .multilineTextAlignment(.center)

          // Secondary redirect message
          Text(CheckoutComponentsStrings.redirectConfirmationMessage)
            .font(PrimerFont.bodyMedium(tokens: tokens))
            .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
            .multilineTextAlignment(.center)
        }
      }
      .padding(.horizontal, PrimerSpacing.xxlarge(tokens: tokens))
    }
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        withAnimation(AnimationConstants.successSpringAnimation) {
          iconScale = 1.0
        }
      }
    }
    .task {
      try? await Task.sleep(nanoseconds: UInt64(AnimationConstants.autoDismissDelay * 1_000_000_000))
      onDismiss?()
    }
  }
}
