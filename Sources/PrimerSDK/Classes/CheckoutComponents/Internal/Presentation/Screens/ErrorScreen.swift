//
//  ErrorScreen.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Default error screen for CheckoutComponents
@available(iOS 15.0, *)
internal struct ErrorScreen: View {
    let error: PrimerError
    let onRetry: (() -> Void)?

    @Environment(\.designTokens) private var tokens

    var body: some View {
        VStack(spacing: 24) {
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(tokens?.primerColorBorderOutlinedError ?? .red)

            // Error title
            Text("Something went wrong")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)

            // Error message
            Text(error.errorDescription ?? "An unexpected error occurred. Please try again.")
                .font(.body)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Retry button
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Text("Try Again")
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
    }
}
