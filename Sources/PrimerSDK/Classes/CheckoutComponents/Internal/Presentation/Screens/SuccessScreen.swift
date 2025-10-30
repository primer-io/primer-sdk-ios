//
//  SuccessScreen.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 27.6.25.
//

import SwiftUI

/// Success screen for CheckoutComponents with auto-dismiss functionality
@available(iOS 15.0, *)
struct SuccessScreen: View {
    let result: CheckoutPaymentResult
    let onDismiss: (() -> Void)?

    @Environment(\.designTokens) private var tokens
    @State private var dismissTimer: Timer?

    init(result: CheckoutPaymentResult, onDismiss: (() -> Void)? = nil) {
        self.result = result
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            PrimerCheckoutColors.background(tokens: tokens)
                .ignoresSafeArea()

            VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
                Image(systemName: "checkmark.circle.fill")
                    .font(PrimerFont.extraLargeIcon(tokens: tokens))
                    .foregroundColor(PrimerCheckoutColors.green(tokens: tokens))

                VStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
                    // Primary success message
                    Text(CheckoutComponentsStrings.paymentSuccessful)
                        .font(PrimerFont.bodyLarge(tokens: tokens))
                        .foregroundColor(PrimerCheckoutColors.textPrimary(tokens: tokens))
                        .multilineTextAlignment(.center)

                    // Secondary redirect message
                    Text(CheckoutComponentsStrings.redirectConfirmationMessage)
                        .font(PrimerFont.bodyMedium(tokens: tokens))
                        .foregroundColor(PrimerCheckoutColors.textSecondary(tokens: tokens))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, PrimerSpacing.xxlarge(tokens: tokens))
        }
        .onAppear {
            startAutoDismissTimer()
        }
        .onDisappear {
            dismissTimer?.invalidate()
            dismissTimer = nil
        }
    }

    private func startAutoDismissTimer() {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: AnimationConstants.autoDismissDelay, repeats: false) { _ in
            onDismiss?()
        }
    }
}
