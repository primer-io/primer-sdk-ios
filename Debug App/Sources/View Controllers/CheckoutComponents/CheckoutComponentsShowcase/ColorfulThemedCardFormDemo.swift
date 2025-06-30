//
//  ColorfulThemedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Colorful theme demo with branded colors and gradients
@available(iOS 15.0, *)
struct ColorfulThemedCardFormDemo: View {
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
                    Text("Colorful Theme Demo")
                        .font(.headline)
                        .padding()
                    
                    Text("Branded colors with gradients")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                    
                    // Pure SwiftUI PrimerCheckout with custom colorful styling
                    PrimerCheckout(
                        clientToken: clientToken,
                        settings: settings,
                        scope: { checkoutScope in
                            print("🌈 [ColorfulDemo] Scope builder called!")
                            print("🌈 [ColorfulDemo] Setting payment method screen for .paymentCard")
                            
                            // Set custom screen for card payments
                            checkoutScope.setPaymentMethodScreen(.paymentCard) { (scope: any PrimerPaymentMethodScope) in
                                print("🌈 [ColorfulDemo] Custom scope builder EXECUTED! Scope type: \(type(of: scope))")
                                guard let cardScope = scope as? any PrimerCardFormScope else {
                                    print("🌈 [ColorfulDemo] ❌ Failed to cast to PrimerCardFormScope")
                                    return AnyView(Text("Error: Invalid scope type").foregroundColor(.red))
                                }
                                print("🌈 [ColorfulDemo] ✅ Successfully cast to PrimerCardFormScope")
                                print("🌈 [ColorfulDemo] 🎨 Building colorful themed UI...")
                                return AnyView(
                                    VStack(spacing: 20) {
                                        // Colorful header
                                        Text("🌈 Payment")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundStyle(LinearGradient(
                                                gradient: Gradient(colors: [Color.purple, Color.pink, Color.orange]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ))
                                        
                                        // Colorful styled card form
                                        VStack(spacing: 16) {
                                            // Card number with rainbow border
                                            if let cardNumberInput = cardScope.cardNumberInput {
                                                cardNumberInput(PrimerModifier()
                                                    .fillMaxWidth()
                                                    .height(52)
                                                    .padding(.horizontal, 16)
                                                    .background(.white)
                                                    .cornerRadius(12)
                                                    .border(Color.purple.opacity(0.6), width: 2)
                                                    .shadow(color: Color.pink.opacity(0.3), radius: 4, x: 0, y: 2)
                                                )
                                            }
                                            
                                            // Expiry and CVV row with different colors
                                            HStack(spacing: 12) {
                                                if let expiryDateInput = cardScope.expiryDateInput {
                                                    expiryDateInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(52)
                                                        .padding(.horizontal, 16)
                                                        .background(.white)
                                                        .cornerRadius(12)
                                                        .border(Color.orange.opacity(0.6), width: 2)
                                                        .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
                                                    )
                                                }
                                                
                                                if let cvvInput = cardScope.cvvInput {
                                                    cvvInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(52)
                                                        .padding(.horizontal, 16)
                                                        .background(.white)
                                                        .cornerRadius(12)
                                                        .border(Color.green.opacity(0.6), width: 2)
                                                        .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
                                                    )
                                                }
                                            }
                                            
                                            // Cardholder name with blue accent
                                            if let cardholderNameInput = cardScope.cardholderNameInput {
                                                cardholderNameInput(PrimerModifier()
                                                    .fillMaxWidth()
                                                    .height(52)
                                                    .padding(.horizontal, 16)
                                                    .background(.white)
                                                    .cornerRadius(12)
                                                    .border(Color.blue.opacity(0.6), width: 2)
                                                    .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                                                )
                                            }
                                        }
                                    }
                                    .padding(20)
                                    .background(LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.purple.opacity(0.1),
                                            Color.pink.opacity(0.1),
                                            Color.orange.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .onAppear {
                                        print("🌈 [ColorfulDemo] 🎉 Colorful themed UI appeared!")
                                    }
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
    
    /// Creates a session for this demo with colorful theme support
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
