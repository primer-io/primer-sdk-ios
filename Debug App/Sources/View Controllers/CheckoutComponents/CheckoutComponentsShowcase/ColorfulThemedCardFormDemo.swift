//
//  ColorfulThemedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Colorful theme demo with branded colors and gradients
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
            Text("Colorful Theme Demo")
                .font(.headline)
                .padding()
            
            Text("Branded colors with gradients")
                .font(.subheadline)
                .foregroundColor(.secondary)
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
        // Apply field customizations directly to the checkout scope
        setupCardFormFields(checkoutScope)
    }
    
    private func setupCardFormFields(_ checkoutScope: PrimerCheckoutScope) {
        // Get the card scope and apply our field customizations
        guard let cardScope = checkoutScope.getPaymentMethodScope(for: .paymentCard) as DefaultCardFormScope? else {
            return
        }
        
        setupFieldCustomizations(cardScope)
    }
    
    private func setupFieldCustomizations(_ cardScope: DefaultCardFormScope) {
        // Store original builders before customization
        let originalCardNumberBuilder = cardScope.cardNumberInput
        let originalExpiryDateBuilder = cardScope.expiryDateInput
        let originalCvvBuilder = cardScope.cvvInput
        let originalCardholderNameBuilder = cardScope.cardholderNameInput
        
        // Card Number Field with Pink/Purple theme
        cardScope.cardNumberInput = { modifier in
            let colorfulModifier = self.createPinkPurpleModifier(from: modifier)
            
            if let originalBuilder = originalCardNumberBuilder {
                return originalBuilder(colorfulModifier)
            }
            // Note: originalBuilder should always exist in production
            return AnyView(EmptyView())
        }
        
        // Expiry Date Field with Orange/Yellow theme
        cardScope.expiryDateInput = { modifier in
            let colorfulModifier = self.createOrangeYellowModifier(from: modifier)
            
            if let originalBuilder = originalExpiryDateBuilder {
                return originalBuilder(colorfulModifier)
            }
            // Note: originalBuilder should always exist in production
            return AnyView(EmptyView())
        }

        // CVV Field with Green/Blue theme
        cardScope.cvvInput = { modifier in
            let colorfulModifier = self.createGreenBlueModifier(from: modifier)
            
            if let originalBuilder = originalCvvBuilder {
                return originalBuilder(colorfulModifier)
            }
            // Note: originalBuilder should always exist in production
            return AnyView(EmptyView())
        }

        // Billing Address Section with colorful themes
        setupBillingAddressSection(cardScope)
    }
    
    private func setupBillingAddressSection(_ cardScope: DefaultCardFormScope) {
        
        // Store original builders before customization
        let originalFirstNameBuilder = cardScope.firstNameInput
        let originalLastNameBuilder = cardScope.lastNameInput
        let originalAddressLine1Builder = cardScope.addressLine1Input
        let originalAddressLine2Builder = cardScope.addressLine2Input
        let originalCityBuilder = cardScope.cityInput
        let originalStateBuilder = cardScope.stateInput
        let originalPostalCodeBuilder = cardScope.postalCodeInput
        let originalCountryBuilder = cardScope.countryInput
        
        // First Name Field with cyan/teal theme
        cardScope.firstNameInput = { modifier in
            let colorfulModifier = self.createCyanTealBillingModifier(from: modifier)
            
            if let originalBuilder = originalFirstNameBuilder {
                return originalBuilder(colorfulModifier)
            }
            // Note: originalBuilder should always exist in production
            return AnyView(EmptyView())
        }
        
        // Last Name Field with mint/green theme
        cardScope.lastNameInput = { modifier in
            let colorfulModifier = self.createMintGreenBillingModifier(from: modifier)
            
            if let originalBuilder = originalLastNameBuilder {
                return originalBuilder(colorfulModifier)
            }
            // Note: originalBuilder should always exist in production
            return AnyView(EmptyView())
        }
        
        // Address Line 1 Field with indigo/purple theme
        cardScope.addressLine1Input = { modifier in
            let colorfulModifier = self.createIndigoPurpleBillingModifier(from: modifier)
            
            if let originalBuilder = originalAddressLine1Builder {
                return originalBuilder(colorfulModifier)
            }
            // Note: originalBuilder should always exist in production
            return AnyView(EmptyView())
        }
        
        // Address Line 2 Field with red/pink theme
        cardScope.addressLine2Input = { modifier in
            let colorfulModifier = self.createRedPinkBillingModifier(from: modifier)
            
            if let originalBuilder = originalAddressLine2Builder {
                return originalBuilder(colorfulModifier)
            }
            // Note: originalBuilder should always exist in production
            return AnyView(EmptyView())
        }
        
        // City Field with yellow/orange theme
        cardScope.cityInput = { modifier in
            let colorfulModifier = self.createYellowOrangeBillingModifier(from: modifier)
            
            if let originalBuilder = originalCityBuilder {
                return originalBuilder(colorfulModifier)
            }
            // Note: originalBuilder should always exist in production
            return AnyView(EmptyView())
        }
        
        // State Field with gray/black theme
        cardScope.stateInput = { modifier in
            let colorfulModifier = self.createGrayBlackBillingModifier(from: modifier)
            
            if let originalBuilder = originalStateBuilder {
                return originalBuilder(colorfulModifier)
            }
            // Note: originalBuilder should always exist in production
            return AnyView(EmptyView())
        }
        
        // Postal Code Field with rainbow theme
        cardScope.postalCodeInput = { modifier in
            let colorfulModifier = self.createRainbowBillingAddressModifier(from: modifier)
            
            if let originalBuilder = originalPostalCodeBuilder {
                return originalBuilder(colorfulModifier)
            }
            // Note: originalBuilder should always exist in production
            return AnyView(EmptyView())
        }
        
        // Country Field with blue/purple theme
        cardScope.countryInput = { modifier in
            let colorfulModifier = self.createBluePurpleModifier(from: modifier)
            
            if let originalBuilder = originalCountryBuilder {
                return originalBuilder(colorfulModifier)
            }
            // Note: originalBuilder should always exist in production
            return AnyView(EmptyView())
        }
    }
    
    // MARK: - Modifier Creation Functions
    
    private func createPinkPurpleModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .backgroundGradient(
                Gradient(colors: [Color.pink.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .border(Color.pink, width: 2)
            .cornerRadius(12)
            .shadow(color: Color.pink.opacity(0.3), radius: 4, offsetX: 0, offsetY: 2)
            .padding(.horizontal, 2)
            .inputOnly()
    }
    
    private func createOrangeYellowModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .backgroundGradient(
                Gradient(colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.1)]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .border(Color.orange, width: 2)
            .cornerRadius(12)
            .shadow(color: Color.orange.opacity(0.3), radius: 4, offsetX: 0, offsetY: 2)
            .padding(.horizontal, 2)
            .inputOnly()
    }
    
    private func createGreenBlueModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .backgroundGradient(
                Gradient(colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .border(Color.green, width: 2)
            .cornerRadius(12)
            .shadow(color: Color.green.opacity(0.3), radius: 4, offsetX: 0, offsetY: 2)
            .padding(.horizontal, 2)
            .inputOnly()
    }
    
    private func createBluePurpleModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .backgroundGradient(
                Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .border(Color.blue, width: 2)
            .cornerRadius(12)
            .shadow(color: Color.blue.opacity(0.3), radius: 4, offsetX: 0, offsetY: 2)
            .padding(.horizontal, 2)
            .inputOnly()
    }
    
    // MARK: - Billing Address Modifier Creation Functions
    
    private func createCyanTealBillingModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .backgroundGradient(
                Gradient(colors: [Color.cyan.opacity(0.1), Color.teal.opacity(0.1)]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .border(Color.cyan, width: 2)
            .cornerRadius(12)
            .shadow(color: Color.cyan.opacity(0.3), radius: 4, offsetX: 0, offsetY: 2)
            .padding(.horizontal, 2)
            .inputOnly()
    }
    
    private func createMintGreenBillingModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .backgroundGradient(
                Gradient(colors: [Color.mint.opacity(0.1), Color.green.opacity(0.1)]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .border(Color.mint, width: 2)
            .cornerRadius(12)
            .shadow(color: Color.mint.opacity(0.3), radius: 4, offsetX: 0, offsetY: 2)
            .padding(.horizontal, 2)
            .inputOnly()
    }
    
    private func createIndigoPurpleBillingModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .backgroundGradient(
                Gradient(colors: [Color.indigo.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .border(Color.indigo, width: 2)
            .cornerRadius(12)
            .shadow(color: Color.indigo.opacity(0.3), radius: 4, offsetX: 0, offsetY: 2)
            .padding(.horizontal, 2)
            .inputOnly()
    }
    
    private func createRedPinkBillingModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .backgroundGradient(
                Gradient(colors: [Color.red.opacity(0.1), Color.pink.opacity(0.1)]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .border(Color.red, width: 2)
            .cornerRadius(12)
            .shadow(color: Color.red.opacity(0.3), radius: 4, offsetX: 0, offsetY: 2)
            .padding(.horizontal, 2)
            .inputOnly()
    }
    
    private func createYellowOrangeBillingModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .backgroundGradient(
                Gradient(colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.1)]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .border(Color.yellow, width: 2)
            .cornerRadius(12)
            .shadow(color: Color.yellow.opacity(0.3), radius: 4, offsetX: 0, offsetY: 2)
            .padding(.horizontal, 2)
            .inputOnly()
    }
    
    private func createGrayBlackBillingModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .backgroundGradient(
                Gradient(colors: [Color.gray.opacity(0.1), Color.black.opacity(0.05)]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .border(Color.gray, width: 2)
            .cornerRadius(12)
            .shadow(color: Color.gray.opacity(0.3), radius: 4, offsetX: 0, offsetY: 2)
            .padding(.horizontal, 2)
            .inputOnly()
    }

    /// Creates a rainbow-styled modifier for the entire billing address section
    /// This modifier will be passed to BillingAddressView and applied to all billing fields
    private func createRainbowBillingAddressModifier(from modifier: PrimerModifier) -> PrimerModifier {
        
        // Create a vibrant rainbow gradient modifier that will be applied to all billing address fields
        // BillingAddressView will pass this through its field-specific modifier creation functions
        return modifier
            .backgroundGradient(
                Gradient(colors: [
                    Color.red.opacity(0.08),
                    Color.orange.opacity(0.08),
                    Color.yellow.opacity(0.08),
                    Color.green.opacity(0.08),
                    Color.blue.opacity(0.08),
                    Color.purple.opacity(0.08)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .border(Color.purple, width: 2)
            .cornerRadius(12)
            .shadow(color: Color.purple.opacity(0.4), radius: 6, offsetX: 0, offsetY: 3)
            .padding(.horizontal, 2)
            .inputOnly() // Target input fields specifically for consistent styling
    }
    
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
