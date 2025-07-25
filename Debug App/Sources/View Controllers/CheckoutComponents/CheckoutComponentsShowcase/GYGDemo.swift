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
    
    @State private var cardState: PrimerCardFormState?
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
                        AnyView(cardFormScope.PrimerCardNumberField(
                            label: nil,
                            styling: gygFieldStyling()
                        ))
                        
                        // Co-badged Card Network Selection (if multiple networks detected)
                        if let availableNetworks = cardState?.availableCardNetworks,
                           availableNetworks.count > 1 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Select Card Network")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(textColor)
                                
                                HStack(spacing: 12) {
                                    ForEach(availableNetworks, id: \.self) { network in
                                        Button(action: {
                                            cardFormScope.updateSelectedCardNetwork(network)
                                        }) {
                                            HStack {
                                                Image(systemName: cardState?.selectedCardNetwork == network ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(cardState?.selectedCardNetwork == network ? gygOrange : .gray)
                                                Text(network.uppercased())
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(textColor)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(cardState?.selectedCardNetwork == network ? gygOrange.opacity(0.1) : Color.gray.opacity(0.1))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(cardState?.selectedCardNetwork == network ? gygOrange : Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
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
                            AnyView(cardFormScope.PrimerExpiryDateField(
                                label: nil,
                                styling: gygFieldStyling()
                            ))
                            
                            // CVV Field
                            AnyView(cardFormScope.PrimerCvvField(
                                label: nil,
                                styling: gygFieldStyling()
                            ))
                        }

                        // Cardholder Name Field
                        AnyView(cardFormScope.PrimerCardholderNameField(
                            label: nil,
                            styling: gygFieldStyling()
                        ))
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
                AnyView(cardFormScope.PrimerCountryField(
                    label: nil,
                    styling: gygFieldStyling()
                ))
                
                // Address Line 1 Field
                AnyView(cardFormScope.PrimerAddressLine1Field(
                    label: nil,
                    styling: gygFieldStyling()
                ))
                
                HStack(spacing: 16) {
                    // Postal Code Field
                    AnyView(cardFormScope.PrimerPostalCodeField(
                        label: nil,
                        styling: gygFieldStyling()
                    ))
                    
                    // State Field (shown for countries that require it)
                    AnyView(cardFormScope.PrimerStateField(
                        label: nil,
                        styling: gygFieldStyling()
                    ))
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
