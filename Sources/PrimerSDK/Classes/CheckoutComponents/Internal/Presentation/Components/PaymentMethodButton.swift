//
//  PaymentMethodButton.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// A button component for displaying a payment method in the selection list
@available(iOS 15.0, *)
struct PaymentMethodButton: View {
    let method: CheckoutPaymentMethod
    let customItem: PaymentMethodItemComponent?
    let onSelect: () -> Void

    @Environment(\.designTokens) private var tokens

    var body: some View {
        if let customItem {
            AnyView(customItem(method))
                .onTapGesture { onSelect() }
        } else {
            Button(action: onSelect) {
                HStack(spacing: PrimerSpacing.large(tokens: tokens)) {
                    icon
                    Text(method.name)
                        .font(PrimerFont.bodyLarge(tokens: tokens))
                        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
                .padding(.vertical, PrimerSpacing.medium(tokens: tokens))
                .frame(minHeight: PrimerComponentHeight.paymentMethodCard)
                .background(
                    RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
                        .fill(method.backgroundColor.map(Color.init) ?? CheckoutColors.background(tokens: tokens))
                )
            }
            .buttonStyle(PaymentMethodButtonStyle())
        }
    }

    @ViewBuilder
    private var icon: some View {
        let image = method.icon ?? PrimerPaymentMethodType(rawValue: method.type)?.defaultImageName.image
        if let image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: PrimerComponentWidth.paymentMethodIcon, height: PrimerSize.large(tokens: tokens))
        }
    }
}

// MARK: - Button Style

@available(iOS 15.0, *)
struct PaymentMethodButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
