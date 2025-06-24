//
//  SuccessScreen.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Default success screen for CheckoutComponents
@available(iOS 15.0, *)
internal struct SuccessScreen: View {
    let paymentResult: PaymentResult
    let onDismiss: (() -> Void)?

    @Environment(\.designTokens) private var tokens
    @State private var showCheckmark = false

    var body: some View {
        VStack(spacing: 24) {
            // Success animation
            ZStack {
                Circle()
                    .fill(tokens?.primerColorIconPositive ?? .green)
                    .frame(width: 80, height: 80)
                    .scaleEffect(showCheckmark ? 1.0 : 0.5)
                    .opacity(showCheckmark ? 1.0 : 0.0)

                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(showCheckmark ? 1.0 : 0.5)
                    .opacity(showCheckmark ? 1.0 : 0.0)
            }

            // Success title
            Text("Payment Successful")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)

            // Payment details
            VStack(spacing: 8) {
                HStack {
                    Text("Payment ID:")
                        .font(.caption)
                        .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                    Text(paymentResult.paymentId)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
                }
            }
            .padding(.horizontal, 32)

            // Dismiss button (user-controlled only)
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Text("Done")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(tokens?.primerColorTextPrimary ?? .blue)
                        .cornerRadius(8)
                }
                .padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(tokens?.primerColorBackground ?? Color(.systemBackground))
        .onAppear {
            // Show checkmark animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showCheckmark = true
            }
        }
    }
}
