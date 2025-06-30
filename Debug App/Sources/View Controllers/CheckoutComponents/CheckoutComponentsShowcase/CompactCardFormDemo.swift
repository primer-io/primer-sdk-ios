//
//  CompactCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Compact layout demo with horizontal card fields
@available(iOS 15.0, *)
struct CompactCardFormDemo: View {
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    let clientSession: ClientSessionRequestBody?
    
    @State private var clientToken: String?
    @State private var isLoading = true
    @State private var error: String?
    @State private var isDismissed = false
    var body: some View {
        VStack {
            if isDismissed {
                // Show dismissed state with option to reset
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Demo Completed")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Compact layout demo has been dismissed")
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
            } else if isLoading {
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
                    Text("Compact Layout Demo")
                        .font(.headline)
                        .padding()

                    Text("Horizontal fields with tight spacing")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)

                    // Pure SwiftUI PrimerCheckout with custom compact styling
                    PrimerCheckout(
                        clientToken: clientToken,
                        settings: settings,
                        scope: { checkoutScope in
                            checkoutScope.setPaymentMethodScreen(.paymentCard) { (scope: any PrimerPaymentMethodScope) in
                                guard let cardScope = scope as? any PrimerCardFormScope else {
                                    return AnyView(Text("Error: Invalid scope type").foregroundColor(.red))
                                }
                                return AnyView(
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
                                                )
                                                .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
                                            }
                                            
                                            // Compact row: Expiry, CVV, and first part of name
                                            HStack(spacing: 6) {
                                                if let expiryDateInput = cardScope.expiryDateInput {
                                                    expiryDateInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(40)
                                                        .padding(.horizontal, 10)
                                                    )
                                                    .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
                                                }
                                                
                                                if let cvvInput = cardScope.cvvInput {
                                                    cvvInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(40)
                                                        .padding(.horizontal, 10)
                                                    )
                                                    .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
                                                }
                                                
                                                if let cardholderNameInput = cardScope.cardholderNameInput {
                                                    cardholderNameInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(40)
                                                        .padding(.horizontal, 10)
                                                    )
                                                    .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
                                                }
                                            }
                                            
                                            // Compact submit button
                                            if let submitButton = cardScope.submitButton {
                                                submitButton(PrimerModifier()
                                                    .fillMaxWidth()
                                                    .height(40)
                                                    .padding(.horizontal, 12)
                                                    .background(.blue)
                                                    .cornerRadius(6)
                                                    .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1),
                                                    "Pay"
                                                )
                                            }
                                        }
                                        
                                        // Compact error view
                                        if let errorView = cardScope.errorView {
                                            errorView("Error placeholder")
                                        }
                                    }
                                    .padding(16)
                                    .background(.gray.opacity(0.05))
                                )
                            }
                        },
                        onCompletion: {
                            isDismissed = true
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
    
    /// Creates a session for this demo with compact layout support
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
