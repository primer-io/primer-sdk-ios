//
//  LiveStateCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Live state demo with real-time state updates and debugging
@available(iOS 15.0, *)
struct LiveStateCardFormDemo: View {
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
                    Text("Live State Demo")
                        .font(.headline)
                        .padding()
                    
                    Text("Real-time state updates and debugging")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                    
                    // Pure SwiftUI PrimerCheckout with live state styling
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
                                        // Live state header with indicators
                                        VStack(spacing: 8) {
                                            HStack {
                                                Text("📊 Live State Monitor")
                                                    .font(.title2)
                                                    .fontWeight(.semibold)
                                                Spacer()
                                                Circle()
                                                    .fill(.green)
                                                    .frame(width: 10, height: 10)
                                                Text("LIVE")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.green)
                                            }
                                            Text("Real-time validation and state updates")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        // Form with live state indicators
                                        VStack(spacing: 16) {
                                            // Card number with live state
                                            if let cardNumberInput = cardScope.cardNumberInput {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    HStack {
                                                        Text("Card Number")
                                                            .font(.subheadline)
                                                            .fontWeight(.medium)
                                                        Spacer()
                                                        Text("🟢 Validating...")
                                                            .font(.caption)
                                                            .foregroundColor(.orange)
                                                    }
                                                    cardNumberInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(50)
                                                        .padding(.horizontal, 16)
                                                    )
                                                }
                                            }
                                            
                                            // Expiry and CVV with state indicators
                                            HStack(spacing: 16) {
                                                if let expiryDateInput = cardScope.expiryDateInput {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        HStack {
                                                            Text("Expiry")
                                                                .font(.subheadline)
                                                                .fontWeight(.medium)
                                                            Spacer()
                                                            Text("⚙️")
                                                                .font(.caption)
                                                        }
                                                        expiryDateInput(PrimerModifier()
                                                            .fillMaxWidth()
                                                            .height(50)
                                                            .padding(.horizontal, 16)
                                                        )
                                                    }
                                                }
                                                
                                                if let cvvInput = cardScope.cvvInput {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        HStack {
                                                            Text("CVV")
                                                                .font(.subheadline)
                                                                .fontWeight(.medium)
                                                            Spacer()
                                                            Text("🔒")
                                                                .font(.caption)
                                                        }
                                                        cvvInput(PrimerModifier()
                                                            .fillMaxWidth()
                                                            .height(50)
                                                            .padding(.horizontal, 16)
                                                        )
                                                    }
                                                }
                                            }
                                            
                                            // Cardholder name with live feedback
                                            if let cardholderNameInput = cardScope.cardholderNameInput {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    HStack {
                                                        Text("Name on Card")
                                                            .font(.subheadline)
                                                            .fontWeight(.medium)
                                                        Spacer()
                                                        Text("👤 Active")
                                                            .font(.caption)
                                                            .foregroundColor(.blue)
                                                    }
                                                    cardholderNameInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(50)
                                                        .padding(.horizontal, 16)
                                                    )
                                                }
                                            }
                                            
                                            // Submit button with live state
                                            if let submitButton = cardScope.submitButton {
                                                submitButton(PrimerModifier()
                                                    .fillMaxWidth()
                                                    .height(50)
                                                    .padding(.horizontal, 16)
                                                    .background(.blue)
                                                    .cornerRadius(10),
                                                    "Pay Now"
                                                )
                                            }
                                        }
                                        
                                        // Error view
                                        if let errorView = cardScope.errorView {
                                            errorView("Error placeholder")
                                        }
                                        
                                        // Live state indicators
                                        VStack(spacing: 4) {
                                            Text("• Real-time field validation")
                                            Text("• Live state change indicators")
                                            Text("• Instant feedback on input")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(20)
                                    .background(.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(.blue.opacity(0.2), lineWidth: 2)
                                    )
                                    .cornerRadius(12)
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
    
    /// Creates a session for this demo with live state support
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
