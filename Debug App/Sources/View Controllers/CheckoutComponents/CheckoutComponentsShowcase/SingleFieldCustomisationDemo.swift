//
//  SingleFieldCustomisationDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Single field customisation demo
/// 
/// This demo demonstrates how to override ONLY the cardholder name field
/// while keeping all other fields with their default appearance and functionality.
/// This is the simplest form of partial customization - changing just one element.
@available(iOS 15.0, *)
struct SingleFieldCustomisationDemo: View {
    private let settings: PrimerSettings
    private let apiVersion: PrimerApiVersion
    private let clientSession: ClientSessionRequestBody?
    
    @State private var clientToken: String?
    @State private var isLoading = true
    @State private var error: String?
    @State private var isDismissed = false
    
    init(settings: PrimerSettings, apiVersion: PrimerApiVersion, clientSession: ClientSessionRequestBody?) {
        self.settings = settings
        self.apiVersion = apiVersion
        self.clientSession = clientSession
    }
    
    var body: some View {
        VStack {
            if isDismissed {
                dismissedStateView
            } else if isLoading {
                loadingStateView
            } else if let error {
                errorStateView(error)
            } else if let clientToken {
                checkoutView(clientToken: clientToken)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .task {
            await createSession()
        }
    }
    
    // MARK: - State Views
    
    private var dismissedStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("Demo Completed")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Single field customisation demo has been dismissed")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Reset Demo") {
                isDismissed = false
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(height: 300)
        .padding()
    }
    
    private var loadingStateView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Creating session...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
    }
    
    private func errorStateView(_ errorMessage: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(.orange)
            Text("Session Failed")
                .font(.headline)
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await createSession() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(height: 200)
    }
    
    private func checkoutView(clientToken: String) -> some View {
        VStack {
            Text("Single Field Customisation")
                .font(.headline)
                .padding()
            
            Text("Only cardholder name field is customized - all other fields use default UI")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom)

            PrimerCheckout(
                clientToken: clientToken,
                settings: settings,
                scope: customizeScope,
                onCompletion: {
                    isDismissed = true
                }
            )
        }
    }

    // MARK: - Scope Customization with Single Field Override
    private func customizeScope(_ checkoutScope: PrimerCheckoutScope) {
        // Get the card form scope
        if let cardScope: DefaultCardFormScope = checkoutScope.getPaymentMethodScope(for: .paymentCard) {
            // IMPORTANT: We're ONLY customizing the cardholder name field
            // All other fields (card number, expiry, CVV, billing address) will use default UI
            
            // Override ONLY the cardholder name field styling using defaultFieldStyling
            // This avoids infinite recursion and properly demonstrates partial customization
            cardScope.defaultFieldStyling = [
                "cardholderName": PrimerFieldStyling(
                    font: .title3,
                    labelFont: .headline,
                    textColor: .purple,
                    labelColor: .purple,
                    backgroundColor: Color.purple.opacity(0.05),
                    borderColor: .purple,
                    focusedBorderColor: .pink,
                    cornerRadius: 12,
                    borderWidth: 2
                )
            ]
            
            // Also ensure we have a custom label for the cardholder name field to make it more visible
            cardScope.cardholderNameField = { label, styling in
                AnyView(
                    cardScope.PrimerCardholderNameField(
                        label: "🎨 Custom Cardholder Name",
                        styling: styling
                    )
                )
            }
            
            // That's it! We're NOT setting:
            // - cardScope.cardNumberField
            // - cardScope.expiryDateField  
            // - cardScope.cvvField
            // - cardScope.countryField
            // - cardScope.postalCodeField
            // - etc.
            // 
            // All these fields will appear with their default UI and functionality
            // The card form will work exactly as if everything was default,
            // except the cardholder name field will have our colorful custom appearance
        }
    }
    
    // MARK: - Session Creation
    
    /// Creates a session for this demo
    private func createSession() async {
        isLoading = true
        error = nil
        
        do {
            // Create session using the main controller's configuration
            let sessionBody = createSessionBody()
            
            // Request client token using the session configuration
            await withCheckedContinuation { continuation in
                Networking.requestClientSession(requestBody: sessionBody, apiVersion: apiVersion) { clientToken, error in
                    Task { @MainActor in
                        if let error {
                            self.error = error.localizedDescription
                            self.isLoading = false
                        } else if let clientToken {
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
    
    /// Creates session body using the main controller's configuration
    private func createSessionBody() -> ClientSessionRequestBody {
        // Use the configured session from MerchantSessionAndSettingsViewController
        guard let configuredSession = clientSession else {
            fatalError("No session configuration provided - SingleFieldCustomisationDemo requires configured session from main controller")
        }
        
        return configuredSession
    }
}
