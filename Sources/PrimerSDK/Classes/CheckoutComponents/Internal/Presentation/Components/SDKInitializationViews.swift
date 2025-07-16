//
//  SDKInitializationViews.swift
//  PrimerSDK
//
//  Created by Boris on 15.7.25.
//

import SwiftUI

// MARK: - SDK Initialization UI Components

/// Loading view shown during SDK initialization
@available(iOS 15.0, *)
internal struct SDKInitializationLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Initializing payment system...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

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

            Text("Payment System Error")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
