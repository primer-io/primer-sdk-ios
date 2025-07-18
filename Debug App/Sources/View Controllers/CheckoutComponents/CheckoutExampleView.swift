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
        print("🔍 [CheckoutExampleView] Init called for example: \(example.name)")
        print("🔍 [CheckoutExampleView] Configured client session: \(clientSession != nil ? "provided" : "nil")")
        if let session = clientSession {
            print("🔍 [CheckoutExampleView] Surcharge configured: \(session.paymentMethod?.options?.PAYMENT_CARD?.networks != nil)")
        }
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
            // For default examples, use the configured client session directly if available
            // This preserves the exact surcharge configuration from the UI
            let session: ClientSessionRequestBody
            
            if example.customization == nil && configuredClientSession != nil {
                print("🔍 [CheckoutExampleView] Using configured client session directly for default example")
                session = configuredClientSession!
                
                // Debug the configured session surcharge
                if let configuredSurcharge = session.paymentMethod?.options?.PAYMENT_CARD?.networks?.VISA?.surcharge.amount {
                    print("🔍 [CheckoutExampleView] ✅ Configured session VISA surcharge: \(configuredSurcharge)")
                } else {
                    print("🔍 [CheckoutExampleView] ❌ Configured session has NO VISA surcharge")
                }
            } else {
                // For customized examples, create a new session with extracted surcharge amount
                let surchargeAmount = extractSurchargeAmount(from: configuredClientSession)
                print("🔍 [CheckoutExampleView] Creating new session with extracted surcharge amount: \(surchargeAmount)")
                
                session = example.createSession(surchargeAmount: surchargeAmount)
                
                // Debug: Verify the created session actually has the surcharge amount
                if let createdSurcharge = session.paymentMethod?.options?.PAYMENT_CARD?.networks?.VISA?.surcharge.amount {
                    print("🔍 [CheckoutExampleView] ✅ Created session VISA surcharge: \(createdSurcharge)")
                } else {
                    print("🔍 [CheckoutExampleView] ❌ Created session has NO VISA surcharge")
                }
            }
            
            print("🔍 [CheckoutExampleView] Requesting client token with session...")
            
            // Request client token using the session configuration
            await withCheckedContinuation { continuation in
                Networking.requestClientSession(requestBody: session, apiVersion: apiVersion) { clientToken, error in
                    Task { @MainActor in
                        if let error = error {
                            print("🔍 [CheckoutExampleView] ❌ Client token failed: \(error)")
                            self.error = error.localizedDescription
                            self.isLoading = false
                            print("🔍 [CheckoutExampleView] ❌ UI updated with error: \(error.localizedDescription)")
                        } else if let clientToken = clientToken {
                            print("🔍 [CheckoutExampleView] ✅ Client token received: \(clientToken.prefix(20))...")
                            self.clientToken = clientToken
                            self.isLoading = false
                            print("🔍 [CheckoutExampleView] ✅ UI updated - ready to show checkout")
                        } else {
                            print("🔍 [CheckoutExampleView] ❌ Unknown error occurred")
                            self.error = "Unknown error occurred"
                            self.isLoading = false
                        }
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    /// Extracts surcharge amount from the configured client session
    private func extractSurchargeAmount(from clientSession: ClientSessionRequestBody?) -> Int {
        guard let session = clientSession,
              let paymentCardOptions = session.paymentMethod?.options?.PAYMENT_CARD,
              let networks = paymentCardOptions.networks else {
            print("🔍 [CheckoutExampleView] No surcharge configuration found, using default: 50")
            return 50 // Default fallback
        }
        
        // Try to get surcharge amount from any of the configured networks
        if let visaSurcharge = networks.VISA?.surcharge.amount {
            print("🔍 [CheckoutExampleView] Found surcharge from VISA network: \(visaSurcharge)")
            return visaSurcharge
        }

        if let mastercardSurcharge = networks.MASTERCARD?.surcharge.amount {
            print("🔍 [CheckoutExampleView] Found surcharge from MASTERCARD network: \(mastercardSurcharge)")
            return mastercardSurcharge
        }
        
        if let jcbSurcharge = networks.JCB?.surcharge.amount {
            print("🔍 [CheckoutExampleView] Found surcharge from JCB network: \(jcbSurcharge)")
            return jcbSurcharge
        }
        
        print("🔍 [CheckoutExampleView] Networks configured but no surcharge found, using default: 50")
        return 50 // Default fallback
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
                // Customized examples - show the actual CheckoutComponents with customization
                customizedSwiftUIContent
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
    
    @ViewBuilder
    private var customizedSwiftUIContent: some View {
        // Route to the actual showcase demo files for customized examples
        switch example.name {
        case "Colorful Theme":
            ColorfulThemedCardFormDemo(settings: settings, apiVersion: .V2_4, clientSession: nil)
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
            case .cardOnlyWithSurcharge:
                return "Card Only + Surcharge"
            case .cardAndApplePayWithSurcharge:
                return "Card + Apple Pay + Surcharge"
            case .fullMethods:
                return "All Payment Methods"
            case .custom:
                return "Custom Configuration"
            }
        }
    }
}

