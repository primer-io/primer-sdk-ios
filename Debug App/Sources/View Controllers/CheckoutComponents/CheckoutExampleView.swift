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
        case "Compact Form":
            CompactCardFormDemo(settings: settings, apiVersion: .V2_4, clientSession: nil)
        case "Expanded Form":
            ExpandedCardFormDemo(settings: settings, apiVersion: .V2_4, clientSession: nil)
        case "Grid Layout":
            GridCardFormDemo(settings: settings, apiVersion: .V2_4, clientSession: nil)
        case "Inline Form":
            InlineCardFormDemo(settings: settings, apiVersion: .V2_4, clientSession: nil)
        case "Modern Theme":
            ModernThemedCardFormDemo(settings: settings, apiVersion: .V2_4, clientSession: nil)
        case "Colorful Theme":
            ColorfulThemedCardFormDemo(settings: settings, apiVersion: .V2_4, clientSession: nil)
        case "Corporate Theme":
            CorporateThemedCardFormDemo(settings: settings, apiVersion: .V2_4, clientSession: nil)
        case "Dark Theme":
            DarkThemedCardFormDemo(settings: settings, apiVersion: .V2_4, clientSession: nil)
        case "Live State Monitor":
            LiveStateCardFormDemo(settings: settings, apiVersion: .V2_4, clientSession: nil)
        case "Validation Showcase":
            ValidationCardFormDemo(settings: settings, apiVersion: .V2_4, clientSession: nil)
        case "Co-badged Cards":
            CoBadgedCardFormDemo(settings: settings, apiVersion: .V2_4, clientSession: nil)
        case "Modifier Chains":
            ModifierChainsCardFormDemo(settings: settings, apiVersion: .V2_4, clientSession: nil)
        case "Custom Screen":
            CustomScreenCardFormDemo(settings: settings, apiVersion: .V2_4, clientSession: nil)
        case "Animated Form":
            AnimatedCardFormDemo(settings: settings, apiVersion: .V2_4, clientSession: nil)
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
    
    @ViewBuilder
    private func createCustomizedCardForm(for cardScope: any PrimerCardFormScope) -> some View {
        switch example.customization {
        case .corporate:
            createCorporateTheme(cardScope: cardScope)
        case .modern:
            createModernTheme(cardScope: cardScope)
        case .colorful:
            createColorfulTheme(cardScope: cardScope)
        case .dark:
            createDarkTheme(cardScope: cardScope)
        case .compact:
            createCompactLayout(cardScope: cardScope)
        case .expanded:
            createExpandedLayout(cardScope: cardScope)
        case .inline:
            createInlineLayout(cardScope: cardScope)
        case .grid:
            createGridLayout(cardScope: cardScope)
        case .validation:
            createValidationTheme(cardScope: cardScope)
        case .liveState:
            createLiveStateTheme(cardScope: cardScope)
        case .coBadged:
            createCoBadgedTheme(cardScope: cardScope)
        case .modifierChains:
            createModifierChainsTheme(cardScope: cardScope)
        case .customScreen:
            createCustomScreenTheme(cardScope: cardScope)
        case .animated:
            createAnimatedTheme(cardScope: cardScope)
        case .none:
            createDefaultForm(cardScope: cardScope)
        }
    }
    
    @ViewBuilder
    private func createCorporateTheme(cardScope: any PrimerCardFormScope) -> some View {
        VStack(spacing: 16) {
            // Corporate header
            VStack(alignment: .leading, spacing: 8) {
                Text("Payment Details")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.7))
                
                Text("Enter your corporate card information")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                if let cardNumberInput = cardScope.cardNumberInput {
                    cardNumberInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(50)
                        .padding(.horizontal, 16)
                        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                        .cornerRadius(8)
                        .border(Color(red: 0.2, green: 0.4, blue: 0.7), width: 1)
                    )
                }
                
                HStack(spacing: 12) {
                    if let expiryDateInput = cardScope.expiryDateInput {
                        expiryDateInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(50)
                            .padding(.horizontal, 16)
                            .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                            .cornerRadius(8)
                            .border(Color(red: 0.2, green: 0.4, blue: 0.7), width: 1)
                        )
                    }
                    
                    if let cvvInput = cardScope.cvvInput {
                        cvvInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(50)
                            .padding(.horizontal, 16)
                            .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                            .cornerRadius(8)
                            .border(Color(red: 0.2, green: 0.4, blue: 0.7), width: 1)
                        )
                    }
                }
                
                if let cardholderNameInput = cardScope.cardholderNameInput {
                    cardholderNameInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(50)
                        .padding(.horizontal, 16)
                        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                        .cornerRadius(8)
                        .border(Color(red: 0.2, green: 0.4, blue: 0.7), width: 1)
                    )
                }
            }
        }
        .padding(20)
        .background(Color(red: 0.95, green: 0.96, blue: 0.98))
    }
    
    @ViewBuilder
    private func createModernTheme(cardScope: any PrimerCardFormScope) -> some View {
        VStack(spacing: 20) {
            Text("Modern Payment Form")
                .font(.title2)
                .fontWeight(.medium)
            
            VStack(spacing: 16) {
                if let cardNumberInput = cardScope.cardNumberInput {
                    cardNumberInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(56)
                        .padding(.horizontal, 20)
                        .background(.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                    )
                }
                
                HStack(spacing: 16) {
                    if let expiryDateInput = cardScope.expiryDateInput {
                        expiryDateInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(56)
                            .padding(.horizontal, 20)
                            .background(.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                        )
                    }
                    
                    if let cvvInput = cardScope.cvvInput {
                        cvvInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(56)
                            .padding(.horizontal, 20)
                            .background(.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                        )
                    }
                }
                
                if let cardholderNameInput = cardScope.cardholderNameInput {
                    cardholderNameInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(56)
                        .padding(.horizontal, 20)
                        .background(.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                    )
                }
            }
        }
        .padding(24)
        .background(.gray.opacity(0.05))
    }
    
    @ViewBuilder
    private func createColorfulTheme(cardScope: any PrimerCardFormScope) -> some View {
        VStack(spacing: 20) {
            LinearGradient(
                colors: [.pink, .purple, .blue],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)
            .cornerRadius(2)
            
            Text("Colorful Payment Experience")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            VStack(spacing: 16) {
                if let cardNumberInput = cardScope.cardNumberInput {
                    cardNumberInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(50)
                        .padding(.horizontal, 16)
                        .background(.pink.opacity(0.1))
                        .cornerRadius(10)
                        .border(.pink.opacity(0.5), width: 1)
                    )
                }
                
                HStack(spacing: 12) {
                    if let expiryDateInput = cardScope.expiryDateInput {
                        expiryDateInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(50)
                            .padding(.horizontal, 16)
                            .background(.purple.opacity(0.1))
                            .cornerRadius(10)
                            .border(.purple.opacity(0.5), width: 1)
                        )
                    }
                    
                    if let cvvInput = cardScope.cvvInput {
                        cvvInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(50)
                            .padding(.horizontal, 16)
                            .background(.blue.opacity(0.1))
                            .cornerRadius(10)
                            .border(.blue.opacity(0.5), width: 1)
                        )
                    }
                }
                
                if let cardholderNameInput = cardScope.cardholderNameInput {
                    cardholderNameInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(50)
                        .padding(.horizontal, 16)
                        .background(.green.opacity(0.1))
                        .cornerRadius(10)
                        .border(.green.opacity(0.5), width: 1)
                    )
                }
            }
        }
        .padding(20)
    }
    
    @ViewBuilder
    private func createDarkTheme(cardScope: any PrimerCardFormScope) -> some View {
        VStack(spacing: 16) {
            Text("Dark Mode Payment")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                if let cardNumberInput = cardScope.cardNumberInput {
                    cardNumberInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(50)
                        .padding(.horizontal, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .border(.gray, width: 1)
                    )
                }
                
                HStack(spacing: 12) {
                    if let expiryDateInput = cardScope.expiryDateInput {
                        expiryDateInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(50)
                            .padding(.horizontal, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .border(.gray, width: 1)
                        )
                    }
                    
                    if let cvvInput = cardScope.cvvInput {
                        cvvInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(50)
                            .padding(.horizontal, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .border(.gray, width: 1)
                        )
                    }
                }
                
                if let cardholderNameInput = cardScope.cardholderNameInput {
                    cardholderNameInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(50)
                        .padding(.horizontal, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .border(.gray, width: 1)
                    )
                }
            }
        }
        .padding(20)
        .background(.black)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func createDefaultForm(cardScope: any PrimerCardFormScope) -> some View {
        VStack(spacing: 16) {
            if let cardNumberInput = cardScope.cardNumberInput {
                cardNumberInput(PrimerModifier())
            }
            
            HStack(spacing: 12) {
                if let expiryDateInput = cardScope.expiryDateInput {
                    expiryDateInput(PrimerModifier())
                }
                
                if let cvvInput = cardScope.cvvInput {
                    cvvInput(PrimerModifier())
                }
            }
            
            if let cardholderNameInput = cardScope.cardholderNameInput {
                cardholderNameInput(PrimerModifier())
            }
        }
        .padding()
    }
    
    // Simplified implementations for other themes
    @ViewBuilder
    private func createCompactLayout(cardScope: any PrimerCardFormScope) -> some View {
        VStack(spacing: 12) {
            // Compact header
            Text("Compact Form")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Compact layout - horizontal fields with tight spacing
            VStack(spacing: 8) {
                // Card number (full width but smaller)
                if let cardNumberInput = cardScope.cardNumberInput {
                    cardNumberInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(40)
                        .padding(.horizontal, 12)
                        .background(.white)
                        .cornerRadius(6)
                        .border(.gray.opacity(0.3), width: 1)
                    )
                }
                
                // Expiry and CVV in compact row
                HStack(spacing: 8) {
                    if let expiryDateInput = cardScope.expiryDateInput {
                        expiryDateInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(40)
                            .padding(.horizontal, 12)
                            .background(.white)
                            .cornerRadius(6)
                            .border(.gray.opacity(0.3), width: 1)
                        )
                    }
                    
                    if let cvvInput = cardScope.cvvInput {
                        cvvInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(40)
                            .padding(.horizontal, 12)
                            .background(.white)
                            .cornerRadius(6)
                            .border(.gray.opacity(0.3), width: 1)
                        )
                    }
                }
                
                // Cardholder name
                if let cardholderNameInput = cardScope.cardholderNameInput {
                    cardholderNameInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(40)
                        .padding(.horizontal, 12)
                        .background(.white)
                        .cornerRadius(6)
                        .border(.gray.opacity(0.3), width: 1)
                    )
                }
            }
        }
        .padding(16)
        .background(.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func createExpandedLayout(cardScope: any PrimerCardFormScope) -> some View {
        VStack(spacing: 28) {
            // Expanded header
            VStack(spacing: 8) {
                Text("Expanded Payment Form")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Generous spacing for comfortable input")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Expanded layout - vertical fields with generous spacing
            VStack(spacing: 24) {
                // Card number with label
                VStack(alignment: .leading, spacing: 8) {
                    Text("Card Number")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if let cardNumberInput = cardScope.cardNumberInput {
                        cardNumberInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(60)
                            .padding(.horizontal, 20)
                            .background(.white)
                            .cornerRadius(12)
                            .border(.blue.opacity(0.2), width: 1)
                        )
                    }
                }
                
                // Expiry Date with label
                VStack(alignment: .leading, spacing: 8) {
                    Text("Expiry Date")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if let expiryDateInput = cardScope.expiryDateInput {
                        expiryDateInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(60)
                            .padding(.horizontal, 20)
                            .background(.white)
                            .cornerRadius(12)
                            .border(.blue.opacity(0.2), width: 1)
                        )
                    }
                }
                
                // CVV with label
                VStack(alignment: .leading, spacing: 8) {
                    Text("Security Code")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if let cvvInput = cardScope.cvvInput {
                        cvvInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(60)
                            .padding(.horizontal, 20)
                            .background(.white)
                            .cornerRadius(12)
                            .border(.blue.opacity(0.2), width: 1)
                        )
                    }
                }
                
                // Cardholder Name with label
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cardholder Name")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if let cardholderNameInput = cardScope.cardholderNameInput {
                        cardholderNameInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(60)
                            .padding(.horizontal, 20)
                            .background(.white)
                            .cornerRadius(12)
                            .border(.blue.opacity(0.2), width: 1)
                        )
                    }
                }
            }
        }
        .padding(24)
        .background(.blue.opacity(0.02))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func createInlineLayout(cardScope: any PrimerCardFormScope) -> some View {
        VStack(spacing: 14) {
            // Inline header - minimal
            Text("Payment Information")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            // Inline layout - seamless integration
            VStack(spacing: 12) {
                // Card number - minimal styling
                if let cardNumberInput = cardScope.cardNumberInput {
                    cardNumberInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(44)
                        .padding(.horizontal, 14)
                        .background(.clear)
                        .cornerRadius(8)
                        .border(.gray.opacity(0.2), width: 0.5)
                    )
                }
                
                // Expiry and CVV row - inline style
                HStack(spacing: 12) {
                    if let expiryDateInput = cardScope.expiryDateInput {
                        expiryDateInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(44)
                            .padding(.horizontal, 14)
                            .background(.clear)
                            .cornerRadius(8)
                            .border(.gray.opacity(0.2), width: 0.5)
                        )
                    }
                    
                    if let cvvInput = cardScope.cvvInput {
                        cvvInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(44)
                            .padding(.horizontal, 14)
                            .background(.clear)
                            .cornerRadius(8)
                            .border(.gray.opacity(0.2), width: 0.5)
                        )
                    }
                }
                
                // Cardholder name - inline style
                if let cardholderNameInput = cardScope.cardholderNameInput {
                    cardholderNameInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(44)
                        .padding(.horizontal, 14)
                        .background(.clear)
                        .cornerRadius(8)
                        .border(.gray.opacity(0.2), width: 0.5)
                    )
                }
            }
        }
        .padding(12)
    }
    
    @ViewBuilder
    private func createGridLayout(cardScope: any PrimerCardFormScope) -> some View {
        VStack(spacing: 16) {
            // Grid header
            Text("Grid Payment Layout")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.purple)
            
            // Grid layout for card form
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Card number spans full width
                if let cardNumberInput = cardScope.cardNumberInput {
                    cardNumberInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(48)
                        .padding(.horizontal, 12)
                        .background(.white)
                        .cornerRadius(10)
                        .border(.purple.opacity(0.3), width: 2)
                    )
                }
                
                // Expiry Date
                if let expiryDateInput = cardScope.expiryDateInput {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Expiry")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                        
                        expiryDateInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(48)
                            .padding(.horizontal, 12)
                            .background(.white)
                            .cornerRadius(10)
                            .border(.purple.opacity(0.3), width: 2)
                        )
                    }
                }
                
                // CVV
                if let cvvInput = cardScope.cvvInput {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CVV")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                        
                        cvvInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(48)
                            .padding(.horizontal, 12)
                            .background(.white)
                            .cornerRadius(10)
                            .border(.purple.opacity(0.3), width: 2)
                        )
                    }
                }
                
                // Cardholder name spans full width
                if let cardholderNameInput = cardScope.cardholderNameInput {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cardholder Name")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                        
                        cardholderNameInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(48)
                            .padding(.horizontal, 12)
                            .background(.white)
                            .cornerRadius(10)
                            .border(.purple.opacity(0.3), width: 2)
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(.purple.opacity(0.05))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func createValidationTheme(cardScope: any PrimerCardFormScope) -> some View {
        VStack(spacing: 20) {
            // Validation showcase header
            VStack(spacing: 8) {
                HStack {
                    Text("Validation Showcase")
                        .font(.title2.weight(.semibold))
                    Spacer()
                    Image(systemName: "checkmark.shield")
                        .foregroundColor(.green)
                        .font(.title3)
                }
                Text("Try entering invalid data to see error states")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Validation info banner
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Validation Examples")
                        .font(.caption.weight(.semibold))
                    Text("Try: 1234 (invalid), 4242424242424242 (valid)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(.blue.opacity(0.1))
            .cornerRadius(8)
            
            // Form with validation emphasis
            VStack(spacing: 16) {
                // Card number with validation styling
                if let cardNumberInput = cardScope.cardNumberInput {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Card Number")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("Required")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        cardNumberInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(50)
                            .padding(.horizontal, 16)
                            .background(.white)
                            .cornerRadius(8)
                            .border(.red.opacity(0.3), width: 2)
                        )
                        Text("16-digit card number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Expiry and CVV with validation states
                HStack(spacing: 16) {
                    if let expiryDateInput = cardScope.expiryDateInput {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Expiry")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text("MM/YY")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            expiryDateInput(PrimerModifier()
                                .fillMaxWidth()
                                .height(50)
                                .padding(.horizontal, 16)
                                .background(.white)
                                .cornerRadius(8)
                                .border(.orange.opacity(0.3), width: 2)
                            )
                            Text("Must be future date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let cvvInput = cardScope.cvvInput {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("CVV")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text("3-4 digits")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                            cvvInput(PrimerModifier()
                                .fillMaxWidth()
                                .height(50)
                                .padding(.horizontal, 16)
                                .background(.white)
                                .cornerRadius(8)
                                .border(.purple.opacity(0.3), width: 2)
                            )
                            Text("Security code")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Cardholder name with validation
                if let cardholderNameInput = cardScope.cardholderNameInput {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Cardholder Name")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("Full name")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        cardholderNameInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(50)
                            .padding(.horizontal, 16)
                            .background(.white)
                            .cornerRadius(8)
                            .border(.green.opacity(0.3), width: 2)
                        )
                        Text("As shown on your card")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Validation rules footer
            VStack(alignment: .leading, spacing: 4) {
                Text("Validation Rules:")
                    .font(.caption.weight(.semibold))
                Text("• Card numbers must pass Luhn algorithm")
                Text("• Expiry dates must be in the future")
                Text("• CVV must be 3-4 digits depending on card type")
                Text("• All fields are required for completion")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(.gray.opacity(0.02))
    }
    
    @ViewBuilder
    private func createLiveStateTheme(cardScope: any PrimerCardFormScope) -> some View {
        VStack(spacing: 16) {
            // Live state header
            VStack(spacing: 8) {
                Text("Live State Demo")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.blue)
                
                Text("Real-time state updates and debugging")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // State indicator banner
            HStack {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                Text("Live State Monitoring Active")
                    .font(.caption.weight(.medium))
                Spacer()
                Text("Ready")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .padding(10)
            .background(.green.opacity(0.1))
            .cornerRadius(8)
            
            // Form with live state styling
            VStack(spacing: 14) {
                if let cardNumberInput = cardScope.cardNumberInput {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Card Number")
                                .font(.caption.weight(.medium))
                            Spacer()
                            Text("Live Validation")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        cardNumberInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(48)
                            .padding(.horizontal, 14)
                            .background(.white)
                            .cornerRadius(8)
                            .border(.blue.opacity(0.4), width: 1.5)
                        )
                    }
                }
                
                HStack(spacing: 12) {
                    if let expiryDateInput = cardScope.expiryDateInput {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Expiry")
                                .font(.caption.weight(.medium))
                            expiryDateInput(PrimerModifier()
                                .fillMaxWidth()
                                .height(48)
                                .padding(.horizontal, 14)
                                .background(.white)
                                .cornerRadius(8)
                                .border(.blue.opacity(0.4), width: 1.5)
                            )
                        }
                    }
                    
                    if let cvvInput = cardScope.cvvInput {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CVV")
                                .font(.caption.weight(.medium))
                            cvvInput(PrimerModifier()
                                .fillMaxWidth()
                                .height(48)
                                .padding(.horizontal, 14)
                                .background(.white)
                                .cornerRadius(8)
                                .border(.blue.opacity(0.4), width: 1.5)
                            )
                        }
                    }
                }
                
                if let cardholderNameInput = cardScope.cardholderNameInput {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Cardholder Name")
                                .font(.caption.weight(.medium))
                            Spacer()
                            Text("Optional")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        cardholderNameInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(48)
                            .padding(.horizontal, 14)
                            .background(.white)
                            .cornerRadius(8)
                            .border(.blue.opacity(0.4), width: 1.5)
                        )
                    }
                }
            }
        }
        .padding(18)
        .background(.blue.opacity(0.03))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func createCoBadgedTheme(cardScope: any PrimerCardFormScope) -> some View {
        VStack(spacing: 16) {
            // Co-badged header
            VStack(spacing: 8) {
                Text("Co-badged Cards Demo")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.orange)
                
                Text("Multiple network selection support")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Network info banner
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Network Detection")
                        .font(.caption.weight(.semibold))
                    Text("Card networks detected automatically")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(.orange.opacity(0.1))
            .cornerRadius(8)
            
            // Form with co-badged emphasis
            VStack(spacing: 14) {
                if let cardNumberInput = cardScope.cardNumberInput {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Card Number")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("Auto-detect")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        cardNumberInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(52)
                            .padding(.horizontal, 16)
                            .background(.white)
                            .cornerRadius(10)
                            .border(.orange.opacity(0.4), width: 2)
                        )
                        Text("Enter card number to see network detection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 12) {
                    if let expiryDateInput = cardScope.expiryDateInput {
                        expiryDateInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(52)
                            .padding(.horizontal, 16)
                            .background(.white)
                            .cornerRadius(10)
                            .border(.orange.opacity(0.4), width: 2)
                        )
                    }
                    
                    if let cvvInput = cardScope.cvvInput {
                        cvvInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(52)
                            .padding(.horizontal, 16)
                            .background(.white)
                            .cornerRadius(10)
                            .border(.orange.opacity(0.4), width: 2)
                        )
                    }
                }
                
                if let cardholderNameInput = cardScope.cardholderNameInput {
                    cardholderNameInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(52)
                        .padding(.horizontal, 16)
                        .background(.white)
                        .cornerRadius(10)
                        .border(.orange.opacity(0.4), width: 2)
                    )
                }
            }
        }
        .padding(18)
        .background(.orange.opacity(0.03))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func createModifierChainsTheme(cardScope: any PrimerCardFormScope) -> some View {
        VStack(spacing: 18) {
            // Modifier chains header
            Text("PrimerModifier Chains")
                .font(.title2.weight(.bold))
                .foregroundColor(.purple)
            
            Text("Complex styling combinations")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Complex styled form
            VStack(spacing: 16) {
                // Card number with complex modifier chain
                if let cardNumberInput = cardScope.cardNumberInput {
                    cardNumberInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(56)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(.white)
                        .cornerRadius(16)
                        .border(.purple, width: 2)
                        .shadow(color: .purple.opacity(0.2), radius: 4, y: 2)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                    )
                }
                
                // Expiry and CVV with different chain styles
                HStack(spacing: 16) {
                    if let expiryDateInput = cardScope.expiryDateInput {
                        expiryDateInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(56)
                            .padding(.horizontal, 18)
                            .background(.purple.opacity(0.1))
                            .cornerRadius(14)
                            .border(.blue, width: 1.5)
                            .shadow(color: .blue.opacity(0.15), radius: 3, y: 1)
                        )
                    }
                    
                    if let cvvInput = cardScope.cvvInput {
                        cvvInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(56)
                            .padding(.horizontal, 18)
                            .background(.pink.opacity(0.1))
                            .cornerRadius(14)
                            .border(.pink, width: 1.5)
                            .shadow(color: .pink.opacity(0.15), radius: 3, y: 1)
                        )
                    }
                }
                
                // Cardholder name with ultimate modifier chain
                if let cardholderNameInput = cardScope.cardholderNameInput {
                    cardholderNameInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(56)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(.white)
                        .cornerRadius(16)
                        .border(.purple, width: 2)
                        .shadow(color: .purple.opacity(0.2), radius: 6, y: 3)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                    )
                }
            }
        }
        .padding(22)
        .background(.purple.opacity(0.02))
        .cornerRadius(20)
    }
    
    @ViewBuilder
    private func createCustomScreenTheme(cardScope: any PrimerCardFormScope) -> some View {
        VStack(spacing: 20) {
            // Custom screen header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Custom Layout")
                        .font(.title.weight(.bold))
                        .foregroundColor(.indigo)
                    Text("Non-standard form arrangement")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "square.grid.3x3")
                    .font(.title2)
                    .foregroundColor(.indigo)
            }
            
            // Custom arranged form
            VStack(spacing: 18) {
                // Top row: Card number centered
                HStack {
                    Spacer()
                    VStack {
                        Text("CARD NUMBER")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.indigo)
                            .tracking(1)
                        
                        if let cardNumberInput = cardScope.cardNumberInput {
                            cardNumberInput(PrimerModifier()
                                .width(280)
                                .height(50)
                                .padding(.horizontal, 16)
                                .background(.indigo.opacity(0.1))
                                .cornerRadius(25)
                                .border(.indigo.opacity(0.3), width: 1)
                            )
                        }
                    }
                    Spacer()
                }
                
                // Middle section: Split layout
                HStack(spacing: 24) {
                    // Left column
                    VStack(spacing: 12) {
                        Text("EXPIRY")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.indigo)
                            .tracking(1)
                        
                        if let expiryDateInput = cardScope.expiryDateInput {
                            expiryDateInput(PrimerModifier()
                                .fillMaxWidth()
                                .height(45)
                                .padding(.horizontal, 14)
                                .background(.white)
                                .cornerRadius(12)
                                .border(.indigo.opacity(0.2), width: 1)
                            )
                        }
                    }
                    
                    // Right column
                    VStack(spacing: 12) {
                        Text("SECURITY")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.indigo)
                            .tracking(1)
                        
                        if let cvvInput = cardScope.cvvInput {
                            cvvInput(PrimerModifier()
                                .fillMaxWidth()
                                .height(45)
                                .padding(.horizontal, 14)
                                .background(.white)
                                .cornerRadius(12)
                                .border(.indigo.opacity(0.2), width: 1)
                            )
                        }
                    }
                }
                
                // Bottom: Cardholder name full width
                VStack(spacing: 8) {
                    Text("CARDHOLDER NAME")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.indigo)
                        .tracking(1)
                    
                    if let cardholderNameInput = cardScope.cardholderNameInput {
                        cardholderNameInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(50)
                            .padding(.horizontal, 16)
                            .background(.white)
                            .cornerRadius(25)
                            .border(.indigo.opacity(0.3), width: 1)
                        )
                    }
                }
            }
        }
        .padding(24)
        .background(.indigo.opacity(0.05))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func createAnimatedTheme(cardScope: any PrimerCardFormScope) -> some View {
        VStack(spacing: 20) {
            // Animated header
            HStack {
                Text("Animated Form")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.teal)
                
                Spacer()
                
                // Animated indicator
                Circle()
                    .fill(.teal)
                    .frame(width: 12, height: 12)
                    .scaleEffect(1.2)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: true)
            }
            
            Text("Interactive animations and smooth transitions")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Animated form fields
            VStack(spacing: 16) {
                // Card number with animated border
                if let cardNumberInput = cardScope.cardNumberInput {
                    cardNumberInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(52)
                        .padding(.horizontal, 18)
                        .background(.white)
                        .cornerRadius(12)
                        .border(.teal.opacity(0.6), width: 2)
                        .shadow(color: .teal.opacity(0.2), radius: 4, y: 2)
                    )
                    .animation(.spring(duration: 0.3), value: true)
                }
                
                // Expiry and CVV with staggered animation
                HStack(spacing: 16) {
                    if let expiryDateInput = cardScope.expiryDateInput {
                        expiryDateInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(52)
                            .padding(.horizontal, 18)
                            .background(.teal.opacity(0.05))
                            .cornerRadius(12)
                            .border(.teal.opacity(0.4), width: 1.5)
                        )
                        .animation(.spring(duration: 0.3).delay(0.1), value: true)
                    }
                    
                    if let cvvInput = cardScope.cvvInput {
                        cvvInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(52)
                            .padding(.horizontal, 18)
                            .background(.teal.opacity(0.05))
                            .cornerRadius(12)
                            .border(.teal.opacity(0.4), width: 1.5)
                        )
                        .animation(.spring(duration: 0.3).delay(0.2), value: true)
                    }
                }
                
                // Cardholder name with slide-in animation
                if let cardholderNameInput = cardScope.cardholderNameInput {
                    cardholderNameInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(52)
                        .padding(.horizontal, 18)
                        .background(.teal.opacity(0.1))
                        .cornerRadius(12)
                        .border(.teal.opacity(0.4), width: 1.5)
                    )
                    .animation(.spring(duration: 0.4).delay(0.3), value: true)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.teal.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.teal.opacity(0.1), lineWidth: 1)
                )
        )
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

