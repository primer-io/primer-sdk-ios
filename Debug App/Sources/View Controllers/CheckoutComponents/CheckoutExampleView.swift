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
    
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var clientToken: String?
    @State private var isLoading = true
    @State private var error: String?
    @State private var checkoutCompleted = false
    
    init(example: ExampleConfig, settings: PrimerSettings, apiVersion: PrimerApiVersion) {
        self.example = example
        self.settings = settings
        self.apiVersion = apiVersion
        print("🔍 [CheckoutExampleView] Init called for example: \(example.name)")
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
        let _ = print("🔍 [CheckoutExampleView] contentView - isLoading: \(isLoading), error: \(error ?? "none"), clientToken: \(clientToken?.prefix(10) ?? "none")")
        
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
        print("🔍 [CheckoutExampleView] createSession called for: \(example.name)")
        isLoading = true
        error = nil
        
        do {
            let session = example.createSession()
            print("🔍 [CheckoutExampleView] Session created, requesting client token...")
            
            // Request client token using the session configuration
            let result: AsyncResult<String, Error> = await withCheckedContinuation { continuation in
                Networking.requestClientSession(requestBody: session, apiVersion: apiVersion) { clientToken, error in
                    if let error = error {
                        continuation.resume(returning: AsyncResult.failure(error))
                    } else if let clientToken = clientToken {
                        continuation.resume(returning: AsyncResult.success(clientToken))
                    } else {
                        continuation.resume(returning: AsyncResult.failure(NSError(domain: "CheckoutExample", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
                    }
                }
            }
            
            switch result {
            case .success(let token):
                print("🔍 [CheckoutExampleView] Client token received: \(token.prefix(20))...")
                await MainActor.run {
                    self.clientToken = token
                    self.isLoading = false
                    print("🔍 [CheckoutExampleView] Updated UI - isLoading: false, clientToken set")
                }
            case .failure(let error):
                print("🔍 [CheckoutExampleView] Client token failed: \(error)")
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    print("🔍 [CheckoutExampleView] Updated UI - isLoading: false, error: \(error.localizedDescription)")
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
    let onCompletion: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Example info header
            ExampleInfoHeader(example: example)
            
            // Debug output
            let _ = print("🔍 [CheckoutContentView] Example: \(example.name), isDefaultExample: \(isDefaultExample)")
            
            // Choose integration approach based on example type
            if isDefaultExample {
                // Direct SwiftUI integration - now completely automatic!
                directSwiftUIContent
            } else {
                // Bridge integration for customized examples (placeholder for now)
                Text("Customized examples coming soon")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            print("🔍 [CheckoutContentView] onAppear called, isDefaultExample: \(isDefaultExample)")
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
            .onAppear {
                print("🎯 [CheckoutContentView] PrimerCheckout appeared - SDK initialization will happen automatically")
            }
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
                    
                    HStack {
                        Text("Session Type:")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text(sessionTypeDescription)
                            .font(.caption)
                            .foregroundColor(.purple)
                        Spacer()
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
    
    private var sessionTypeDescription: String {
        switch example.sessionType {
        case .cardOnly:
            return "Card Only"
        case .cardAndApplePay:
            return "Card + Apple Pay"
        case .fullMethods:
            return "All Payment Methods"
        case .custom:
            return "Custom Configuration"
        }
    }
}

// MARK: - Result Enum for Async Operations

enum AsyncResult<Success, Failure: Error> {
    case success(Success)
    case failure(Failure)
}
