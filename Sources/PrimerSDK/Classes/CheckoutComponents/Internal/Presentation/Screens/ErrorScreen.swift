//
//  ErrorScreen.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Default error screen for CheckoutComponents with auto-dismiss functionality
@available(iOS 15.0, *)
struct ErrorScreen: View {
    let error: PrimerError
    let onDismiss: (() -> Void)?

    @Environment(\.designTokens) private var tokens
    @Environment(\.sizeCategory) private var sizeCategory // Observes Dynamic Type changes
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
                .foregroundColor(CheckoutColors.borderError(tokens: tokens))

            // Error title
            Text(CheckoutComponentsStrings.somethingWentWrong)
                .font(PrimerFont.titleLarge(tokens: tokens))
                .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

            // Error message
            Text(error.errorDescription ?? CheckoutComponentsStrings.unexpectedError)
                .font(PrimerFont.bodyMedium(tokens: tokens))
                .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
                .multilineTextAlignment(.center)
                .padding(.horizontal, PrimerSpacing.xxlarge(tokens: tokens))

            // Auto-dismiss message
            Text(CheckoutComponentsStrings.autoDismissMessage)
                .font(PrimerFont.bodySmall(tokens: tokens))
                .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
                .multilineTextAlignment(.center)
                .padding(.top, PrimerSpacing.large(tokens: tokens))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CheckoutColors.background(tokens: tokens))
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
