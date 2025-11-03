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
            paymentMethodLogo

            Text(CheckoutComponentsStrings.paymentMethodDisplayName(displayName))
                .font(PrimerFont.headline(tokens: tokens))

            Text(CheckoutComponentsStrings.implementationComingSoon)
                .font(PrimerFont.subheadline(tokens: tokens))
                .foregroundColor(PrimerCheckoutColors.secondary(tokens: tokens))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    }

    private var displayName: String {
        // Use raw value with proper formatting as fallback
        // Converts "PAYMENT_CARD" → "Payment Card", "PAYPAL" → "Paypal"
        paymentMethodType
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}
