//
//  DefaultCheckoutDemo.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import PrimerSDK

// MARK: - Default Checkout Demo

/// Self-contained demo showing the default PrimerCheckout with SDK-provided UI.
/// This demo handles its own session creation and PrimerCheckout initialization.
@available(iOS 15.0, *)
struct DefaultCheckoutDemo: View, CheckoutComponentsDemo {

    // MARK: - Metadata

    static var metadata: DemoMetadata {
        DemoMetadata(
            name: "Default Checkout",
            description: "Standard CheckoutComponents with SDK-provided UI",
            tags: ["PAYMENT_CARD", "APPLE_PAY"],
            isCustom: false
        )
    }

    // MARK: - Configuration

    private let configuration: DemoConfiguration

    // MARK: - State

    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var clientToken: String?
    @State private var isLoading = true
    @State private var error: String?

    // MARK: - Init

    init(configuration: DemoConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            contentView
                .navigationTitle(Self.metadata.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
        .task {
            await createSession()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            LoadingView()
        } else if let error {
            ErrorView(error: error, onRetry: { Task { await createSession() } })
        } else if let clientToken {
            checkoutView(clientToken: clientToken)
        }
    }

    private func checkoutView(clientToken: String) -> some View {
        VStack(spacing: 0) {
            infoHeader

            VStack {
                Text("Pure SwiftUI PrimerCheckout")
                    .font(.headline)
                    .padding()

                Text("Client Token: \(clientToken.prefix(20))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)

                PrimerCheckout(
                    clientToken: clientToken,
                    primerSettings: configuration.settings,
                    onCompletion: { _ in dismiss() }
                )
            }
        }
    }

    private var infoHeader: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Self.metadata.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Tags: \(Self.metadata.tags.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
        }
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }

    // MARK: - Session Creation

    private func createSession() async {
        isLoading = true
        error = nil

        guard let clientSession = configuration.clientSession else {
            error = "No session configuration provided - please configure session in main settings"
            isLoading = false
            return
        }

        do {
            clientToken = try await NetworkingUtils.requestClientSession(
                body: clientSession,
                apiVersion: configuration.apiVersion
            )
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}
