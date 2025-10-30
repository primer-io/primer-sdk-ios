//
//  SDKInitializationViews.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - SDK Initialization UI Components

/// Error view shown when SDK initialization fails
@available(iOS 15.0, *)
struct SDKInitializationErrorView: View {
    let error: PrimerError
    let onRetry: () -> Void
    @Environment(\.designTokens) private var tokens

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(PrimerFont.largeIcon(tokens: tokens))
                .foregroundColor(PrimerCheckoutColors.orange(tokens: tokens))

            Text(CheckoutComponentsStrings.paymentSystemError)
                .font(PrimerFont.headline(tokens: tokens))

            Text(error.localizedDescription)
                .font(PrimerFont.subheadline(tokens: tokens))
                .foregroundColor(PrimerCheckoutColors.secondary(tokens: tokens))
                .multilineTextAlignment(.center)
                .padding(.horizontal, PrimerSpacing.large(tokens: tokens))

            Button(CheckoutComponentsStrings.retryButton) {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(PrimerSpacing.large(tokens: tokens))
    }
}
