//
//  SuccessScreen.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 27.6.25.
//

import SwiftUI

/// Success screen for CheckoutComponents with auto-dismiss functionality
@available(iOS 15.0, *)
internal struct SuccessScreen: View {
    let result: CheckoutPaymentResult
    let onDismiss: (() -> Void)?

    @Environment(\.designTokens) private var tokens
    @State private var dismissTimer: Timer?

    init(result: CheckoutPaymentResult, onDismiss: (() -> Void)? = nil) {
        self.result = result
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 24) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(tokens?.primerColorGreen500 ?? .green)

            // Success title
            Text(CheckoutComponentsStrings.paymentSuccessful)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)

            // Payment details
            VStack(spacing: 8) {
                if !result.paymentId.isEmpty {
                    HStack {
                        Text(CheckoutComponentsStrings.paymentId)
                            .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                        Spacer()
                        Text(result.paymentId)
                            .fontWeight(.medium)
                            .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
                    }
                }

                if !result.amount.isEmpty && result.amount != "N/A" {
                    HStack {
                        Text(CheckoutComponentsStrings.amount)
                            .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                        Spacer()
                        Text(result.amount)
                            .fontWeight(.medium)
                            .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
                    }
                }

                if !result.method.isEmpty {
                    HStack {
                        Text(CheckoutComponentsStrings.paymentMethod)
                            .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                        Spacer()
                        Text(result.method)
                            .fontWeight(.medium)
                            .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
                    }
                }
            }
            .padding(.horizontal, 32)
            .font(.body)

            // Auto-dismiss message
            Text(CheckoutComponentsStrings.autoDismissMessage)
                .font(.caption)
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
