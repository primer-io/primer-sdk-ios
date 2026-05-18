//
//  PaymentMethodComponents.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
@MainActor
struct PaymentMethodScreen: View {
  let paymentMethodType: String
  let checkoutScope: any CheckoutScopeInternal

  @ViewBuilder
  var body: some View {
    if let paymentMethodView = PaymentMethodRegistry.shared.getView(
      for: paymentMethodType,
      checkoutScope: checkoutScope
    ) {
      paymentMethodView
    } else {
      AnyView(
        PaymentMethodPlaceholder(
          paymentMethodType: paymentMethodType,
          checkoutScope: checkoutScope
        ))
    }
  }
}

/// Placeholder screen for payment methods that don't have implemented scopes yet
@available(iOS 15.0, *)
@MainActor
struct PaymentMethodPlaceholder: View {
  let paymentMethodType: String
  let checkoutScope: any CheckoutScopeInternal

  @Environment(\.designTokens) private var tokens
  @Environment(\.sizeCategory) private var sizeCategory  // Observes Dynamic Type changes

  var body: some View {
    VStack(spacing: 0) {
      navigationBar

      VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
        Spacer()

        paymentMethodLogo

        Text(CheckoutComponentsStrings.paymentMethodDisplayName(displayName))
          .font(PrimerFont.headline(tokens: tokens))

        Text(CheckoutComponentsStrings.implementationComingSoon)
          .font(PrimerFont.subheadline(tokens: tokens))
          .foregroundColor(CheckoutColors.secondary(tokens: tokens))

        Spacer()
      }
      .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(CheckoutColors.background(tokens: tokens))
  }

  private var navigationBar: some View {
    HStack {
      Button(
        action: checkoutScope.checkoutNavigator.navigateBack,
        label: {
          HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
            Image(systemName: RTLIcon.backChevron)
              .font(PrimerFont.bodyMedium(tokens: tokens))
            Text(CheckoutComponentsStrings.backButton)
          }
          .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        }
      )
      .accessibility(
        config: AccessibilityConfiguration(
          identifier: AccessibilityIdentifiers.Common.backButton,
          label: CheckoutComponentsStrings.a11yBack,
          traits: [.isButton]
        ))

      Spacer()
    }
    .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
    .padding(.vertical, PrimerSpacing.medium(tokens: tokens))
  }

  /// Payment method logo using bundled assets (same pattern as PaymentMethodSelectionScreen)
  private var paymentMethodLogo: some View {
    // Use bundled asset images based on payment method type
    let paymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodType)
    let imageName = paymentMethodType?.defaultImageName ?? .genericCard
    let fallbackImage = imageName.image

    return Image(uiImage: fallbackImage ?? UIImage())
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: PrimerIconSize.paymentMethodLargeWidth, height: PrimerIconSize.paymentMethodLargeHeight)
      .accessibilityHidden(true)  // Decorative image, payment method name is announced via text
  }

  private var displayName: String {
    // Use raw value with proper formatting as fallback
    // Converts "PAYMENT_CARD" → "Payment Card", "PAYPAL" → "Paypal"
    paymentMethodType
      .replacingOccurrences(of: "_", with: " ")
      .capitalized
  }
}
