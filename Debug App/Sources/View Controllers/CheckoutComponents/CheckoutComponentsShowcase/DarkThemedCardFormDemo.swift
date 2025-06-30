//
//  DarkThemedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Dark theme demo with full dark mode implementation
@available(iOS 15.0, *)
struct DarkThemedCardFormDemo: View {
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    let clientSession: ClientSessionRequestBody?
    
    @State private var clientToken: String?
    @State private var isLoading = true
    @State private var error: String?
    var body: some View {
        VStack {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Creating session...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
            } else if let error = error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("Session Failed")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await createSession() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(height: 200)
            } else if let clientToken = clientToken {
                VStack {
                    Text("Dark Theme Demo")
                        .font(.headline)
                        .padding()
                    
                    Text("Full dark mode implementation")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                    
                    // Pure SwiftUI PrimerCheckout with custom dark styling
                    PrimerCheckout(
                        clientToken: clientToken,
                        settings: settings,
                        scope: { checkoutScope in
                            checkoutScope.setPaymentMethodScreen(.paymentCard) { (scope: any PrimerPaymentMethodScope) in
                                guard let cardScope = scope as? any PrimerCardFormScope else {
                                    return AnyView(Text("Error: Invalid scope type").foregroundColor(.red))
                                }
                                return AnyView(
                                    VStack(spacing: 20) {
                                        // Dark theme header
                                        VStack(spacing: 8) {
                                            Text("🌙 Dark Mode Payment")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                            Text("Complete your secure payment")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        
                                        // Dark styled card form
                                        VStack(spacing: 16) {
                                            // Card number with dark styling
                                            if let cardNumberInput = cardScope.cardNumberInput {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    Text("Card Number")
                                                        .font(.caption)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.white.opacity(0.9))
                                                    cardNumberInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(50)
                                                        .padding(.horizontal, 16)
                                                        .background(.white.opacity(0.1))
                                                        .cornerRadius(12)
                                                        .border(.white.opacity(0.3), width: 1.5)
                                                    )
                                                }
                                            }
                                            
                                            // Expiry and CVV row with dark theme
                                            HStack(spacing: 16) {
                                                if let expiryDateInput = cardScope.expiryDateInput {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        Text("Expiry Date")
                                                            .font(.caption)
                                                            .fontWeight(.medium)
                                                            .foregroundColor(.white.opacity(0.9))
                                                        expiryDateInput(PrimerModifier()
                                                            .fillMaxWidth()
                                                            .height(50)
                                                            .padding(.horizontal, 16)
                                                            .background(.white.opacity(0.1))
                                                            .cornerRadius(12)
                                                            .border(.white.opacity(0.3), width: 1.5)
                                                        )
                                                    }
                                                }
                                                
                                                if let cvvInput = cardScope.cvvInput {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        Text("CVV")
                                                            .font(.caption)
                                                            .fontWeight(.medium)
                                                            .foregroundColor(.white.opacity(0.9))
                                                        cvvInput(PrimerModifier()
                                                            .fillMaxWidth()
                                                            .height(50)
                                                            .padding(.horizontal, 16)
                                                            .background(.white.opacity(0.1))
                                                            .cornerRadius(12)
                                                            .border(.white.opacity(0.3), width: 1.5)
                                                        )
                                                    }
                                                }
                                            }
                                            
                                            // Cardholder name with dark theme
                                            if let cardholderNameInput = cardScope.cardholderNameInput {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    Text("Cardholder Name")
                                                        .font(.caption)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.white.opacity(0.9))
                                                    cardholderNameInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(50)
                                                        .padding(.horizontal, 16)
                                                        .background(.white.opacity(0.1))
                                                        .cornerRadius(12)
                                                        .border(.white.opacity(0.3), width: 1.5)
                                                    )
                                                }
                                            }
                                        }
                                        
                                        // Dark theme security notice
                                        HStack {
                                            Image(systemName: "lock.shield.fill")
                                                .foregroundColor(.green.opacity(0.8))
                                            Text("Secured with 256-bit encryption")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                    .padding(24)
                                    .background(
                                        LinearGradient(
                                            colors: [.black, .gray.opacity(0.9)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(16)
                                )
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .task {
            await createSession()
        }
    }
    
    /// Creates a session for this demo with dark theme support
    private func createSession() async {
        isLoading = true
        error = nil
        
        do {
            // Create session with surcharge support, supporting session type variations
            let surchargeAmount = extractSurchargeAmount(from: clientSession)
            let sessionBody = createSessionBody(surchargeAmount: surchargeAmount)
            
            // Request client token using the session configuration
            await withCheckedContinuation { continuation in
                Networking.requestClientSession(requestBody: sessionBody, apiVersion: apiVersion) { clientToken, error in
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
    
    /// Creates session body supporting different session types
    private func createSessionBody(surchargeAmount: Int) -> ClientSessionRequestBody {
        // Support session type variations - default to card only with surcharge for demos
        return MerchantMockDataManager.getClientSession(sessionType: .cardOnlyWithSurcharge, surchargeAmount: surchargeAmount)
    }
    
    /// Extracts surcharge amount from the configured client session
    private func extractSurchargeAmount(from clientSession: ClientSessionRequestBody?) -> Int {
        guard let session = clientSession,
              let paymentCardOptions = session.paymentMethod?.options?.PAYMENT_CARD,
              let networks = paymentCardOptions.networks else {
            return 50 // Default fallback
        }
        
        // Try to get surcharge amount from any of the configured networks
        if let visaSurcharge = networks.VISA?.surcharge.amount {
            return visaSurcharge
        }
        if let mastercardSurcharge = networks.MASTERCARD?.surcharge.amount {
            return mastercardSurcharge
        }
        if let jcbSurcharge = networks.JCB?.surcharge.amount {
            return jcbSurcharge
        }
        
        return 50 // Default fallback
    }
    
}
