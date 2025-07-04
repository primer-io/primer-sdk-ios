//
//  ValidationCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Validation showcase with error states and feedback
@available(iOS 15.0, *)
struct ValidationCardFormDemo: View {
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
                    Text("Validation Showcase Demo")
                        .font(.headline)
                        .padding()
                    
                    Text("Error states and validation feedback")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                    
                    // Pure SwiftUI PrimerCheckout with validation styling
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
                                        // Validation showcase header
                                        VStack(spacing: 8) {
                                            HStack {
                                                Text("✅ Validation Showcase")
                                                    .font(.title2)
                                                    .fontWeight(.semibold)
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
                                                Text("Test Examples")
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                Text("Valid: 4242424242424242 | Invalid: 1234")
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
                                                            .font(.subheadline)
                                                            .fontWeight(.medium)
                                                        Spacer()
                                                        Text("Required")
                                                            .font(.caption)
                                                            .foregroundColor(.red)
                                                    }
                                                    cardNumberInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(50)
                                                        .padding(.horizontal, 16)
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
                                                                .font(.subheadline)
                                                                .fontWeight(.medium)
                                                            Spacer()
                                                            Text("MM/YY")
                                                                .font(.caption)
                                                                .foregroundColor(.orange)
                                                        }
                                                        expiryDateInput(PrimerModifier()
                                                            .fillMaxWidth()
                                                            .height(50)
                                                            .padding(.horizontal, 16)
                                                        )
                                                        Text("Future date")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                
                                                if let cvvInput = cardScope.cvvInput {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        HStack {
                                                            Text("CVV")
                                                                .font(.subheadline)
                                                                .fontWeight(.medium)
                                                            Spacer()
                                                            Text("3-4 digits")
                                                                .font(.caption)
                                                                .foregroundColor(.purple)
                                                        }
                                                        cvvInput(PrimerModifier()
                                                            .fillMaxWidth()
                                                            .height(50)
                                                            .padding(.horizontal, 16)
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
                                                            .font(.subheadline)
                                                            .fontWeight(.medium)
                                                        Spacer()
                                                        Text("Full name")
                                                            .font(.caption)
                                                            .foregroundColor(.green)
                                                    }
                                                    cardholderNameInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(50)
                                                        .padding(.horizontal, 16)
                                                    )
                                                    Text("As shown on card")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            // Submit button with validation styling
                                            if let submitButton = cardScope.submitButton {
                                                submitButton(PrimerModifier()
                                                    .fillMaxWidth()
                                                    .height(50)
                                                    .padding(.horizontal, 16),
                                                    "Pay Now"
                                                )
                                            }
                                        }
                                        
                                        // Error view
                                        if let errorView = cardScope.errorView {
                                            errorView("Error placeholder")
                                        }
                                        
                                        // Validation rules footer
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Validation Rules:")
                                                .font(.caption)
                                                .fontWeight(.semibold)
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
    
    /// Creates a session for this demo with validation showcase support
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

