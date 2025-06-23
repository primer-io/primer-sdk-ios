//
//  PaymentMethodSelectionScreen.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Default payment method selection screen for CheckoutComponents
@available(iOS 15.0, *)
internal struct PaymentMethodSelectionScreen: View {
    let scope: PrimerPaymentMethodSelectionScope

    @Environment(\.designTokens) private var tokens
    @State private var selectionState: PrimerPaymentMethodSelectionState = .init()
    var body: some View {
        mainContent
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            titleSection
            paymentMethodsList
        }
        .onAppear {
            observeState()
        }
    }

    private var titleSection: some View {
        Text("Select Payment Method")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
    }

    private var paymentMethodsList: some View {
        VStack(spacing: 0) {
            ScrollView {
                if selectionState.paymentMethods.isEmpty {
                    emptyStateView
                } else {
                    paymentMethodsContent
                }
            }

            errorSection
        }
        .background(tokens?.primerColorBackground ?? Color(.systemBackground))
    }

    @ViewBuilder
    private var emptyStateView: some View {
        if let customEmptyState = scope.emptyStateView {
            customEmptyState()
        } else {
            VStack(spacing: 16) {
                Image(systemName: "creditcard.slash")
                    .font(.system(size: 48))
                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)

                Text("No payment methods available")
                    .font(.body)
                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 100)
        }
    }

    private var paymentMethodsContent: some View {
        VStack(spacing: 16) {
            ForEach(selectionState.paymentMethods) { method in
                modernPaymentMethodCard(method)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
    }

    @ViewBuilder
    private func modernPaymentMethodCard(_ method: PrimerComposablePaymentMethod) -> some View {
        if let customPaymentMethodCard = scope.paymentMethodCard {
            let modifier = PrimerModifier()
            customPaymentMethodCard(modifier) {
                scope.onPaymentMethodSelected(paymentMethod: method)
            }
        } else {
            ModernPaymentMethodCardView(
                method: method,
                onTap: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scope.onPaymentMethodSelected(paymentMethod: method)
                    }
                }
            )
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let error = selectionState.error {
            Text(error)
                .font(.caption)
                .foregroundColor(tokens?.primerColorBorderOutlinedError ?? .red)
                .padding()
        }
    }

    private func observeState() {
        Task {
            for await state in scope.state {
                await MainActor.run {
                    self.selectionState = state
                }
            }
        }
    }
}

/// Modern payment method card view matching Image #2 design
@available(iOS 15.0, *)
private struct ModernPaymentMethodCardView: View {
    let method: PrimerComposablePaymentMethod
    let onTap: () -> Void

    @Environment(\.designTokens) private var tokens

    var body: some View {
        Button(action: onTap) {
            contentView
        }
        .buttonStyle(ModernCardButtonStyle())
    }

    private var contentView: some View {
        HStack(spacing: 16) {
            paymentMethodLogo
            methodNameText
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundView)
    }

    @ViewBuilder
    private var paymentMethodLogo: some View {
        if let icon = method.icon {
            Image(uiImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 24)
        } else {
            paymentMethodLogoPlaceholder
        }
    }

    private var paymentMethodLogoPlaceholder: some View {
        // Create logo based on payment method type
        Group {
            switch method.type {
            case "APPLE_PAY":
                applePayLogo
            case "GOOGLE_PAY":
                googlePayLogo
            case "PAYPAL":
                paypalLogo
            case "PAYMENT_CARD":
                cardLogo
            case "KLARNA":
                klarnaLogo
            case "ADYEN_IDEAL":
                idealLogo
            default:
                genericLogo
            }
        }
        .frame(width: 32, height: 24)
    }

    private var applePayLogo: some View {
        HStack(spacing: 2) {
            Image(systemName: "applelogo")
                .font(.system(size: 12, weight: .medium))
            Text("Pay")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.black)
    }

    private var googlePayLogo: some View {
        HStack(spacing: 2) {
            Text("G")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.blue)
            Text("Pay")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
    }

    private var paypalLogo: some View {
        Text("PayPal")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.blue)
    }

    private var cardLogo: some View {
        Image(systemName: "creditcard")
            .font(.system(size: 14))
            .foregroundColor(.gray)
    }

    private var klarnaLogo: some View {
        Text("Klarna")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.pink)
    }

    private var idealLogo: some View {
        Text("iDeal")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.orange)
    }

    private var genericLogo: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(tokens?.primerColorGray200 ?? Color(.systemGray4))
            .overlay(
                Text(String(method.type.prefix(2)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            )
    }

    private var methodNameText: some View {
        Text(method.name)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .overlay(borderOverlay)
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color(.systemGray5), lineWidth: 1)
    }
}

/// Modern button style with subtle press animation
@available(iOS 15.0, *)
private struct ModernCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
