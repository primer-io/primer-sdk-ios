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

        // CVV Field with Green/Blue theme - EXAMPLE: Multiple ModifierTarget usage
        cardScope.cvvInput = { modifier in
            let colorfulModifier = self.createGreenBlueModifierWithMultipleTargets(from: modifier)
            
            if let originalBuilder = originalCvvBuilder {
                return originalBuilder(colorfulModifier)
            }
            // Note: originalBuilder should always exist in production
            return AnyView(EmptyView())
        }

        // Cardholder Name Field with Blue/Purple theme
        cardScope.cardholderNameInput = { modifier in
            let colorfulModifier = self.createBluePurpleModifier(from: modifier)
            
            if let originalBuilder = originalCardholderNameBuilder {
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
    
    /// SOLUTION: Proper Modifier Hierarchy Implementation
    /// 
    /// Previous issue: Components were hardcoded to use design tokens (tokens?.primerRadiusMedium ?? 8)
    /// and completely ignored PrimerModifier settings, causing conflicts.
    /// 
    /// IMPROVED SOLUTION: Implemented proper value hierarchy in CardNumberInputField:
    /// 1. **PrimerModifier values** (highest priority - developer's explicit styling)
    /// 2. **Design tokens** (merchant settings - fallback when no modifier set)  
    /// 3. **Default values** (lowest priority - final fallback)
    /// 
    /// The component now uses `effectiveCornerRadius` computed property that:
    /// - Extracts cornerRadius from PrimerModifier chain if set
    /// - Falls back to design tokens (merchant's setting like 17)
    /// - Finally defaults to 8 if nothing is set
    /// 
    /// This means:
    /// - If developer sets .cornerRadius(25) in modifier → UI uses 25
    /// - If no modifier but merchant sets tokens to 17 → UI uses 17  
    /// - If neither set → UI uses default 8
    /// 
    /// Now our modifiers can safely use .cornerRadius() and they will be properly respected!
    
    /// Creates enhanced modifiers that work with design tokens for dramatic visual impact
    /// These modifiers will complement the merchant's corner radius settings instead of overriding them
    /// Card Number: Premium blue gradient with sophisticated styling
    private func createPinkPurpleModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .fillMaxWidth()
            .height(54)
            .backgroundGradient(
                Gradient(colors: [
                    Color.blue.opacity(0.15),
                    Color.indigo.opacity(0.12),
                    Color.blue.opacity(0.10)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .foregroundColor(.primary)
            .font(.system(size: 18, weight: .medium))
            .border(Color.blue.opacity(0.3), width: 1.5)
            .cornerRadius(12)
            .padding(.all, 12)
            .margin(.vertical, 6)
            .opacity(1.0)
            .animation(.easeInOut(duration: 0.2))
            .inputOnly()
    }
    
    /// Expiry Date: Professional orange gradient with refined styling
    private func createOrangeYellowModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .width(160)
            .height(54)
            .backgroundGradient(
                Gradient(colors: [
                    Color.orange.opacity(0.12),
                    Color.yellow.opacity(0.10),
                    Color.orange.opacity(0.08)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .foregroundColor(.primary)
            .font(.system(size: 16, weight: .medium))
            .border(Color.orange.opacity(0.25), width: 1.5)
            .cornerRadius(12)
            .padding(.all, 12)
            .margin(.vertical, 6)
            .opacity(1.0)
            .animation(.easeInOut(duration: 0.2))
            .inputOnly()
    }
    
    /// CVV: Professional teal gradient with compact styling
    private func createGreenBlueModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .size(width: 120, height: 54)
            .backgroundGradient(
                Gradient(colors: [
                    Color.teal.opacity(0.15), 
                    Color.mint.opacity(0.12), 
                    Color.teal.opacity(0.10)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .foregroundColor(.primary)
            .font(.system(size: 16, weight: .medium))
            .border(Color.teal.opacity(0.3), width: 1.5)
            .cornerRadius(12)
            .padding(.all, 12)
            .margin(.vertical, 6)
            .opacity(1.0)
            .animation(.easeInOut(duration: 0.2))
            .inputOnly()
    }
    
    /// EXAMPLE: CVV Field with Comprehensive Modifier Styling
    /// This demonstrates the CORRECT way to create modifiers for multiple targets:
    /// 
    /// ❌ WRONG: Chaining .container().inputOnly().labelOnly() overwrites targets
    /// ✅ CORRECT: Create ONE modifier with ALL styling - let components apply to appropriate targets
    /// 
    /// The input field component will automatically apply this modifier to:
    /// - .container target: Gets padding, margin, background (container styling)
    /// - .inputOnly target: Gets size, gradient, border (input styling) 
    /// - .labelOnly target: Gets font, color (label styling)
    private func createGreenBlueModifierWithMultipleTargets(from modifier: PrimerModifier) -> PrimerModifier {
        // FIXED: Due to broken PrimerModifier targeting system, we can only reliably
        // apply ONE type of styling per modifier. Creating label-only modifier.
        return modifier
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.red)  // Very visible red color for debugging
    }
    
    /// Cardholder Name: Professional purple gradient with sophisticated styling  
    /// ALTERNATIVE APPROACH: Create separate target-specific modifiers (advanced usage)
    private func createBluePurpleModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .fillMaxWidth()
            .height(54)
            .backgroundGradient(
                Gradient(colors: [
                    Color.purple.opacity(0.12), 
                    Color.indigo.opacity(0.10), 
                    Color.purple.opacity(0.08)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .foregroundColor(.primary)
            .font(.system(size: 16, weight: .medium))
            .border(Color.purple.opacity(0.25), width: 1.5)
            .cornerRadius(12)
            .padding(.all, 12)
            .margin(.vertical, 6)
            .opacity(1.0)
            .animation(.easeInOut(duration: 0.2))
            .inputOnly()
    }

    // MARK: - Billing Address Modifier Creation Functions

    /// First Name: Professional cyan gradient with clean styling
    private func createCyanTealBillingModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .fillMaxWidth()
            .height(48)
            .backgroundGradient(
                Gradient(colors: [
                    Color.cyan.opacity(0.10), 
                    Color.teal.opacity(0.08), 
                    Color.cyan.opacity(0.06)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .foregroundColor(.primary)
            .font(.system(size: 15, weight: .medium))
            .border(Color.cyan.opacity(0.25), width: 1)
            .cornerRadius(10)
            .padding(.all, 10)
            .margin(.vertical, 4)
            .opacity(1.0)
            .animation(.easeInOut(duration: 0.15))
            .inputOnly()
    }
    
    /// Last Name: Professional mint gradient with refined styling
    private func createMintGreenBillingModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .fillMaxWidth()
            .height(48)
            .backgroundGradient(
                Gradient(colors: [
                    Color.mint.opacity(0.10), 
                    Color.green.opacity(0.08), 
                    Color.mint.opacity(0.06)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .foregroundColor(.primary)
            .font(.system(size: 15, weight: .medium))
            .border(Color.mint.opacity(0.25), width: 1)
            .cornerRadius(10)
            .padding(.all, 10)
            .margin(.vertical, 4)
            .opacity(1.0)
            .animation(.easeInOut(duration: 0.15))
            .inputOnly()
    }
    
    /// Address Line 1: Professional indigo gradient with elegant styling
    private func createIndigoPurpleBillingModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .fillMaxWidth()
            .height(48)
            .backgroundGradient(
                Gradient(colors: [
                    Color.indigo.opacity(0.10), 
                    Color.purple.opacity(0.08), 
                    Color.indigo.opacity(0.06)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .foregroundColor(.primary)
            .font(.system(size: 15, weight: .medium))
            .border(Color.indigo.opacity(0.25), width: 1)
            .cornerRadius(10)
            .padding(.all, 10)
            .margin(.vertical, 4)
            .opacity(1.0)
            .animation(.easeInOut(duration: 0.15))
            .inputOnly()
    }
    
    /// Address Line 2: Professional pink gradient with subtle styling
    private func createRedPinkBillingModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .fillMaxWidth()
            .height(48)
            .backgroundGradient(
                Gradient(colors: [
                    Color.pink.opacity(0.10), 
                    Color.red.opacity(0.08), 
                    Color.pink.opacity(0.06)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .foregroundColor(.primary)
            .font(.system(size: 15, weight: .medium))
            .border(Color.pink.opacity(0.25), width: 1)
            .cornerRadius(10)
            .padding(.all, 10)
            .margin(.vertical, 4)
            .opacity(1.0)
            .animation(.easeInOut(duration: 0.15))
            .inputOnly()
    }
    
    /// City: Professional yellow gradient with warm styling
    private func createYellowOrangeBillingModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .fillMaxWidth()
            .height(48)
            .backgroundGradient(
                Gradient(colors: [
                    Color.yellow.opacity(0.12), 
                    Color.orange.opacity(0.10), 
                    Color.yellow.opacity(0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .foregroundColor(.primary)
            .font(.system(size: 15, weight: .medium))
            .border(Color.yellow.opacity(0.30), width: 1)
            .cornerRadius(10)
            .padding(.all, 10)
            .margin(.vertical, 4)
            .opacity(1.0)
            .animation(.easeInOut(duration: 0.15))
            .inputOnly()
    }
    
    /// State: Professional gray gradient with neutral styling
    private func createGrayBlackBillingModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .fillMaxWidth()
            .height(48)
            .backgroundGradient(
                Gradient(colors: [
                    Color.gray.opacity(0.08), 
                    Color.secondary.opacity(0.06), 
                    Color.gray.opacity(0.04)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .foregroundColor(.primary)
            .font(.system(size: 15, weight: .medium))
            .border(Color.gray.opacity(0.20), width: 1)
            .cornerRadius(10)
            .padding(.all, 10)
            .margin(.vertical, 4)
            .opacity(1.0)
            .animation(.easeInOut(duration: 0.15))
            .inputOnly()
    }

    /// Postal Code: Professional rainbow gradient with sophisticated styling
    /// This modifier demonstrates comprehensive modifier usage including multi-color gradients
    private func createRainbowBillingAddressModifier(from modifier: PrimerModifier) -> PrimerModifier {
        return modifier
            .fillMaxWidth()
            .height(48)
            .backgroundGradient(
                Gradient(colors: [
                    Color.red.opacity(0.08),
                    Color.orange.opacity(0.06),
                    Color.yellow.opacity(0.08),
                    Color.green.opacity(0.06),
                    Color.blue.opacity(0.08),
                    Color.purple.opacity(0.06)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .foregroundColor(.primary)
            .font(.system(size: 15, weight: .medium))
            .border(Color.purple.opacity(0.25), width: 1)
            .cornerRadius(10)
            .padding(.all, 10)
            .margin(.vertical, 4)
            .opacity(1.0)
            .animation(.easeInOut(duration: 0.15))
            .inputOnly()
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
