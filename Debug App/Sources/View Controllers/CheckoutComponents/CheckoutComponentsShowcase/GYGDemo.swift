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
            // Apply GYG field customizations using ViewBuilder methods
            let gygStyling = createGYGFieldStyling()
            
            // Set default field styling for all fields
            cardFormScope.defaultFieldStyling = [
                "cardNumber": gygStyling,
                "expiryDate": gygStyling,
                "cvv": gygStyling,
                "cardholderName": gygStyling,
                "country": gygStyling,
                "addressLine1": gygStyling,
                "postalCode": gygStyling,
                "state": gygStyling
            ]
            
            // Customize co-badged cards view with GYG styling
            cardFormScope.cobadgedCardsView = { availableNetworks, selectNetwork in
                AnyView(
                    GYGCobadgedCardsView(
                        availableNetworks: availableNetworks,
                        selectNetwork: selectNetwork,
                        isDarkMode: isDarkMode
                    )
                )
            }
            
            // Override the entire screen to maintain GYG layout
            cardFormScope.screen = { _ in
                AnyView(GYGCardFormView(cardFormScope: cardFormScope, isDarkMode: isDarkMode))
            }
        }
    }
    
    private func createGYGFieldStyling() -> PrimerFieldStyling {
        let gygOrange = Color(red: 1.0, green: 0.4, blue: 0.0)
        
        return PrimerFieldStyling(
            font: .body,
            labelFont: .caption,
            textColor: isDarkMode ? .white : Color(red: 0.2, green: 0.2, blue: 0.2),
            labelColor: isDarkMode ? Color.white.opacity(0.7) : Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.7),
            backgroundColor: isDarkMode ? Color(red: 0.18, green: 0.18, blue: 0.18) : Color.white,
            borderColor: isDarkMode ? Color(red: 0.3, green: 0.3, blue: 0.3) : Color.gray.opacity(0.3),
            focusedBorderColor: gygOrange,
            cornerRadius: 8,
            borderWidth: 1,
            padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        )
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

/// GetYourGuide-themed card form view using real SDK components
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
                
                // Card form with GYG styling using ViewBuilder methods
                VStack(spacing: 16) {
                    Text("Payment Information")
                        .font(.headline)
                        .foregroundColor(isDarkMode ? .white : .black)
                    
                    // Card fields using ViewBuilder methods
                    VStack(spacing: 12) {
                        AnyView(cardFormScope.PrimerCardNumberField(label: "Card Number", styling: nil))
                            .padding(.horizontal, 4)
                        
                        HStack(spacing: 12) {
                            AnyView(cardFormScope.PrimerExpiryDateField(label: "Expiry", styling: nil))
                            AnyView(cardFormScope.PrimerCvvField(label: "CVV", styling: nil))
                                .frame(width: 100)
                        }
                        .padding(.horizontal, 4)
                        
                        AnyView(cardFormScope.PrimerCardholderNameField(label: "Cardholder Name", styling: nil))
                            .padding(.horizontal, 4)
                    }
                    
                    // GYG Submit Button
                    Button(action: {
                        cardFormScope.onSubmit()
                    }) {
                        HStack(spacing: 8) {
                            if cardState?.isLoading == true {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Processing...")
                            } else {
                                Image(systemName: "creditcard.fill")
                                Text("Complete Booking")
                            }
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    (cardState?.isValid == true && cardState?.isLoading != true) 
                                        ? gygOrange 
                                        : Color.gray.opacity(0.6)
                                )
                        )
                    }
                    .disabled(cardState?.isValid != true || cardState?.isLoading == true)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 8)
                }
                .padding()
                .background(isDarkMode ? Color(red: 0.11, green: 0.11, blue: 0.11) : Color.white)
                .cornerRadius(16)
                
                securityAssuranceView
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
}


/// GYG-themed co-badged cards view
@available(iOS 15.0, *)
private struct GYGCobadgedCardsView: View {
    let availableNetworks: [String]
    let selectNetwork: (String) -> Void
    let isDarkMode: Bool
    
    private let gygOrange = Color(red: 1.0, green: 0.4, blue: 0.0)
    
    private var textColor: Color {
        isDarkMode ? Color.white : Color(red: 0.2, green: 0.2, blue: 0.2)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Card Network")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(textColor)
            
            HStack(spacing: 12) {
                ForEach(availableNetworks, id: \.self) { network in
                    Button(action: {
                        selectNetwork(network)
                    }) {
                        HStack {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                            Text(network.uppercased())
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(textColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
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

