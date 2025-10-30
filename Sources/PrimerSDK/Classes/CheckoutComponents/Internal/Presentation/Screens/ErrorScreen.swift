//
//  ErrorScreen.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Default error screen for CheckoutComponents with auto-dismiss functionality
@available(iOS 15.0, *)
struct ErrorScreen: View {
    let error: PrimerError
    let onDismiss: (() -> Void)?

    @Environment(\.designTokens) private var tokens
    @State private var dismissTimer: Timer?

    init(error: PrimerError, onDismiss: (() -> Void)? = nil) {
        self.error = error
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: PrimerSpacing.xxlarge(tokens: tokens)) {
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(PrimerFont.largeIcon(tokens: tokens))
                .foregroundColor(PrimerCheckoutColors.borderError(tokens: tokens))

            // Error title
            Text(CheckoutComponentsStrings.somethingWentWrong)
                .font(PrimerFont.titleLarge(tokens: tokens))
                .foregroundColor(PrimerCheckoutColors.textPrimary(tokens: tokens))

            // Error message
            Text(error.errorDescription ?? CheckoutComponentsStrings.unexpectedError)
                .font(PrimerFont.bodyMedium(tokens: tokens))
                .foregroundColor(PrimerCheckoutColors.textSecondary(tokens: tokens))
                .multilineTextAlignment(.center)
                .padding(.horizontal, PrimerSpacing.xxlarge(tokens: tokens))

            // Auto-dismiss message
            Text(CheckoutComponentsStrings.autoDismissMessage)
                .font(PrimerFont.bodySmall(tokens: tokens))
                .foregroundColor(PrimerCheckoutColors.textSecondary(tokens: tokens))
                .multilineTextAlignment(.center)
                .padding(.top, PrimerSpacing.large(tokens: tokens))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PrimerCheckoutColors.background(tokens: tokens))
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
