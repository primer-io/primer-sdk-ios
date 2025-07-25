//
//  GYGDemo.swift
//  Debug App
//
//  Created by Claude on 24.7.25.
//

import SwiftUI
import PrimerSDK

/// GetYourGuide-themed CheckoutComponents demo
/// Demonstrates all card form features with GYG brand styling
@available(iOS 15.0, *)
struct GYGDemo: View {
    let settings: PrimerSettings
    let apiVersion: PrimerApiVersion
    let clientSession: ClientSessionRequestBody?
    
    @State private var clientToken: String?
    @State private var isLoading = true
    @State private var error: String?
    @State private var isDismissed = false
    @State private var isDarkMode = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Dark mode toggle header
            HStack {
                Text("GetYourGuide Demo")
                    .font(.headline)
                    .foregroundColor(isDarkMode ? .white : Color(red: 0.2, green: 0.2, blue: 0.2))
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                        .font(.system(size: 14))
                        .foregroundColor(isDarkMode ? Color(red: 1.0, green: 0.4, blue: 0.0) : Color(red: 1.0, green: 0.4, blue: 0.0))
                    
                    Toggle("", isOn: $isDarkMode)
                        .toggleStyle(SwitchToggleStyle(tint: Color(red: 1.0, green: 0.4, blue: 0.0)))
                        .labelsHidden()
                        .scaleEffect(0.8)
                }
            }
            .padding()
            .background(isDarkMode ? Color(red: 0.11, green: 0.11, blue: 0.11) : Color.white)
            
            // Main content
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isDarkMode ? Color.black : Color(red: 0.98, green: 0.98, blue: 0.98))
        }
        .background(isDarkMode ? Color.black : Color(red: 0.98, green: 0.98, blue: 0.98))
        .cornerRadius(12)
        .padding()
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .animation(.easeInOut(duration: 0.3), value: isDarkMode)
        .task {
            await createSession()
        }
    }
    
    // MARK: - State Views
    
    private var dismissedStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.0)) // GYG Orange
            
            Text("Booking Confirmed!")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Your GetYourGuide experience payment has been processed")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Book Another Experience") {
                isDismissed = false
                Task { await createSession() }
            }
            .buttonStyle(GYGButtonStyle())
        }
        .frame(height: 300)
        .padding()
    }
    
    private var loadingStateView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 1.0, green: 0.4, blue: 0.0)))
                .scaleEffect(1.2)
            Text("Preparing your experience...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
    }
    
    private func errorStateView(_ errorMessage: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.0))
            Text("Booking Failed")
                .font(.headline)
                .foregroundColor(.primary)
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task { await createSession() }
            }
            .buttonStyle(GYGButtonStyle())
        }
        .frame(height: 200)
    }
    
    private func checkoutView(clientToken: String) -> some View {
        VStack {
            // GYG Header
            VStack(spacing: 8) {
                HStack {
                    Text("GET")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.0)) // GYG Orange
                    + Text("YOUR")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.0))
                    + Text("GUIDE")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.0))
                    Spacer()
                }
                
                Text("Complete your booking")
                    .font(.headline)
                    .foregroundColor(isDarkMode ? .white : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Secure payment powered by Primer")
                    .font(.subheadline)
                    .foregroundColor(isDarkMode ? Color.gray : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(isDarkMode ? Color(red: 0.11, green: 0.11, blue: 0.11) : Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(isDarkMode ? 0.2 : 0.05), radius: 4, x: 0, y: 2)

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
    
    // MARK: - GYG Brand Styling
    private func customizeScope(_ checkoutScope: PrimerCheckoutScope) {
        checkoutScope.container = { content in
            AnyView(
                NavigationView {
                    content()
                        .navigationBarTitle("GetYourGuide Checkout", displayMode: .inline)
                }
            )
        }
        
        // Get the card form scope and apply GYG styling
        if let cardFormScope: DefaultCardFormScope = checkoutScope.getPaymentMethodScope(for: .paymentCard) {
            // Override the card form screen with GYG-themed design
            cardFormScope.screen = { _ in
                AnyView(GYGCardFormView(cardFormScope: cardFormScope, isDarkMode: isDarkMode))
            }
        }
    }
    
    // MARK: - Session Creation
    
    private func createSession() async {
        isLoading = true
        error = nil
        
        do {
            let sessionBody = createSessionBody()
            
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
    
    private func createSessionBody() -> ClientSessionRequestBody {
        guard let configuredSession = clientSession else {
            fatalError("No session configuration provided - GYGDemo requires configured session from main controller")
        }
        
        return configuredSession
    }
}

/// GetYourGuide-themed card form view
@available(iOS 15.0, *)
private struct GYGCardFormView: View {
    let cardFormScope: DefaultCardFormScope
    let isDarkMode: Bool
    
    @State private var cardState: StructuredCardFormState?
    @State private var stateTask: Task<Void, Never>?
    
    // GYG Brand Colors - Light Mode
    private let gygOrange = Color(red: 1.0, green: 0.4, blue: 0.0) // #FF6600
    private let gygBlue = Color(red: 0.0, green: 0.48, blue: 1.0) // #007BFF
    private let gygLightGray = Color(red: 0.98, green: 0.98, blue: 0.98)
    private let gygDarkGray = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    // Dark Mode Colors (matching GetYourGuide app)
    private var backgroundColor: Color {
        isDarkMode ? Color(red: 0.0, green: 0.0, blue: 0.0) : gygLightGray // Pure black background
    }
    
    private var cardBackgroundColor: Color {
        isDarkMode ? Color(red: 0.11, green: 0.11, blue: 0.11) : Color.white // #1C1C1C
    }
    
    private var textColor: Color {
        isDarkMode ? Color.white : gygDarkGray
    }
    
    private var secondaryTextColor: Color {
        isDarkMode ? Color(red: 0.6, green: 0.6, blue: 0.6) : Color.secondary // #999999
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                experienceSummaryCard
                
                // Wrap form sections in a container with dark mode background
                VStack(spacing: 16) {
                    paymentDetailsSection
                    billingAddressSection
                }
                .background(isDarkMode ? Color(red: 0.11, green: 0.11, blue: 0.11) : Color.white)
                .cornerRadius(16)
                
                securityAssuranceView
                submitButton
                footerText
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .background(backgroundColor)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            startObservingState()
        }
        .onDisappear {
            stateTask?.cancel()
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var experienceSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "ticket.fill")
                            .font(.title2)
                            .foregroundColor(gygOrange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Amazing City Tour")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(textColor)
                            Text("2 hours • Skip the line")
                                .font(.caption)
                                .foregroundColor(secondaryTextColor)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            if let surchargeString = cardState?.surchargeAmount,
                               let surcharge = Int(surchargeString),
                               surcharge > 0 {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("$89.00")
                                        .font(.system(size: 16))
                                        .foregroundColor(secondaryTextColor)
                                    Text("+ $\(String(format: "%.2f", Double(surcharge) / 100)) fee")
                                        .font(.system(size: 12))
                                        .foregroundColor(secondaryTextColor)
                                    Text("$\(String(format: "%.2f", Double(8900 + surcharge) / 100))")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(gygOrange)
                                }
                            } else {
                                Text("$89.00")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(gygOrange)
                            }
                            Text("per person")
                                .font(.caption)
                                .foregroundColor(secondaryTextColor)
                        }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(16)
    }

    @ViewBuilder
    private var paymentDetailsSection: some View {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Payment Details")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(textColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 16) {
                        // Card Number Field
                        gygMockField(label: "Card Number", placeholder: "1234 5678 9012 3456", color: gygOrange)
                        
                        // Co-badged Card Network Selection (if multiple networks detected)
                        if let availableNetworks = cardState?.availableNetworks,
                           availableNetworks.count > 1 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Select Card Network")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(textColor)
                                
                                HStack(spacing: 12) {
                                    ForEach(availableNetworks, id: \.self) { network in
                                        networkSelectionButton(for: network)
                                    }
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }
                        
                        HStack(spacing: 16) {
                            // Expiry Date Field
                            gygMockField(label: "Expiry", placeholder: "MM/YY", color: gygOrange)
                            
                            // CVV Field
                            gygMockField(label: "CVV", placeholder: "123", color: gygOrange)
                        }

                        // Cardholder Name Field
                        gygMockField(label: "Cardholder Name", placeholder: "John Smith", color: gygOrange)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var billingAddressSection: some View {
        // Always show billing address for GYG demo to demonstrate all features
        // In production, the backend controls these fields via checkout modules
        VStack(alignment: .leading, spacing: 20) {
            Text("Billing Address")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                // Country Field
                gygMockField(label: "Country", placeholder: "Select Country", color: gygOrange)
                
                // Address Line 1 Field
                gygMockField(label: "Address", placeholder: "123 Main St", color: gygOrange)
                
                HStack(spacing: 16) {
                    // Postal Code Field
                    gygMockField(label: "Postal Code", placeholder: "10001", color: gygOrange)
                    
                    // State Field (shown for countries that require it)
                    gygMockField(label: "State", placeholder: "NY", color: gygOrange)
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var securityAssuranceView: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.title3)
                .foregroundColor(gygBlue)
            VStack(alignment: .leading, spacing: 2) {
                Text("Secure Payment")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(textColor)
                Text("Your payment information is encrypted and secure")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
            Spacer()
        }
        .padding()
        .background(isDarkMode ? Color.blue.opacity(0.1) : Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var submitButton: some View {
        if let state = cardState {
            Button(action: {
                cardFormScope.onSubmit()
            }) {
                HStack(spacing: 12) {
                    if state.isValid {
                        Image(systemName: "creditcard.fill")
                            .font(.title3)
                    }
                    Text("Complete Booking")
                        .font(.system(size: 17, weight: .semibold))
                    if state.isValid {
                        Image(systemName: "arrow.right")
                            .font(.title3)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(state.isValid ? gygBlue : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(state.isValid ? 0.1 : 0), radius: 4, x: 0, y: 2)
            }
            .disabled(!state.isValid)
            .animation(.spring(), value: state.isValid)
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    @ViewBuilder
    private var footerText: some View {
        Text("By completing this booking, you agree to GetYourGuide's terms of service and privacy policy.")
            .font(.caption)
            .foregroundColor(secondaryTextColor)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
    
    private func startObservingState() {
        stateTask?.cancel()
        stateTask = Task {
            for await state in cardFormScope.state {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.cardState = state
                    }
                }
            }
        }
    }
    
    private func gygFieldStyling() -> PrimerFieldStyling {
        PrimerFieldStyling(
            font: .body,
            textColor: textColor,
            backgroundColor: isDarkMode ? Color(red: 0.18, green: 0.18, blue: 0.18) : Color.white, // #2E2E2E
            borderColor: isDarkMode ? Color(red: 0.3, green: 0.3, blue: 0.3) : Color.gray.opacity(0.3), // #4D4D4D
            focusedBorderColor: gygOrange,
            cornerRadius: 8,
            borderWidth: 1,
            padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        )
    }
    
    @ViewBuilder
    private func networkSelectionButton(for network: PrimerCardNetwork) -> some View {
        let isSelected = cardState?.selectedNetwork == network
        
        Button(action: {
            cardFormScope.updateSelectedCardNetwork(network.network.rawValue)
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? gygOrange : .gray)
                Text(network.network.rawValue.uppercased())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? gygOrange.opacity(0.1) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? gygOrange : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func gygMockField(label: String, placeholder: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if !label.isEmpty {
                Text(label)
                    .font(.caption)
                    .foregroundColor(textColor.opacity(0.7))
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isDarkMode ? Color(red: 0.18, green: 0.18, blue: 0.18) : Color.white)
                    .frame(height: 50)
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isDarkMode ? Color(red: 0.3, green: 0.3, blue: 0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                    .frame(height: 50)
                Text(placeholder)
                    .foregroundColor(textColor.opacity(0.3))
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// GetYourGuide button style
@available(iOS 15.0, *)
private struct GYGButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color(red: 0.0, green: 0.48, blue: 1.0)) // GYG Blue
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
