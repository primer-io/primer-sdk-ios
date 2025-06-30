//
//  ExpandedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Expanded layout demo with vertical fields and generous spacing
@available(iOS 15.0, *)
struct ExpandedCardFormDemo: View {
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
                    Text("Expanded Layout Demo")
                        .font(.headline)
                        .padding()

                    Text("Vertical fields with generous spacing")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)

                    // Pure SwiftUI PrimerCheckout with custom expanded styling
                    PrimerCheckout(
                        clientToken: clientToken,
                        settings: settings,
                        scope: { checkoutScope in
                            checkoutScope.setPaymentMethodScreen(.paymentCard) { (scope: any PrimerPaymentMethodScope) in
                                guard let cardScope = scope as? any PrimerCardFormScope else {
                                    return AnyView(Text("Error: Invalid scope type").foregroundColor(.red))
                                }
                                return AnyView(
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
                                                    )
                                                    .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
                                                }
                                            }
                                            
                                            // Expiry and CVV with labels
                                            HStack(spacing: 20) {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    Text("Expiry Date")
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                    
                                                    if let expiryDateInput = cardScope.expiryDateInput {
                                                        expiryDateInput(PrimerModifier()
                                                            .fillMaxWidth()
                                                            .height(60)
                                                            .padding(.horizontal, 20)
                                                        )
                                                        .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
                                                    }
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 8) {
                                                    Text("CVV")
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                    
                                                    if let cvvInput = cardScope.cvvInput {
                                                        cvvInput(PrimerModifier()
                                                            .fillMaxWidth()
                                                            .height(60)
                                                            .padding(.horizontal, 20)
                                                        )
                                                        .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
                                                    }
                                                }
                                            }
                                            
                                            // Cardholder name with label
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Cardholder Name")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                
                                                if let cardholderNameInput = cardScope.cardholderNameInput {
                                                    cardholderNameInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(60)
                                                        .padding(.horizontal, 20)
                                                    )
                                                    .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
                                                }
                                            }
                                            
                                            // Expanded submit button
                                            if let submitButton = cardScope.submitButton {
                                                submitButton(PrimerModifier()
                                                    .fillMaxWidth()
                                                    .height(64)
                                                    .padding(.horizontal, 20),
                                                    "Complete Payment"
                                                )
                                                .shadow(color: .blue.opacity(0.3), radius: 6, x: 0, y: 3)
                                            }
                                        }
                                        
                                        // Expanded error view
                                        if let errorView = cardScope.errorView {
                                            errorView("Error placeholder")
                                        }
                                    }
                                    .padding(24)
                                    .background(.blue.opacity(0.02))
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
    
    /// Creates a session for this demo with expanded layout support
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
