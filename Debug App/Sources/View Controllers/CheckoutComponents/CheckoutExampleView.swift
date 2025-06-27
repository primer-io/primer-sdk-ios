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
            let session = example.createSession()
            
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
                await MainActor.run {
                    self.clientToken = token
                    self.isLoading = false
                }
            case .failure(let error):
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
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
            
            // Pure SwiftUI PrimerCheckout integration
            PrimerCheckout(
                clientToken: clientToken,
                settings: settings
                // Use default DI container and navigator as specified in the plan
            )
            .onReceive(checkoutCompletedPublisher) { _ in
                onCompletion()
            }
        }
    }
    
    // Placeholder for checkout completion publisher
    // This would need to be implemented based on actual PrimerCheckout API
    private var checkoutCompletedPublisher: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: .init("CheckoutCompleted"))
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
