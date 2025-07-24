//
//  RuntimeCustomizationDemo.swift
//  Debug App
//
//  Created by Claude on 24.7.25.
//

import SwiftUI
import PrimerSDK

/// Demonstrates runtime customization with conditional component overrides
@available(iOS 15.0, *)
struct RuntimeCustomizationDemo: View {
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
                dismissedStateView
            } else if isLoading {
                loadingStateView
            } else if let error = error {
                errorStateView(error)
            } else if let clientToken = clientToken {
                checkoutView(clientToken: clientToken)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .task {
            await createSession()
        }
    }
    
    // MARK: - State Views
    
    private var dismissedStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("Demo Completed")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Runtime customization demo has been dismissed")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Reset Demo") {
                isDismissed = false
                Task { await createSession() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(height: 300)
        .padding()
    }
    
    private var loadingStateView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Creating session...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
    }
    
    private func errorStateView(_ errorMessage: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(.orange)
            Text("Session Failed")
                .font(.headline)
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await createSession() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(height: 200)
    }
    
    private func checkoutView(clientToken: String) -> some View {
        VStack {
            Text("Conditional Runtime Customization")
                .font(.headline)
                .padding()
            
            Text("Components change behavior based on card type and validation state")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom)

            PrimerCheckout(
                clientToken: clientToken,
                settings: settings,
                scope: customizeScope,
                onCompletion: {
                    isDismissed = true
                }
            )
        }
    }
    
    // MARK: - Scope Customization
    private func customizeScope(_ checkoutScope: PrimerCheckoutScope) {
        checkoutScope.container = { content in
            AnyView(
                NavigationView {
                    content()
                        .navigationBarTitle("Conditional Customization", displayMode: .inline)
                }
            )
        }
        
        // Get the card form scope
        if let cardFormScope: DefaultCardFormScope = checkoutScope.getPaymentMethodScope(for: .paymentCard) {
            // Override the card form screen with conditional customization demo
            cardFormScope.screen = { _ in
                AnyView(ConditionalCardFormView(cardFormScope: cardFormScope))
            }
        }
    }
    
    // MARK: - Session Creation
    
    /// Creates a session for this demo
    private func createSession() async {
        isLoading = true
        error = nil
        
        do {
            // Create session using the main controller's configuration
            let sessionBody = createSessionBody()
            
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
    
    /// Creates session body using the main controller's configuration
    private func createSessionBody() -> ClientSessionRequestBody {
        // Use the configured session from MerchantSessionAndSettingsViewController
        guard let configuredSession = clientSession else {
            fatalError("No session configuration provided - RuntimeCustomizationDemo requires configured session from main controller")
        }
        
        return configuredSession
    }
}

/// Card form view with conditional customization
@available(iOS 15.0, *)
private struct ConditionalCardFormView: View {
    let cardFormScope: DefaultCardFormScope
    
    @State private var cardState: PrimerCardFormState?
    @State private var detectedCardType: String = "Unknown"
    @State private var showSecurityBadge = false
    @State private var isAmex = false
    @State private var stateTask: Task<Void, Never>?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Card type indicator
                if detectedCardType != "Unknown" {
                    HStack {
                        Image(systemName: cardTypeIcon)
                            .font(.title2)
                        Text(detectedCardType)
                            .font(.headline)
                        Spacer()
                        if showSecurityBadge {
                            Label("Secure", systemImage: "lock.shield.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(cardTypeColor.opacity(0.1))
                    .cornerRadius(12)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Card form fields with conditional styling using real SDK components
                VStack(spacing: 16) {
                    // Card number with dynamic icon
                    HStack(spacing: 12) {
                        Image(systemName: cardTypeIcon)
                            .foregroundColor(cardTypeColor)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Card Number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            // Real card number field from SDK with conditional styling
                            AnyView(cardFormScope.PrimerCardNumberField(
                                label: nil,
                                styling: PrimerFieldStyling(
                                    backgroundColor: cardTypeColor.opacity(0.05),
                                    borderColor: cardTypeColor.opacity(0.3),
                                    focusedBorderColor: cardTypeColor,
                                    cornerRadius: 8,
                                    borderWidth: 1,
                                    padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
                                )
                            ))
                        }
                    }
                    
                    HStack(spacing: 16) {
                        // Expiry date
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Expiry")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            // Real expiry date field from SDK
                            AnyView(cardFormScope.PrimerExpiryDateField(
                                label: nil,
                                styling: PrimerFieldStyling(
                                    backgroundColor: Color.gray.opacity(0.05),
                                    borderColor: Color.gray.opacity(0.3),
                                    cornerRadius: 8,
                                    borderWidth: 1,
                                    padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
                                )
                            ))
                        }
                        
                        // CVV with conditional tooltip
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("CVV")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if isAmex {
                                    Image(systemName: "info.circle")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            // Real CVV field from SDK with Amex-specific styling
                            AnyView(cardFormScope.PrimerCvvField(
                                label: nil,
                                styling: PrimerFieldStyling(
                                    backgroundColor: Color.gray.opacity(0.05),
                                    borderColor: isAmex ? Color.blue : Color.gray.opacity(0.3),
                                    focusedBorderColor: isAmex ? Color.blue : Color.gray,
                                    cornerRadius: 8,
                                    borderWidth: isAmex ? 2 : 1,
                                    padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
                                )
                            ))
                        }
                    }
                    
                    // Cardholder name with validation feedback
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cardholder Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        // Real cardholder name field from SDK with validation styling
                        AnyView(cardFormScope.PrimerCardholderNameField(
                            label: nil,
                            styling: PrimerFieldStyling(
                                backgroundColor: Color.gray.opacity(0.05),
                                borderColor: cardholderValidationColor,
                                focusedBorderColor: cardholderValidationColor == .green ? .green : .orange,
                                cornerRadius: 8,
                                borderWidth: cardholderValidationColor == .clear ? 1 : 2,
                                padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
                            )
                        ))
                    }
                }
                .padding()
                .animation(.spring(), value: detectedCardType)
                
                // Dynamic help text based on card type
                if isAmex {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("American Express Card Detected", systemImage: "info.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("• CVV is 4 digits on the front of your card")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• Higher transaction limits available")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                }
                
                // Submit button with dynamic styling demo
                if let state = cardState {
                    Button(action: {
                        cardFormScope.onSubmit()
                    }) {
                        HStack {
                            if state.isValid {
                                Image(systemName: "checkmark.shield.fill")
                            }
                            Text("Submit Payment")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(submitButtonBackground(isValid: state.isValid))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(state.isValid ? Color.green : Color.clear, lineWidth: 2)
                        )
                    }
                    .disabled(!state.isValid)
                    .animation(.spring(), value: state.isValid)
                }
            }
            .padding()
        }
        .onAppear {
            startObservingState()
        }
        .onDisappear {
            stateTask?.cancel()
        }
    }
    
    private func startObservingState() {
        stateTask?.cancel()
        stateTask = Task {
            for await state in cardFormScope.state {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.cardState = state
                        self.updateCardType(from: state)
                    }
                }
            }
        }
    }
    
    private var cardTypeIcon: String {
        switch detectedCardType {
        case "Visa":
            return "creditcard.fill"
        case "Mastercard":
            return "creditcard.circle.fill"
        case "Amex":
            return "creditcard.trianglebadge.exclamationmark"
        default:
            return "creditcard"
        }
    }
    
    private var cardTypeColor: Color {
        switch detectedCardType {
        case "Visa":
            return .blue
        case "Mastercard":
            return .orange
        case "Amex":
            return .green
        default:
            return .gray
        }
    }
    
    private var cardholderValidationColor: Color {
        guard let state = cardState else {
            return Color.clear
        }
        
        let nameValue = state.cardholderName
        
        if nameValue.isEmpty {
            return Color.clear
        }
        
        return nameValue.count >= 2 ? Color.green : Color.orange
    }
    
    private func submitButtonBackground(isValid: Bool) -> Color {
        if isValid {
            return detectedCardType != "Unknown" ? cardTypeColor : .green
        }
        return .gray.opacity(0.3)
    }
    
    private func updateCardType(from state: PrimerCardFormState) {
        // Detect card type from card number
        let cardNumber = state.cardNumber
        
        if cardNumber.starts(with: "4") && cardNumber.count >= 1 {
            detectedCardType = "Visa"
            showSecurityBadge = true
            isAmex = false
        } else if (cardNumber.starts(with: "51") || cardNumber.starts(with: "52") ||
                   cardNumber.starts(with: "53") || cardNumber.starts(with: "54") ||
                   cardNumber.starts(with: "55")) && cardNumber.count >= 2 {
            detectedCardType = "Mastercard"
            showSecurityBadge = true
            isAmex = false
        } else if (cardNumber.starts(with: "34") || cardNumber.starts(with: "37")) && cardNumber.count >= 2 {
            detectedCardType = "Amex"
            showSecurityBadge = true
            isAmex = true
        } else if cardNumber.isEmpty {
            detectedCardType = "Unknown"
            showSecurityBadge = false
            isAmex = false
        }
    }
}
