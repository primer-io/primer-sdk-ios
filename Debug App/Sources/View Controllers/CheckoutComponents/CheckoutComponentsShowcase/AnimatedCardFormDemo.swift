//
//  AnimatedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Animation playground demo with various animation styles
@available(iOS 15.0, *)
struct AnimatedCardFormDemo: View {
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
                    Text("Animation Demo")
                        .font(.headline)
                        .padding()
                    
                    Text("Various animation styles")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                    
                    // Pure SwiftUI PrimerCheckout with animated styling
                    PrimerCheckout(
                        clientToken: clientToken,
                        settings: settings,
                        scope: { checkoutScope in
                            checkoutScope.setPaymentMethodScreen(.paymentCard) { (scope: any PrimerPaymentMethodScope) in
                                guard let cardScope = scope as? any PrimerCardFormScope else {
                                    return AnyView(Text("Error: Invalid scope type").foregroundColor(.red))
                                }
                                return AnyView(AnimatedFormView(scope: cardScope))
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
    
    /// Creates a session for this demo with animation support
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



/// Animated form view with transitions and effects
@available(iOS 15.0, *)
struct AnimatedFormView: View {
    let scope: any PrimerCardFormScope
    @State private var isVisible = false
    @State private var slideOffset: CGFloat = 50
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated header
            VStack(spacing: 8) {
                Text("✨ Animated Payment")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                    .scaleEffect(isVisible ? 1.0 : 0.8)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: isVisible)
                
                Text("Smooth transitions and effects")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.5).delay(0.2), value: isVisible)
            }
            
            // Animated form fields
            VStack(spacing: 16) {
                // Card number with slide animation
                if let cardNumberInput = scope.cardNumberInput {
                    cardNumberInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(52)
                        .padding(.horizontal, 16)
                    )
                    .shadow(color: .purple.opacity(0.2), radius: 4, x: 0, y: 2)
                    .offset(x: isVisible ? 0 : -slideOffset)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.7, blendDuration: 0).delay(0.3), value: isVisible)
                }
                
                // Expiry and CVV with staggered animation
                HStack(spacing: 12) {
                    if let expiryDateInput = scope.expiryDateInput {
                        expiryDateInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(52)
                            .padding(.horizontal, 16)
                        )
                        .shadow(color: .orange.opacity(0.2), radius: 4, x: 0, y: 2)
                        .offset(x: isVisible ? 0 : -slideOffset)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.7, blendDuration: 0).delay(0.5), value: isVisible)
                    }
                    
                    if let cvvInput = scope.cvvInput {
                        cvvInput(PrimerModifier()
                            .fillMaxWidth()
                            .height(52)
                            .padding(.horizontal, 16)
                        )
                        .shadow(color: .blue.opacity(0.2), radius: 4, x: 0, y: 2)
                        .offset(x: isVisible ? 0 : slideOffset)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .animation(.spring(response: 0.7, dampingFraction: 0.7, blendDuration: 0).delay(0.6), value: isVisible)
                    }
                }
                
                // Cardholder name with bounce animation
                if let cardholderNameInput = scope.cardholderNameInput {
                    cardholderNameInput(PrimerModifier()
                        .fillMaxWidth()
                        .height(52)
                        .padding(.horizontal, 16)
                    )
                    .shadow(color: .green.opacity(0.2), radius: 4, x: 0, y: 2)
                    .offset(y: isVisible ? 0 : slideOffset)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0).delay(0.8), value: isVisible)
                }
                
                // Submit button with animated entrance
                if let submitButton = scope.submitButton {
                    submitButton(PrimerModifier()
                        .fillMaxWidth()
                        .height(56)
                        .padding(.horizontal, 18),
                        "✨ Animated Payment"
                    )
                    .shadow(color: .purple.opacity(0.3), radius: 6, x: 0, y: 3)
                    .scaleEffect(isVisible ? 1.0 : 0.9)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0).delay(1.0), value: isVisible)
                }
            }
            
            // Error view with animated entrance
            if let errorView = scope.errorView {
                errorView("Error placeholder")
            }
        }
        .padding(20)
        .background(LinearGradient(
            gradient: Gradient(colors: [
                .purple.opacity(0.05),
                .orange.opacity(0.05),
                .blue.opacity(0.05),
                .green.opacity(0.05)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ))
        .onAppear {
            isVisible = true
        }
    }
}
