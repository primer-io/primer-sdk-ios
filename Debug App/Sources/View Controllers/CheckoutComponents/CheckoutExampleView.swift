//
//  CheckoutExampleView.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import PrimerSDK

@available(iOS 15.0, *)
struct CheckoutExampleView: View {
    private let example: ExampleConfig
    private let settings: PrimerSettings
    private let apiVersion: PrimerApiVersion
    private let configuredClientSession: ClientSessionRequestBody?

    @SwiftUI.Environment(\.dismiss) private var dismiss
    @SwiftUI.Environment(\.colorScheme) private var colorScheme
    @State private var clientToken: String?
    @State private var isLoading = true
    @State private var error: String?
    @State private var checkoutCompleted = false

    init(example: ExampleConfig, settings: PrimerSettings, apiVersion: PrimerApiVersion, clientSession: ClientSessionRequestBody? = nil) {
        self.example = example
        self.settings = settings
        self.apiVersion = apiVersion
        self.configuredClientSession = clientSession
    }

    var body: some View {
        NavigationView {
            contentView
                .navigationTitle(example.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
        }
        .task {
            await createSession()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error {
                ErrorView(error: error) {
                    Task {
                        await createSession()
                    }
                }
            } else if let clientToken {
                CheckoutContentView(
                    example: example,
                    clientToken: clientToken,
                    settings: settings,
                    onCompletion: onCheckoutCompletion
                )
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            if shouldShowInfoButton {
                Button("Info") {
                    // Show example configuration info
                }
            } else {
                EmptyView()
            }
        }
    }

    private var shouldShowInfoButton: Bool {
        !isLoading && error == nil
    }

    private func onCheckoutCompletion() {
        checkoutCompleted = true
        dismiss()
    }

    private func createSession() async {
        isLoading = true
        error = nil

        // Always use the configured client session from MerchantSessionAndSettingsViewController
        // This preserves the exact configuration from the main UI including currency, billing address, surcharge, etc.
        guard let configuredClientSession else {
            self.error = "No session configuration provided - please configure session in main settings"
            self.isLoading = false
            return
        }

        // Request client token using the new utility
        do {
            self.clientToken = try await NetworkingUtils.requestClientSession(
                body: configuredClientSession,
                apiVersion: apiVersion
            )
            self.isLoading = false
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }
}

// MARK: - Loading View

@available(iOS 15.0, *)
private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Creating session...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Error View

@available(iOS 15.0, *)
private struct ErrorView: View {
    fileprivate let error: String
    fileprivate let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Session Creation Failed")
                .font(.headline)

            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Checkout Content View

@available(iOS 15.0, *)
private struct CheckoutContentView: View {
    fileprivate let example: ExampleConfig
    fileprivate let clientToken: String
    fileprivate let settings: PrimerSettings
    fileprivate let onCompletion: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Example info header
            ExampleInfoHeader(example: example)

            // Simple, clean integration - PrimerCheckout handles everything automatically!
            VStack {
                Text("Pure SwiftUI PrimerCheckout")
                    .font(.headline)
                    .padding()

                Text("Client Token: \(clientToken.prefix(20))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)

                // This is all the merchant needs to do - PrimerCheckout handles SDK initialization automatically!
                PrimerCheckout(
                    clientToken: clientToken,
                    primerSettings: settings,
                    onCompletion: onCompletion
                )
            }
        }
    }

    // MARK: - Example Info Header

    @available(iOS 15.0, *)
    private struct ExampleInfoHeader: View {
        fileprivate let example: ExampleConfig
        @State private var isExpanded = false

        var body: some View {
            VStack(spacing: 0) {
                Button(action: { isExpanded.toggle() }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(example.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("Payment Methods: \(example.paymentMethods.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                }
                .buttonStyle(.plain)
            }
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(.separator)),
                alignment: .bottom
            )
        }
    }
}
