//
//  ErrorScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct ErrorScreen: View {
  let error: PrimerError
  let onRetry: (() -> Void)?
  let onChooseOtherPaymentMethods: (() -> Void)?

  @Environment(\.designTokens) private var tokens
  @Environment(\.sizeCategory) private var sizeCategory  // Observes Dynamic Type changes

  init(
    error: PrimerError,
    onRetry: (() -> Void)? = nil,
    onChooseOtherPaymentMethods: (() -> Void)? = nil
  ) {
    self.error = error
    self.onRetry = onRetry
    self.onChooseOtherPaymentMethods = onChooseOtherPaymentMethods
  }

  var body: some View {
    VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
      Spacer()

      Image(systemName: "exclamationmark.triangle.fill")
        .font(PrimerFont.largeIcon(tokens: tokens))
        .foregroundColor(CheckoutColors.borderError(tokens: tokens))

      Text(CheckoutComponentsStrings.paymentFailed)
        .font(PrimerFont.titleLarge(tokens: tokens))
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

      Text(error.errorDescription ?? CheckoutComponentsStrings.unexpectedError)
        .font(PrimerFont.bodyMedium(tokens: tokens))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        .multilineTextAlignment(.center)
        .padding(.horizontal, PrimerSpacing.xxlarge(tokens: tokens))

      Spacer()

      VStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
        makeRetryButton()
        makeOtherPaymentButton()
      }
      .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
      .padding(.bottom, PrimerSpacing.xxlarge(tokens: tokens))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(CheckoutColors.background(tokens: tokens))
  }

  @ViewBuilder
  private func makeRetryButton() -> some View {
    Button {
      onRetry?()
    } label: {
      Text(CheckoutComponentsStrings.retryButton)
        .font(PrimerFont.bodyMedium(tokens: tokens))
        .fontWeight(.semibold)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, PrimerSpacing.medium(tokens: tokens))
        .background(CheckoutColors.blue(tokens: tokens))
        .cornerRadius(PrimerRadius.medium(tokens: tokens))
    }
  }

  @ViewBuilder
  private func makeOtherPaymentButton() -> some View {
    Button {
      onChooseOtherPaymentMethods?()
    } label: {
      Text(CheckoutComponentsStrings.chooseOtherPaymentMethod)
        .font(PrimerFont.bodyMedium(tokens: tokens))
        .fontWeight(.semibold)
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        .frame(maxWidth: .infinity)
        .padding(.vertical, PrimerSpacing.medium(tokens: tokens))
        .background(Color.clear)
        .overlay(
          RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
            .stroke(CheckoutColors.borderDefault(tokens: tokens), lineWidth: 1)
        )
    }
  }
}
