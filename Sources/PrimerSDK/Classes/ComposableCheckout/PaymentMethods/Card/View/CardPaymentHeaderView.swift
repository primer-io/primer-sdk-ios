//
//  CardPaymentHeaderView.swift
//  PrimerSDK
//
//  Created by Claude Code on 25.03.2025.
//

import SwiftUI

@available(iOS 15.0, *)
internal struct CardPaymentHeaderView: View {
    let onBackTapped: () -> Void
    let onCancelTapped: () -> Void
    let animationConfig: CardPaymentAnimationConfiguration

    @Environment(\.designTokens) private var tokens
    @State private var isBackPressed = false
    @State private var isCancelPressed = false

    init(
        onBackTapped: @escaping () -> Void,
        onCancelTapped: @escaping () -> Void,
        animationConfig: CardPaymentAnimationConfiguration = .default
    ) {
        self.onBackTapped = onBackTapped
        self.onCancelTapped = onCancelTapped
        self.animationConfig = animationConfig
    }

    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar with back and cancel buttons
            HStack {
                // Back button
                Button(action: onBackTapped) {
                    HStack(spacing: CardPaymentDesign.fieldHorizontalSpacing(from: tokens) / 2) {
                        Image(systemName: "arrow.backward")
                            .font(.system(size: 16, weight: .medium))
                        Text(CardPaymentLocalizable.backButton)
                            .font(CardPaymentDesign.bodyFont(from: tokens))
                    }
                    .foregroundColor(tokens?.primerColorBrand ?? .blue)
                }
                .cardPaymentButtonPress(isPressed: isBackPressed, config: animationConfig)
                .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                    isBackPressed = pressing
                }, perform: {})
                .accessibilityIdentifier("card_payment_button_back")
                .accessibilityLabel(CardPaymentLocalizable.backButton)
                .accessibilityHint(CardPaymentLocalizable.backButtonHint)

                Spacer()

                // Cancel button
                Button(action: onCancelTapped) {
                    Text(CardPaymentLocalizable.cancelButton)
                        .font(CardPaymentDesign.bodyFont(from: tokens))
                        .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                }
                .cardPaymentButtonPress(isPressed: isCancelPressed, config: animationConfig)
                .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                    isCancelPressed = pressing
                }, perform: {})
                .accessibilityIdentifier("card_payment_button_cancel")
                .accessibilityLabel(CardPaymentLocalizable.cancelButton)
                .accessibilityHint(CardPaymentLocalizable.cancelButtonHint)
            }
            .padding(.horizontal, CardPaymentDesign.containerPadding(from: tokens))
            .padding(.top, CardPaymentDesign.fieldVerticalSpacing(from: tokens))

            // Title
            HStack {
                Text(CardPaymentLocalizable.payWithCardTitle)
                    .font(CardPaymentDesign.titleFont(from: tokens))
                    .foregroundColor(CardPaymentDesign.titleColor(from: tokens))
                    .accessibilityIdentifier("card_payment_header_title")
                    .accessibilityAddTraits(.isHeader)

                Spacer()
            }
            .padding(.horizontal, CardPaymentDesign.containerPadding(from: tokens))
            .padding(.top, CardPaymentDesign.headerBottomSpacing(from: tokens))
        }
        .background(CardPaymentDesign.backgroundColor(from: tokens))
    }
}

// MARK: - Preview Provider
@available(iOS 15.0, *)
struct CardPaymentHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CardPaymentHeaderView(
                onBackTapped: { print("Back tapped") },
                onCancelTapped: { print("Cancel tapped") }
            )

            Spacer()
        }
        .previewDisplayName("Default Header")

        VStack {
            CardPaymentHeaderView(
                onBackTapped: { print("Back tapped") },
                onCancelTapped: { print("Cancel tapped") },
                animationConfig: .minimal
            )

            Spacer()
        }
        .previewDisplayName("Minimal Animations")

        VStack {
            CardPaymentHeaderView(
                onBackTapped: { print("Back tapped") },
                onCancelTapped: { print("Cancel tapped") },
                animationConfig: .disabled
            )

            Spacer()
        }
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}
