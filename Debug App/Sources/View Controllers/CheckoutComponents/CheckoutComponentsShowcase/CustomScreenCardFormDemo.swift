//
//  CustomScreenCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Custom screen layout demo with completely custom form layouts
@available(iOS 15.0, *)
struct CustomScreenCardFormDemo: View {
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
                    Text("Custom Screen Demo")
                        .font(.headline)
                        .padding()
                    
                    Text("Completely custom form layouts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                    
                    // Pure SwiftUI PrimerCheckout with custom screen layouts
                    PrimerCheckout(
                        clientToken: clientToken,
                        settings: settings,
                        scope: { checkoutScope in
                            checkoutScope.setPaymentMethodScreen(.paymentCard) { (scope: any PrimerPaymentMethodScope) in
                                guard let cardScope = scope as? any PrimerCardFormScope else {
                                    return AnyView(Text("Error: Invalid scope type").foregroundColor(.red))
                                }
                                return AnyView(
                                    GeometryReader { geometry in
                                        ScrollView {
                                            VStack(spacing: 24) {
                                                // Custom header with split design
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text("💳")
                                                            .font(.largeTitle)
                                                        Text("Custom Screen")
                                                            .font(.title3)
                                                            .fontWeight(.bold)
                                                        Text("Adaptive Layout")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    VStack(alignment: .trailing, spacing: 4) {
                                                        Text("Responsive")
                                                            .font(.caption)
                                                            .foregroundColor(.green)
                                                        Text("Design")
                                                            .font(.caption2)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                .padding(.horizontal)
                                                
                                                // Adaptive layout based on screen size
                                                if geometry.size.width > 400 {
                                                    // Wide layout - side by side
                                                    HStack(spacing: 20) {
                                                        // Left column
                                                        VStack(spacing: 16) {
                                                            if let cardNumberInput = cardScope.cardNumberInput {
                                                                cardNumberInput(PrimerModifier()
                                                                    .fillMaxWidth()
                                                                    .height(50)
                                                                    .padding(.horizontal, 14)
                                                                )
                                                            }
                                                            
                                                            if let cardholderNameInput = cardScope.cardholderNameInput {
                                                                cardholderNameInput(PrimerModifier()
                                                                    .fillMaxWidth()
                                                                    .height(50)
                                                                    .padding(.horizontal, 14)
                                                                )
                                                            }
                                                        }
                                                        
                                                        // Right column
                                                        VStack(spacing: 16) {
                                                            if let expiryDateInput = cardScope.expiryDateInput {
                                                                expiryDateInput(PrimerModifier()
                                                                    .fillMaxWidth()
                                                                    .height(50)
                                                                    .padding(.horizontal, 14)
                                                                )
                                                            }
                                                            
                                                            if let cvvInput = cardScope.cvvInput {
                                                                cvvInput(PrimerModifier()
                                                                    .fillMaxWidth()
                                                                    .height(50)
                                                                    .padding(.horizontal, 14)
                                                                )
                                                            }
                                                        }
                                                    }
                                                } else {
                                                    // Narrow layout - stacked
                                                    VStack(spacing: 16) {
                                                        if let cardNumberInput = cardScope.cardNumberInput {
                                                            VStack(spacing: 0) {
                                                                cardNumberInput(PrimerModifier()
                                                                    .fillMaxWidth()
                                                                    .height(50)
                                                                    .padding(.horizontal, 14)
                                                                )
                                                            }
                                                            .background(.white)
                                                            .cornerRadius(10)
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 10)
                                                                    .stroke(.gray.opacity(0.3), lineWidth: 1)
                                                            )
                                                        }
                                                        
                                                        HStack(spacing: 12) {
                                                            if let expiryDateInput = cardScope.expiryDateInput {
                                                                expiryDateInput(PrimerModifier()
                                                                    .fillMaxWidth()
                                                                    .height(50)
                                                                    .padding(.horizontal, 14)
                                                                )
                                                            }
                                                            
                                                            if let cvvInput = cardScope.cvvInput {
                                                                cvvInput(PrimerModifier()
                                                                    .fillMaxWidth()
                                                                    .height(50)
                                                                    .padding(.horizontal, 14)
                                                                )
                                                            }
                                                        }
                                                        
                                                        if let cardholderNameInput = cardScope.cardholderNameInput {
                                                            VStack(spacing: 0) {
                                                                cardholderNameInput(PrimerModifier()
                                                                    .fillMaxWidth()
                                                                    .height(50)
                                                                    .padding(.horizontal, 14)
                                                                )
                                                            }
                                                            .background(.white)
                                                            .cornerRadius(10)
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 10)
                                                                    .stroke(.gray.opacity(0.3), lineWidth: 1)
                                                            )
                                                        }
                                                    }
                                                }
                                                
                                                // Submit button (adaptive for both layouts)
                                                if let submitButton = cardScope.submitButton {
                                                    submitButton(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(54)
                                                        .padding(.horizontal, 16),
                                                        "Complete Payment"
                                                    )
                                                }
                                                
                                                // Error view
                                                if let errorView = cardScope.errorView {
                                                    errorView("Error placeholder")
                                                }
                                                
                                                // Custom footer with layout info
                                                HStack {
                                                    Image(systemName: "rectangle.split.2x1")
                                                        .foregroundColor(.blue)
                                                    Text("Layout: \(geometry.size.width > 400 ? "Wide" : "Compact")")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    Spacer()
                                                    Text("Adaptive Design")
                                                        .font(.caption2)
                                                        .foregroundColor(.blue)
                                                }
                                                .padding(.horizontal)
                                            }
                                            .padding()
                                        }
                                    }
                                    .background(LinearGradient(
                                        gradient: Gradient(colors: [.gray.opacity(0.02), .blue.opacity(0.02)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
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
    
    /// Creates a session for this demo with custom screen support
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
