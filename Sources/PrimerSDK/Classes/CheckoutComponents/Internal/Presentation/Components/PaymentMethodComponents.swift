//
//  PaymentMethodComponents.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
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
        // Truly generic dynamic scope resolution for ANY payment method
        // Use checkout scope's cached method to ensure field customizations are preserved
        // For card forms, use the generic method to ensure we get the right cached instance
        if paymentMethodType == "PAYMENT_CARD",
           let cardFormScope = checkoutScope.getPaymentMethodScope(DefaultCardFormScope.self) {
            // Check if custom screen is provided, otherwise use default
            if let customScreen = cardFormScope.screen {
                AnyView(customScreen(cardFormScope))
            } else {
                AnyView(CardFormScreen(scope: cardFormScope))
            }
        } else if let container = DIContainer.currentSync,
                  let _ = try? PaymentMethodRegistry.shared.createScope(
                    for: paymentMethodType,
                    checkoutScope: checkoutScope,
                    diContainer: container
                  ) {
            // For non-card payment methods in the future, we'll add similar type checks here
            // For now, show placeholder for non-card payment methods
            AnyView(PaymentMethodPlaceholder(paymentMethodType: paymentMethodType))
        } else {
            // This payment method doesn't have a scope implementation yet
            // Show placeholder that works for any payment method type
            AnyView(PaymentMethodPlaceholder(paymentMethodType: paymentMethodType))
        }
    }
}

/// Placeholder screen for payment methods that don't have implemented scopes yet
@available(iOS 15.0, *)
@MainActor
struct PaymentMethodPlaceholder: View {
    let paymentMethodType: String
    @Environment(\.designTokens) private var tokens

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: paymentMethodIcon)
                .font(PrimerFont.largeIcon(tokens: tokens))
                .foregroundColor(CheckoutColors.gray(tokens: tokens))

            Text(CheckoutComponentsStrings.paymentMethodDisplayName(displayName))
                .font(PrimerFont.headline(tokens: tokens))

            Text(CheckoutComponentsStrings.implementationComingSoon)
                .font(PrimerFont.subheadline(tokens: tokens))
                .foregroundColor(CheckoutColors.secondary(tokens: tokens))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var displayName: String {
        PrimerPaymentMethodType(rawValue: paymentMethodType)?.checkoutComponentsDisplayName ?? paymentMethodType
    }

    private var paymentMethodIcon: String {
        switch paymentMethodType {
        case "PAYMENT_CARD": return "creditcard"
        case "APPLE_PAY": return "applelogo"
        case "GOOGLE_PAY": return "wallet.pass"
        case "PAYPAL": return "dollarsign.circle"
        default: return "creditcard"
        }
    }
}
