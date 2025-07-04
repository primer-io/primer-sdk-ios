//
//  ModifierChainsCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// PrimerModifier chains demo with complex styling combinations
@available(iOS 15.0, *)
struct ModifierChainsCardFormDemo: View {
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
                    Text("Modifier Chains Demo")
                        .font(.headline)
                        .padding()
                    
                    Text("Complex styling combinations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                    
                    // Pure SwiftUI PrimerCheckout with complex modifier chains
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
                                        // Modifier chains header
                                        VStack(spacing: 8) {
                                            Text("🔗 Modifier Chains")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.purple)
                                            
                                            Text("Complex PrimerModifier styling")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }

                                        // Advanced modifier chain examples
                                        VStack(spacing: 16) {
                                            // Card number with complex modifier chain
                                            if let cardNumberInput = cardScope.cardNumberInput {
                                                cardNumberInput(PrimerModifier()
                                                    .fillMaxWidth()
                                                    .height(55)
                                                    .padding(.horizontal, 18)
                                                )
                                                .shadow(color: .purple.opacity(0.2), radius: 6, x: 0, y: 3)
                                            }
                                            
                                            // Expiry and CVV with different chain styles
                                            HStack(spacing: 14) {
                                                if let expiryDateInput = cardScope.expiryDateInput {
                                                    expiryDateInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(55)
                                                        .padding(.horizontal, 16)
                                                    )
                                                    .shadow(color: .orange.opacity(0.3), radius: 4, x: 2, y: 2)
                                                }
                                                
                                                if let cvvInput = cardScope.cvvInput {
                                                    cvvInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(55)
                                                        .padding(.horizontal, 16)
                                                    )
                                                    .shadow(color: .blue.opacity(0.3), radius: 4, x: -2, y: 2)
                                                }
                                            }
                                            
                                            // Cardholder name with most complex chain
                                            if let cardholderNameInput = cardScope.cardholderNameInput {
                                                cardholderNameInput(PrimerModifier()
                                                    .fillMaxWidth()
                                                    .height(55)
                                                    .padding(.horizontal, 18)
                                                )
                                                .shadow(color: .green.opacity(0.2), radius: 8, x: 0, y: 4)
                                            }
                                            
                                            // Submit button with complex modifier chains
                                            if let submitButton = cardScope.submitButton {
                                                submitButton(PrimerModifier()
                                                    .fillMaxWidth()
                                                    .height(60)
                                                    .padding(.horizontal, 20),
                                                    "💎 Pay with Style"
                                                )
                                                .shadow(color: .purple.opacity(0.4), radius: 12, x: 0, y: 6)
                                                .shadow(color: .orange.opacity(0.3), radius: 8, x: 4, y: 4)
                                                .shadow(color: .blue.opacity(0.2), radius: 4, x: -2, y: -2)
                                            }
                                        }
                                        
                                        // Error view with modifier chains
                                        if let errorView = cardScope.errorView {
                                            errorView("Error message placeholder")
                                        }
                                        
                                        // Chain examples info
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Modifier Chain Examples:")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                            Text("• Multi-layer shadows with different colors")
                                            Text("• Complex border and corner radius combinations")
                                            Text("• Varied padding and spacing configurations")
                                            Text("• Gradient backgrounds with transparent overlays")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(20)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                .purple.opacity(0.05),
                                                .orange.opacity(0.05),
                                                .blue.opacity(0.05),
                                                .green.opacity(0.05)
                                            ]),
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
    
    /// Creates a session for this demo with modifier chains support
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
        // For showcase demos, use card-only session to skip payment method selection
        return MerchantMockDataManager.getClientSession(sessionType: .cardOnly, surchargeAmount: surchargeAmount)
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
