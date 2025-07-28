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
            Text("🎨 Smart Runtime Customization")
                .font(.headline)
                .padding()
            
            VStack(spacing: 8) {
                Text("Watch components transform as you type!")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("• Card brand detection with dynamic styling\n• Real-time validation feedback\n• Context-aware help text\n• Adaptive submit button")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
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
    
    @State private var cardState: StructuredCardFormState?
    @State private var detectedCardType: String = "Unknown"
    @State private var showSecurityBadge = false
    @State private var isAmex = false
    @State private var stateTask: Task<Void, Never>?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Dynamic card type indicator with enhanced visual feedback
                VStack(spacing: 12) {
                    if detectedCardType != "Unknown" {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(cardTypeColor.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: cardTypeIcon)
                                    .font(.title2)
                                    .foregroundColor(cardTypeColor)
                            }
                            .scaleEffect(showSecurityBadge ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showSecurityBadge)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("✨ \(detectedCardType) Detected")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(cardTypeColor)
                                
                                if showSecurityBadge {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.shield.fill")
                                        Text("Secure & Validated")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            
                            Spacer()
                            
                            if isAmex {
                                VStack(spacing: 2) {
                                    Text("4-DIGIT")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                    Text("CVV")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(cardTypeColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(cardTypeColor.opacity(0.15))
                                .cornerRadius(6)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [cardTypeColor.opacity(0.1), cardTypeColor.opacity(0.05)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(cardTypeColor.opacity(0.3), lineWidth: 2)
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    } else {
                        HStack {
                            Image(systemName: "creditcard")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("Enter card number to see magic ✨")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [5, 5]))
                        )
                    }
                }
                
                // Card form fields with enhanced conditional styling
                VStack(spacing: 16) {
                    // Card number with animated dynamic styling
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(cardTypeColor.opacity(0.2))
                                    .frame(width: 32, height: 24)
                                
                                Image(systemName: cardTypeIcon)
                                    .font(.caption)
                                    .foregroundColor(cardTypeColor)
                            }
                            .animation(.spring(response: 0.3), value: cardTypeColor)
                            
                            Text("💳 Card Number")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(detectedCardType != "Unknown" ? cardTypeColor : .secondary)
                                .animation(.easeInOut(duration: 0.2), value: cardTypeColor)
                            
                            Spacer()
                            
                            if detectedCardType != "Unknown" {
                                Text(detectedCardType.uppercased())
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(cardTypeColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(cardTypeColor.opacity(0.15))
                                    .cornerRadius(4)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        
                        // Enhanced card number field with dramatic color changes
                        AnyView(
                            cardFormScope.PrimerCardNumberField(
                                label: nil,
                                styling: PrimerFieldStyling(
                                    font: .system(.body, design: .monospaced),
                                    backgroundColor: detectedCardType != "Unknown" ? cardTypeColor.opacity(0.08) : Color.gray.opacity(0.03),
                                    borderColor: detectedCardType != "Unknown" ? cardTypeColor.opacity(0.4) : Color.gray.opacity(0.3),
                                    focusedBorderColor: detectedCardType != "Unknown" ? cardTypeColor : .blue,
                                    cornerRadius: 12,
                                    borderWidth: detectedCardType != "Unknown" ? 2 : 1,
                                    padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
                                )
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: detectedCardType != "Unknown" 
                                            ? [cardTypeColor.opacity(0.6), cardTypeColor.opacity(0.2)]
                                            : [Color.clear, Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: detectedCardType != "Unknown" ? 2 : 0
                                )
                        )
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: cardTypeColor)
                    }
                    
                    HStack(spacing: 16) {
                        // Enhanced expiry date field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("📅 Expiry Date")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            AnyView(
                                cardFormScope.PrimerExpiryDateField(
                                    label: nil,
                                    styling: PrimerFieldStyling(
                                        font: .system(.body, design: .monospaced),
                                        backgroundColor: Color.blue.opacity(0.04),
                                        borderColor: Color.blue.opacity(0.2),
                                        focusedBorderColor: .blue,
                                        cornerRadius: 10,
                                        borderWidth: 1,
                                        padding: EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
                                    )
                                )
                            )
                        }
                        
                        // Enhanced CVV field with dynamic Amex styling 
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: isAmex ? "shield.lefthalf.filled" : "lock.shield")
                                    .font(.caption2)
                                    .foregroundColor(isAmex ? cardTypeColor : .secondary)
                                    .animation(.spring(response: 0.3), value: isAmex)
                                
                                Text(isAmex ? "🔐 CVV (4 digits)" : "🔐 CVV")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(isAmex ? cardTypeColor : .secondary)
                                    .animation(.easeInOut(duration: 0.2), value: isAmex)
                                
                                if isAmex {
                                    Text("FRONT")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(cardTypeColor)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(cardTypeColor.opacity(0.15))
                                        .cornerRadius(3)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            
                            AnyView(
                                cardFormScope.PrimerCvvField(
                                    label: nil,
                                    styling: PrimerFieldStyling(
                                        font: .system(.body, design: .monospaced),
                                        backgroundColor: isAmex ? cardTypeColor.opacity(0.08) : Color.orange.opacity(0.04),
                                        borderColor: isAmex ? cardTypeColor.opacity(0.4) : Color.orange.opacity(0.2),
                                        focusedBorderColor: isAmex ? cardTypeColor : .orange,
                                        cornerRadius: 10,
                                        borderWidth: isAmex ? 2 : 1,
                                        padding: EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
                                    )
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        isAmex ? cardTypeColor.opacity(0.3) : Color.clear,
                                        lineWidth: isAmex ? 1 : 0
                                    )
                                    .animation(.spring(response: 0.3), value: isAmex)
                            )
                        }
                    }
                    
                    // Enhanced cardholder name with real-time validation feedback
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: cardholderValidationIcon)
                                .font(.caption2)
                                .foregroundColor(cardholderValidationColor != .clear ? cardholderValidationColor : .secondary)
                                .animation(.spring(response: 0.3), value: cardholderValidationColor)
                            
                            Text("👤 Cardholder Name")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(cardholderValidationColor != .clear ? cardholderValidationColor : .secondary)
                                .animation(.easeInOut(duration: 0.2), value: cardholderValidationColor)
                            
                            Spacer()
                            
                            if cardholderValidationColor == .green {
                                Text("VALID")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.15))
                                    .cornerRadius(4)
                                    .transition(.scale.combined(with: .opacity))
                            } else if cardholderValidationColor == .orange {
                                Text("TOO SHORT")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.15))
                                    .cornerRadius(4)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        
                        AnyView(
                            cardFormScope.PrimerCardholderNameField(
                                label: nil,
                                styling: PrimerFieldStyling(
                                    backgroundColor: cardholderValidationColor != .clear 
                                        ? cardholderValidationColor.opacity(0.06) 
                                        : Color.purple.opacity(0.04),
                                    borderColor: cardholderValidationColor != .clear 
                                        ? cardholderValidationColor.opacity(0.4) 
                                        : Color.purple.opacity(0.2),
                                    focusedBorderColor: cardholderValidationColor != .clear 
                                        ? cardholderValidationColor 
                                        : .purple,
                                    cornerRadius: 12,
                                    borderWidth: cardholderValidationColor != .clear ? 2 : 1,
                                    padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
                                )
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    cardholderValidationColor != .clear 
                                        ? cardholderValidationColor.opacity(0.3) 
                                        : Color.clear,
                                    lineWidth: cardholderValidationColor != .clear ? 1 : 0
                                )
                                .animation(.spring(response: 0.3), value: cardholderValidationColor)
                        )
                    }
                }
                .padding()
                .animation(.spring(), value: detectedCardType)
                
                // Enhanced dynamic help text with card-specific information
                VStack(spacing: 12) {
                    if detectedCardType != "Unknown" {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                    .foregroundColor(cardTypeColor)
                                    .scaleEffect(showSecurityBadge ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showSecurityBadge)
                                
                                Text("\(detectedCardType) Features Activated")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(cardTypeColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                if isAmex {
                                    Label("CVV is 4 digits on the front of your card", systemImage: "creditcard.trianglebadge.exclamationmark")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Label("Enhanced fraud protection enabled", systemImage: "shield.checkered")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Label("Premium customer support included", systemImage: "person.badge.shield.checkmark")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                } else if detectedCardType == "Visa" {
                                    Label("Global acceptance worldwide", systemImage: "globe")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Label("Contactless payment ready", systemImage: "wave.3.right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Label("Zero liability protection", systemImage: "shield.lefthalf.filled")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                } else if detectedCardType == "Mastercard" {
                                    Label("Worldwide merchant acceptance", systemImage: "storefront")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Label("Price protection benefits", systemImage: "dollarsign.circle")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Label("Travel insurance included", systemImage: "airplane.circle")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [cardTypeColor.opacity(0.08), cardTypeColor.opacity(0.03)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(cardTypeColor.opacity(0.2), lineWidth: 1)
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("💡 Enter a card number (try 4242, 5555, or 3782) to see dynamic customization!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding()
                        .background(Color.orange.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange.opacity(0.2), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [3, 3]))
                        )
                    }
                }
                
                // Enhanced submit button with dynamic styling and card-specific branding
                if let state = cardState {
                    VStack(spacing: 8) {
                        Button(action: {
                            cardFormScope.onSubmit()
                        }) {
                            HStack(spacing: 12) {
                                if state.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Processing...")
                                        .fontWeight(.semibold)
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.3))
                                            .frame(width: 28, height: 28)
                                        
                                        if state.isValid {
                                            Image(systemName: detectedCardType != "Unknown" ? cardTypeIcon : "checkmark.shield.fill")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        } else {
                                            Image(systemName: "creditcard")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(state.isValid ? "Complete Payment" : "Complete Form")
                                            .font(.system(size: 17, weight: .semibold))
                                        
                                        if state.isValid && detectedCardType != "Unknown" {
                                            Text("Pay with \(detectedCardType)")
                                                .font(.caption)
                                                .opacity(0.9)
                                        } else if !state.isValid {
                                            Text("Fill all required fields")
                                                .font(.caption)
                                                .opacity(0.8)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                if state.isValid && detectedCardType != "Unknown" {
                                    Text("SECURE")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.black.opacity(0.2))
                                        .cornerRadius(6)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: state.isValid 
                                        ? [submitButtonBackground(isValid: true), submitButtonBackground(isValid: true).opacity(0.8)]
                                        : [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(
                                color: state.isValid ? submitButtonBackground(isValid: true).opacity(0.4) : Color.clear,
                                radius: state.isValid ? 8 : 0,
                                x: 0,
                                y: state.isValid ? 4 : 0
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: state.isValid && detectedCardType != "Unknown"
                                                ? [cardTypeColor.opacity(0.6), cardTypeColor.opacity(0.3)]
                                                : [Color.clear, Color.clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: state.isValid ? 2 : 0
                                    )
                            )
                            .scaleEffect(state.isValid ? 1.0 : 0.98)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: state.isValid)
                            .animation(.spring(response: 0.3), value: detectedCardType)
                        }
                        .disabled(!state.isValid || state.isLoading)
                        
                        // Dynamic submit button status indicator
                        if !state.isValid {
                            HStack(spacing: 4) {
                                Image(systemName: "info.circle")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                Text("Complete all fields to enable payment")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .transition(.opacity)
                        }
                    }
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
        
        let nameValue = state.data[.cardholderName]
        
        if nameValue.isEmpty {
            return Color.clear
        }
        
        return nameValue.count >= 2 ? Color.green : Color.orange
    }
    
    private var cardholderValidationIcon: String {
        guard let state = cardState else {
            return "person"
        }
        
        let nameValue = state.data[.cardholderName]
        
        if nameValue.isEmpty {
            return "person"
        }
        
        return nameValue.count >= 2 ? "person.fill.checkmark" : "person.fill.xmark"
    }
    
    private func submitButtonBackground(isValid: Bool) -> Color {
        if isValid {
            return detectedCardType != "Unknown" ? cardTypeColor : .green
        }
        return .gray.opacity(0.3)
    }
    
    private func updateCardType(from state: StructuredCardFormState) {
        // Detect card type from card number
        let cardNumber = state.data[.cardNumber]
        
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
