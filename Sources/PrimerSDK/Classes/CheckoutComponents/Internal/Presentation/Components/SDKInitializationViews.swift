//
//  SDKInitializationViews.swift
//  PrimerSDK
//
//  Created by Boris on 15.7.25.
//

import SwiftUI

// MARK: - SDK Initialization UI Components

/// Error view shown when SDK initialization fails
@available(iOS 15.0, *)
internal struct SDKInitializationErrorView: View {
    let error: PrimerError
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text(CheckoutComponentsStrings.paymentSystemError)
                .font(.headline)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(CheckoutComponentsStrings.retryButton) {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
