//
//  CheckoutExampleView.swift
//  Debug App
//
//  Created by Claude on 27.6.25.
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//

import SwiftUI
import PrimerSDK

@available(iOS 15.0, *)
struct CheckoutExampleView: View {
    let example: ExampleConfig
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    let configuredClientSession: ClientSessionRequestBody?
    
    @SwiftUI.Environment(\.dismiss) private var dismiss
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
            } else if let error = error {
                ErrorView(error: error) {
                    Task {
                        await createSession()
                    }
                }
            } else if let clientToken = clientToken {
                CheckoutContentView(
                    example: example,
                    clientToken: clientToken,
                    settings: settings,
                    apiVersion: apiVersion,
                    configuredClientSession: configuredClientSession,
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
        
        do {
            // Always use the configured client session from MerchantSessionAndSettingsViewController
            // This preserves the exact configuration from the main UI including currency, billing address, surcharge, etc.
            guard let session = configuredClientSession else {
                self.error = "No session configuration provided - please configure session in main settings"
                self.isLoading = false
                return
            }
            
            // Request client token using the session configuration
            await withCheckedContinuation { continuation in
                Networking.requestClientSession(requestBody: session, apiVersion: apiVersion) { clientToken, error in
                    Task { @MainActor in
                        if let error = error {
                            self.error = error.localizedDescription
                            self.isLoading = false
                        } else if let clientToken = clientToken {
                            self.clientToken = clientToken
                            self.isLoading = false
                        } else {
                            self.error = "Unknown error occurred"
                            self.isLoading = false
                        }
                        continuation.resume()
                    }
                }
            }
        }
    }
}

// MARK: - Loading View

@available(iOS 15.0, *)
struct LoadingView: View {
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
struct ErrorView: View {
    let error: String
    let onRetry: () -> Void
    
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
struct CheckoutContentView: View {
    let example: ExampleConfig
    let clientToken: String
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    let configuredClientSession: ClientSessionRequestBody?
    let onCompletion: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Example info header
            ExampleInfoHeader(example: example)
            
            // Choose integration approach based on example type
            if isDefaultExample {
                // Direct SwiftUI integration - now completely automatic!
                directSwiftUIContent
            } else {
                // Customized examples - show the actual CheckoutComponents with customization
                customizedSwiftUIContent
            }
        }
    }
    
    private var isDefaultExample: Bool {
        example.customization == nil
    }
    
    @ViewBuilder
    private var directSwiftUIContent: some View {
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
                settings: settings,
                onCompletion: onCompletion
            )
        }
    }
    
    @ViewBuilder
    private var customizedSwiftUIContent: some View {
        // Route to the actual showcase demo files for customized examples
        switch example.name {
        case "Colorful Theme":
            ColorfulThemedCardFormDemo(settings: settings, apiVersion: apiVersion, clientSession: configuredClientSession)
        default:
            // Fallback to default implementation
            VStack {
                Text("\(example.name) Demo")
                    .font(.headline)
                    .padding()
                
                Text("Custom demo implementation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                PrimerCheckout(
                    clientToken: clientToken,
                    settings: settings,
                    onCompletion: onCompletion
                )
            }
        }
    }
    
    // MARK: - Example Info Header
    
    @available(iOS 15.0, *)
    struct ExampleInfoHeader: View {
        let example: ExampleConfig
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
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        if let customization = example.customization {
                            HStack {
                                Text("Style Configuration:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(String(describing: customization))
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Spacer()
                            }
                        }
                        
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    .background(Color(.systemGroupedBackground))
                }
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
