//
//  ColorfulThemedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Colorful theme demo with branded colors and gradients
/// Demonstrates the new ViewBuilder approach with field rearrangement
@available(iOS 15.0, *)
struct ColorfulThemedCardFormDemo: View {
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
            
            Text("Colorful theme demo has been dismissed")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Reset Demo") {
                isDismissed = false
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
            Text("Deep Field Styling Demo")
                .font(.headline)
                .padding()
            
            Text("Custom fonts, colors, borders & styling applied directly to input fields")
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

    // MARK: - Scope Customization with ViewBuilder Approach
    private func customizeScope(_ checkoutScope: PrimerCheckoutScope) {
        // Set up custom card form screen using ViewBuilder approach
        setupCardFormScreen(checkoutScope)
    }
    
    private func setupCardFormScreen(_ checkoutScope: PrimerCheckoutScope) {
        // Override the default card form screen with custom ViewBuilder content
        if let cardScope: DefaultCardFormScope = checkoutScope.getPaymentMethodScope(for: .paymentCard) {
            // Set custom screen using ViewBuilder
            cardScope.screen = { scope in
                AnyView(createCustomCardFormScreen(scope: scope))
            }
        }
    }
    
    // Create custom card form screen with rearranged fields and colorful styling
    @ViewBuilder
    private func createCustomCardFormScreen(scope: any PrimerCardFormScope) -> some View {
        // Use the protocol methods directly - they should be available on any conforming type
        ScrollView {
            VStack(spacing: 20) {
                // Title section
                VStack(spacing: 8) {
                    Text("Deep Field Customization")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Custom field styling: fonts, colors, borders, radius, padding")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // CARDHOLDER NAME with custom field styling 🎯 
                VStack(spacing: 16) {
                    AnyView(scope.PrimerCardholderNameField(
                        label: "Full Name",
                        styling: PrimerFieldStyling(
                            font: .title3,
                            labelFont: .caption,
                            textColor: .purple,
                            labelColor: .indigo,
                            backgroundColor: Color.purple.opacity(0.05),
                            borderColor: .purple,
                            focusedBorderColor: .indigo,
                            errorBorderColor: .red,
                            placeholderColor: .purple.opacity(0.6),
                            cornerRadius: 16,
                            borderWidth: 2,
                            padding: EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20),
                            fieldHeight: 60
                        )
                    ))
                    .padding(.horizontal)
                    
                    // Custom merchant component between Primer fields
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Premium Member Discount Applied!")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Text("-10%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                        // Card Number with deep field styling
                        AnyView(scope.PrimerCardNumberField(
                            label: "Card Number",
                            styling: PrimerFieldStyling(
                                font: .title2,
                                labelFont: .caption2,
                                textColor: .blue,
                                labelColor: .cyan,
                                backgroundColor: Color.blue.opacity(0.08),
                                borderColor: .blue,
                                focusedBorderColor: .cyan,
                                errorBorderColor: .red,
                                placeholderColor: .blue.opacity(0.5),
                                cornerRadius: 20,
                                borderWidth: 3,
                                padding: EdgeInsets(top: 18, leading: 24, bottom: 18, trailing: 24),
                                fieldHeight: 65
                            )
                        ))
                        .padding(.horizontal)
                        
                        // Expiry and CVV with custom field styling
                        HStack(spacing: 12) {
                            AnyView(scope.PrimerExpiryDateField(
                                label: "Expiry",
                                styling: PrimerFieldStyling(
                                    font: .headline,
                                    labelFont: .caption,
                                    textColor: .orange,
                                    labelColor: .yellow,
                                    backgroundColor: Color.orange.opacity(0.1),
                                    borderColor: .orange,
                                    focusedBorderColor: .yellow,
                                    errorBorderColor: .red,
                                    placeholderColor: .orange.opacity(0.7),
                                    cornerRadius: 12,
                                    borderWidth: 2,
                                    padding: EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16),
                                    fieldHeight: 55
                                )
                            ))
                            
                            AnyView(scope.PrimerCvvField(
                                label: "CVV",
                                styling: PrimerFieldStyling(
                                    font: .headline,
                                    labelFont: .caption,
                                    textColor: .teal,
                                    labelColor: .mint,
                                    backgroundColor: Color.teal.opacity(0.1),
                                    borderColor: .teal,
                                    focusedBorderColor: .mint,
                                    errorBorderColor: .red,
                                    placeholderColor: .teal.opacity(0.7),
                                    cornerRadius: 12,
                                    borderWidth: 2,
                                    padding: EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16),
                                    fieldHeight: 55
                                )
                            ))
                        }
                        .padding(.horizontal)
                    
                    // Another custom component
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Secure Payment", systemImage: "lock.shield.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text("Your payment information is encrypted and secure")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                        // Billing Address Section with colorful styling
                        if isShowingBillingAddressFields(scope) {
                            VStack(spacing: 16) {
                                Text("Billing Address")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    .padding(.top)
                                
                                createColorfulBillingAddressSection(scope: scope)
                            }
                        }
                        
                        // Submit button with gradient
                        AnyView(scope.PrimerSubmitButton(text: "Pay Now"))
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .padding(.top)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemBackground))
    }
    
    // Check if billing address fields should be shown
    private func isShowingBillingAddressFields(_ scope: any PrimerCardFormScope) -> Bool {
        // For the showcase demo, always show billing address fields to demonstrate the capability
        return true
    }
    
    // Create colorful billing address section with ViewBuilder
    private func createColorfulBillingAddressSection(scope: any PrimerCardFormScope) -> some View {
        VStack(spacing: 16) {
            // Name fields with deep styling
            HStack(spacing: 12) {
                AnyView(scope.PrimerFirstNameField(
                    label: "First Name",
                    styling: PrimerFieldStyling(
                        font: .body,
                        labelFont: .caption2,
                        textColor: .cyan,
                        labelColor: .teal,
                        backgroundColor: Color.cyan.opacity(0.08),
                        borderColor: .cyan,
                        focusedBorderColor: .teal,
                        placeholderColor: .cyan.opacity(0.6),
                        cornerRadius: 7,
                        borderWidth: 1.5
                    )
                ))
                
                AnyView(scope.PrimerLastNameField(
                    label: "Last Name",
                    styling: PrimerFieldStyling(
                        font: .body,
                        labelFont: .caption2,
                        textColor: .mint,
                        labelColor: .green,
                        backgroundColor: Color.mint.opacity(0.08),
                        borderColor: .mint,
                        focusedBorderColor: .green,
                        placeholderColor: .mint.opacity(0.6),
                        cornerRadius: 10,
                        borderWidth: 1.5
                    )
                ))
            }
            .padding(.horizontal)
            
            // Country field with custom styling
            AnyView(scope.PrimerCountryField(
                label: "Country",
                styling: PrimerFieldStyling(
                    font: .body,
                    labelFont: .caption2,
                    textColor: .purple,
                    labelColor: .indigo,
                    backgroundColor: Color.purple.opacity(0.06),
                    borderColor: .purple,
                    focusedBorderColor: .indigo,
                    placeholderColor: .purple.opacity(0.6),
                    cornerRadius: 13,
                    borderWidth: 3
                )
            ))
            .padding(.horizontal)
            
            // Address field with custom styling
            AnyView(scope.PrimerAddressLine1Field(
                label: "Address",
                styling: PrimerFieldStyling(
                    font: .body,
                    labelFont: .caption2,
                    textColor: .indigo,
                    labelColor: .purple,
                    backgroundColor: Color.indigo.opacity(0.08),
                    borderColor: .indigo,
                    focusedBorderColor: .purple,
                    placeholderColor: .indigo.opacity(0.6),
                    cornerRadius: 17,
                    borderWidth: 1.5
                )
            ))
            .padding(.horizontal)
            
            // Postal Code and State with custom styling
            HStack(spacing: 12) {
                AnyView(scope.PrimerPostalCodeField(
                    label: "Postal Code",
                    styling: PrimerFieldStyling(
                        font: .body,
                        labelFont: .caption2,
                        textColor: .pink,
                        labelColor: .red,
                        backgroundColor: Color.pink.opacity(0.08),
                        borderColor: .pink,
                        focusedBorderColor: .red,
                        placeholderColor: .pink.opacity(0.6),
                        cornerRadius: 20,
                        borderWidth: 1.5
                    )
                ))
                
                AnyView(scope.PrimerStateField(
                    label: "State",
                    styling: PrimerFieldStyling(
                        font: .body,
                        labelFont: .caption2,
                        textColor: .gray,
                        labelColor: .secondary,
                        backgroundColor: Color.gray.opacity(0.06),
                        borderColor: .gray,
                        focusedBorderColor: .primary,
                        placeholderColor: .gray.opacity(0.7),
                        cornerRadius: 23,
                        borderWidth: 1
                    )
                ))
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Session Creation
    
    /// Creates a session for this demo with colorful theme support
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
        // This includes all settings: currency, billing address, payment methods, etc.
        guard let configuredSession = clientSession else {
            fatalError("No session configuration provided - ColorfulThemedCardFormDemo requires configured session from main controller")
        }
        
        return configuredSession
    }
}
