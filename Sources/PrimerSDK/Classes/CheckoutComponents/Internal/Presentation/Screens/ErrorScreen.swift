//
//  ErrorScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
struct ErrorScreen: View {
  let onRetry: (() -> Void)?
  let onChooseOtherPaymentMethods: (() -> Void)?

  @Environment(\.designTokens) private var tokens

  init(
    onRetry: (() -> Void)? = nil,
    onChooseOtherPaymentMethods: (() -> Void)? = nil
  ) {
    self.onRetry = onRetry
    self.onChooseOtherPaymentMethods = onChooseOtherPaymentMethods
  }

  var body: some View {
    VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
      Spacer()

      Image(systemName: "exclamationmark.triangle.fill")
        .font(PrimerFont.largeIcon(tokens: tokens))
        .foregroundColor(CheckoutColors.iconNegative(tokens: tokens))
        .accessibilityIdentifier(AccessibilityIdentifiers.Error.icon)
        .accessibilityHidden(true)

      Text(CheckoutComponentsStrings.paymentFailed)
        .primerTypography(.titleLarge, tokens: tokens)
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        .accessibilityIdentifier(AccessibilityIdentifiers.Error.title)
        .accessibilityAddTraits(.isHeader)

      // The error's own text is written for developers; merchants get it in the failure callback and the logs.
      Text(CheckoutComponentsStrings.paymentFailedMessage)
        .primerTypography(.bodyMedium, tokens: tokens)
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        .multilineTextAlignment(.center)
        .padding(.horizontal, PrimerSpacing.xxlarge(tokens: tokens))
        .accessibilityIdentifier(AccessibilityIdentifiers.Error.description)

      Spacer()

      VStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
        if onRetry != nil {
          makeRetryButton()
        }
        if onChooseOtherPaymentMethods != nil {
          makeOtherPaymentButton()
        }
      }
      .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
      .padding(.bottom, PrimerSpacing.large(tokens: tokens))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(CheckoutColors.background(tokens: tokens))
  }

  private func makeRetryButton() -> some View {
    PrimerCheckoutButton(
      CheckoutComponentsStrings.retryButton,
      accessibilityConfiguration: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.Error.retryButton,
        label: CheckoutComponentsStrings.retryButton,
        traits: [.isButton]
      ),
      action: { onRetry?() }
    )
  }

  private func makeOtherPaymentButton() -> some View {
    Button {
      onChooseOtherPaymentMethods?()
    } label: {
      Text(CheckoutComponentsStrings.chooseOtherPaymentMethod)
        .primerTypography(.bodyMedium, tokens: tokens)
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        .frame(maxWidth: .infinity)
        .padding(.vertical, PrimerSpacing.medium(tokens: tokens))
        .background(Color.clear)
        .overlay(
          RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
            .stroke(
              CheckoutColors.borderDefault(tokens: tokens),
              lineWidth: PrimerBorderWidth.standard(tokens: tokens))
        )
        .contentShape(RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens)))
    }
    .buttonStyle(PlainButtonStyle())
    .accessibility(
      config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.Error.otherPaymentMethodButton,
        label: CheckoutComponentsStrings.chooseOtherPaymentMethod,
        traits: [.isButton]
      ))
  }
}
