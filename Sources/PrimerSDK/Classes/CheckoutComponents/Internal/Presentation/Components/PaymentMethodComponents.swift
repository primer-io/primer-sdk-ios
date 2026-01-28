//
//  PaymentMethodComponents.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Generic Payment Method Screen

/// Generic payment method screen that dynamically resolves and displays any payment method
@available(iOS 15.0, *)
@MainActor
struct PaymentMethodScreen: View {
  let paymentMethodType: String
  let checkoutScope: PrimerCheckoutScope

  @ViewBuilder
  var body: some View {
    // Truly generic dynamic view resolution via registry - NO hardcoded payment method checks!
    // Each payment method registers its own view builder, making this fully extensible
    if let paymentMethodView = PaymentMethodRegistry.shared.getView(
      for: paymentMethodType,
      checkoutScope: checkoutScope
    ) {
      // Payment method has a registered view implementation
      paymentMethodView
    } else {
      // Payment method not registered or doesn't have view implementation yet
      // Show placeholder that works for any payment method type
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
  let checkoutScope: PrimerCheckoutScope

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
      // Try to navigate back if we have access to the navigator, otherwise just show cancel
      if let defaultScope = checkoutScope as? DefaultCheckoutScope {
        Button(
          action: {
            defaultScope.checkoutNavigator.navigateBack()
          },
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
      } else {
        // Fallback to cancel button if we can't access internal navigator
        Button(
          CheckoutComponentsStrings.cancelButton,
          action: {
            checkoutScope.onDismiss()
          }
        )
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        .accessibility(
          config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.Common.closeButton,
            label: CheckoutComponentsStrings.a11yCancel,
            traits: [.isButton]
          ))
      }

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
      .frame(width: 80, height: 80)
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
