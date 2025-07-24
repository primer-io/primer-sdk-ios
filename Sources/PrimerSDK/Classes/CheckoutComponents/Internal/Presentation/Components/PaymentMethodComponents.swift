//
//  PaymentMethodComponents.swift
//  PrimerSDK
//
//  Created by Boris on 15.7.25.
//

import SwiftUI

// MARK: - Generic Payment Method Screen

/// Generic payment method screen that dynamically resolves and displays any payment method
@available(iOS 15.0, *)
@MainActor
internal struct PaymentMethodScreen: View {
    let paymentMethodType: String
    let checkoutScope: PrimerCheckoutScope

    var body: some View {
        // Truly generic dynamic scope resolution for ANY payment method
        Group {
            // Use checkout scope's cached method to ensure field customizations are preserved
            // For card forms, use the generic method to ensure we get the right cached instance
            if paymentMethodType == "PAYMENT_CARD",
               let cardFormScope = checkoutScope.getPaymentMethodScope(DefaultCardFormScope.self) {
                // Check if custom screen is provided, otherwise use default
                if let customScreen = cardFormScope.screen {
                    customScreen(cardFormScope)
                } else {
                    AnyView(CardFormScreen(scope: cardFormScope))
                }
            } else if let paymentMethodScope = try? PaymentMethodRegistry.shared.createScope(
                for: paymentMethodType,
                checkoutScope: checkoutScope,
                diContainer: (checkoutScope as? DefaultCheckoutScope)?.diContainer ?? DIContainer.shared
            ) {
                // For non-card payment methods in the future, we'll add similar type checks here
                // For now, show placeholder for non-card payment methods
                PaymentMethodPlaceholder(paymentMethodType: paymentMethodType)
            } else {
                // This payment method doesn't have a scope implementation yet
                // Show placeholder that works for any payment method type
                PaymentMethodPlaceholder(paymentMethodType: paymentMethodType)
            }
        }
    }
}

/// Placeholder screen for payment methods that don't have implemented scopes yet
@available(iOS 15.0, *)
@MainActor
internal struct PaymentMethodPlaceholder: View {
    let paymentMethodType: String

    var body: some View {
        AnyView(
            VStack(spacing: 16) {
                Image(systemName: paymentMethodIcon)
                    .font(.system(size: 48))
                    .foregroundColor(.gray)

                Text("Payment Method: \(displayName)")
                    .font(.headline)

                Text("Implementation coming soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
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
