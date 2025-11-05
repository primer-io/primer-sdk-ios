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
    @State private var dismissTimer: Timer?

    init(error: PrimerError, onDismiss: (() -> Void)? = nil) {
        self.error = error
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 24) {
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(tokens?.primerColorBorderOutlinedError ?? .red)

            // Error title
            Text(CheckoutComponentsStrings.somethingWentWrong)
                .font(tokens != nil ? PrimerFont.titleLarge(tokens: tokens!) : .title2)
                .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)

            // Error message
            Text(error.errorDescription ?? CheckoutComponentsStrings.unexpectedError)
                .font(tokens != nil ? PrimerFont.bodyMedium(tokens: tokens!) : .body)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Auto-dismiss message
            Text(CheckoutComponentsStrings.autoDismissMessage)
                .font(tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .caption)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(tokens?.primerColorBackground ?? Color(.systemBackground))
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
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            onDismiss?()
        }
    }
}
