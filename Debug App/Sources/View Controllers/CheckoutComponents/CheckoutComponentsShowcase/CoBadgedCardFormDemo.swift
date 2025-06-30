//
//  CoBadgedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Co-badged cards demo with multiple network selection
@available(iOS 15.0, *)
struct CoBadgedCardFormDemo: View {
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
                    Text("Co-badged Cards Demo")
                        .font(.headline)
                        .padding()
                    
                    Text("Multiple network selection demo")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                    
                    // Pure SwiftUI PrimerCheckout with co-badged styling
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
                                        // Co-badged cards header
                                        VStack(spacing: 8) {
                                            HStack {
                                                Text("🔄 Co-badged Cards")
                                                    .font(.title2)
                                                    .fontWeight(.semibold)
                                                Spacer()
                                                HStack(spacing: 4) {
                                                    Text("VISA")
                                                        .font(.caption)
                                                        .fontWeight(.bold)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(.blue)
                                                        .foregroundColor(.white)
                                                        .cornerRadius(4)
                                                    Text("MC")
                                                        .font(.caption)
                                                        .fontWeight(.bold)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(.red)
                                                        .foregroundColor(.white)
                                                        .cornerRadius(4)
                                                }
                                            }
                                            Text("Cards that support multiple payment networks")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        // Co-badged example info
                                        HStack {
                                            Image(systemName: "creditcard.fill")
                                                .foregroundColor(.blue)
                                                .font(.title3)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Network Selection")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                Text("Choose from multiple networks")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Text("🔍")
                                                .font(.title2)
                                        }
                                        .padding(12)
                                        .background(.blue.opacity(0.1))
                                        .cornerRadius(10)
                                        
                                        // Form with co-badged emphasis
                                        VStack(spacing: 16) {
                                            // Card number with network detection
                                            if let cardNumberInput = cardScope.cardNumberInput {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    HStack {
                                                        Text("Card Number")
                                                            .font(.subheadline)
                                                            .fontWeight(.medium)
                                                        Spacer()
                                                        HStack(spacing: 4) {
                                                            Text("Auto-detect")
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                            Image(systemName: "network")
                                                                .font(.caption)
                                                                .foregroundColor(.blue)
                                                        }
                                                    }
                                                    cardNumberInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(52)
                                                        .padding(.horizontal, 16)
                                                        .background(.blue.opacity(0.08))
                                                        .cornerRadius(12)
                                                        .border(.blue.opacity(0.4), width: 1.5)
                                                    )
                                                    Text("Network detected automatically")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            // Other fields with network-aware styling
                                            HStack(spacing: 16) {
                                                if let expiryDateInput = cardScope.expiryDateInput {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        Text("Expiry")
                                                            .font(.subheadline)
                                                            .fontWeight(.medium)
                                                        expiryDateInput(PrimerModifier()
                                                            .fillMaxWidth()
                                                            .height(52)
                                                            .padding(.horizontal, 16)
                                                            .background(.purple.opacity(0.08))
                                                            .cornerRadius(12)
                                                            .border(.purple.opacity(0.4), width: 1.5)
                                                        )
                                                    }
                                                }
                                                
                                                if let cvvInput = cardScope.cvvInput {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        Text("CVV")
                                                            .font(.subheadline)
                                                            .fontWeight(.medium)
                                                        cvvInput(PrimerModifier()
                                                            .fillMaxWidth()
                                                            .height(52)
                                                            .padding(.horizontal, 16)
                                                            .background(.green.opacity(0.08))
                                                            .cornerRadius(12)
                                                            .border(.green.opacity(0.4), width: 1.5)
                                                        )
                                                    }
                                                }
                                            }
                                            
                                            // Cardholder name
                                            if let cardholderNameInput = cardScope.cardholderNameInput {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    Text("Cardholder Name")
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                    cardholderNameInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(52)
                                                        .padding(.horizontal, 16)
                                                        .background(.orange.opacity(0.08))
                                                        .cornerRadius(12)
                                                        .border(.orange.opacity(0.4), width: 1.5)
                                                    )
                                                }
                                            }
                                        }
                                        
                                        // Co-badged information footer
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Co-badged Features:")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                            Text("• Single card, multiple networks")
                                            Text("• User can choose preferred network")
                                            Text("• Automatic network detection")
                                            Text("• Optimized routing for best rates")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(20)
                                    .background(.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
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
    
    /// Creates a session for this demo with co-badged card support
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
