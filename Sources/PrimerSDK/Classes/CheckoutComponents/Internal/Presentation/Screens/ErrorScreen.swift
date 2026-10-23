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
  @Environment(\.bridgeController) private var bridgeController

  private let messageVerticalPadding: CGFloat = 48

  init(
    onRetry: (() -> Void)? = nil,
    onChooseOtherPaymentMethods: (() -> Void)? = nil
  ) {
    self.onRetry = onRetry
    self.onChooseOtherPaymentMethods = onChooseOtherPaymentMethods
  }

  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
        Image(systemName: "exclamationmark.triangle.fill")
          .font(PrimerFont.extraLargeIcon(tokens: tokens))
          .foregroundColor(CheckoutColors.iconNegative(tokens: tokens))
          .accessibilityIdentifier(AccessibilityIdentifiers.Error.icon)
          .accessibilityHidden(true)

        VStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
          Text(CheckoutComponentsStrings.paymentFailed)
            .primerTypography(.titleLarge, tokens: tokens)
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
            .multilineTextAlignment(.center)
            .accessibilityIdentifier(AccessibilityIdentifiers.Error.title)
            .accessibilityAddTraits(.isHeader)

          Text(CheckoutComponentsStrings.paymentFailedMessage)
            .primerTypography(.bodyMedium, tokens: tokens)
            .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
            .multilineTextAlignment(.center)
            .accessibilityIdentifier(AccessibilityIdentifiers.Error.description)
        }
      }
      .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
      .padding(.vertical, messageVerticalPadding)

      VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
        if onRetry != nil {
          makeRetryButton()
        }
        if onChooseOtherPaymentMethods != nil {
          makeOtherPaymentButton()
        }
      }
    }
    .padding(PrimerSpacing.large(tokens: tokens))
    .frame(maxWidth: .infinity)
    .background(CheckoutColors.background(tokens: tokens))
    .onAppear {
      bridgeController?.invalidateContentSize()
    }
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
