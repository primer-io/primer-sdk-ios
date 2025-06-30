//
//  ModernThemedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Modern theme demo with clean white and subtle shadows
@available(iOS 15.0, *)
struct ModernThemedCardFormDemo: View {
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
                    Text("Modern Theme Demo")
                        .font(.headline)
                        .padding()

                    Text("Clean white with subtle shadows")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)

                    // Pure SwiftUI PrimerCheckout with custom modern styling
                    PrimerCheckout(
                        clientToken: clientToken,
                        settings: settings,
                        scope: { checkoutScope in
                            checkoutScope.setPaymentMethodScreen(.paymentCard) { (scope: any PrimerPaymentMethodScope) in
                                guard let cardScope = scope as? any PrimerCardFormScope else {
                                    return AnyView(Text("Error: Invalid scope type").foregroundColor(.red))
                                }
                                return AnyView(
                                    VStack(spacing: 24) {
                                        // Modern header
                                        Text("Payment")
                                            .font(.largeTitle)
                                            .fontWeight(.thin)
                                            .foregroundColor(.primary)
                                        
                                        // Modern styled card form
                                        VStack(spacing: 20) {
                                            // Card number with modern styling
                                            if let cardNumberInput = cardScope.cardNumberInput {
                                                cardNumberInput(PrimerModifier()
                                                    .fillMaxWidth()
                                                    .height(56)
                                                    .padding(.horizontal, 20)
                                                    .background(.white)
                                                    .cornerRadius(16)
                                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                                                )
                                            }
                                            
                                            // Expiry and CVV row
                                            HStack(spacing: 16) {
                                                if let expiryDateInput = cardScope.expiryDateInput {
                                                    expiryDateInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(56)
                                                        .padding(.horizontal, 20)
                                                        .background(.white)
                                                        .cornerRadius(16)
                                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                                                    )
                                                }
                                                
                                                if let cvvInput = cardScope.cvvInput {
                                                    cvvInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(56)
                                                        .padding(.horizontal, 20)
                                                        .background(.white)
                                                        .cornerRadius(16)
                                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                                                    )
                                                }
                                            }
                                            
                                            // Cardholder name
                                            if let cardholderNameInput = cardScope.cardholderNameInput {
                                                cardholderNameInput(PrimerModifier()
                                                    .fillMaxWidth()
                                                    .height(56)
                                                    .padding(.horizontal, 20)
                                                    .background(.white)
                                                    .cornerRadius(16)
                                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                                                )
                                            }
                                        }
                                    }
                                    .padding(24)
                                    .background(.gray.opacity(0.02))
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

    /// Creates a session for this demo with modern theme support
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
