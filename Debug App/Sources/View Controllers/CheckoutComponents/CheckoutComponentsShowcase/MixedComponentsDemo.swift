//
//  MixedComponentsDemo.swift
//  Debug App
//
//  Created by Claude on 24.7.25.
//

import SwiftUI
import PrimerSDK

/// Demonstrates mixing default and custom components
@available(iOS 15.0, *)
struct MixedComponentsDemo: View {
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
            
            Text("Mixed components demo has been dismissed")
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
            Text("Mixed Default/Custom Components")
                .font(.headline)
                .padding()
            
            Text("Some fields use default styling while others are heavily customized")
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
                        .navigationBarTitle("Mixed Components", displayMode: .inline)
                }
            )
        }
        
        // Get the card form scope
        if let cardFormScope: DefaultCardFormScope = checkoutScope.getPaymentMethodScope(for: .paymentCard) {
            // Override the card form screen with mixed components demo
            cardFormScope.screen = { _ in
                AnyView(MixedStyleCardFormView(cardFormScope: cardFormScope))
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
            fatalError("No session configuration provided - MixedComponentsDemo requires configured session from main controller")
        }
        
        return configuredSession
    }
}

/// Card form view mixing default and custom components
@available(iOS 15.0, *)
private struct MixedStyleCardFormView: View {
    let cardFormScope: DefaultCardFormScope
    
    @State private var cardState: StructuredCardFormState?
    @State private var isCardFlipped = false
    @State private var showTooltip = false
    @State private var stateTask: Task<Void, Never>?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title with info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Payment Details")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Fields marked with * use custom styling")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        withAnimation(.spring()) {
                            showTooltip.toggle()
                        }
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                if showTooltip {
                    Text("This demo shows how to mix default Primer styling with custom components for specific fields")
                        .font(.caption)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
                
                // Card visualization (custom)
                CardVisualization(
                    cardNumber: cardState?.data[.cardNumber] ?? "",
                    expiryDate: cardState?.data[.expiryDate] ?? "",
                    cardholderName: cardState?.data[.cardholderName] ?? "",
                    isFlipped: $isCardFlipped
                )
                .padding(.horizontal)
                
                // Form fields
                VStack(spacing: 20) {
                    // Card number - Custom fancy style using real SDK component
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Card Number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        
                        // Real SDK card number field with custom fancy styling
                        CardNumberInputField(
                            scope: cardFormScope,
                            styling: PrimerFieldStyling(
                                textColor: .black,
                                backgroundColor: .clear,
                                borderColor: .clear,
                                cornerRadius: 12,
                                borderWidth: 0,
                                font: .system(size: 18, weight: .medium, design: .monospaced),
                                padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
                            )
                        )
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .cornerRadius(12)
                    }
                    
                    HStack(spacing: 16) {
                        // Expiry date - Default style using real SDK component
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Expiry Date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Real SDK expiry date field with default styling
                            ExpiryDateInputField(
                                scope: cardFormScope,
                                styling: PrimerFieldStyling(
                                    backgroundColor: Color.gray.opacity(0.1),
                                    borderColor: .clear,
                                    cornerRadius: 8,
                                    borderWidth: 0,
                                    padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
                                )
                            )
                            .frame(height: 50)
                        }
                        
                        // CVV - Custom interactive style using real SDK component
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("CVV")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            
                            HStack {
                                // Real SDK CVV field with custom interactive styling
                                CVVInputField(
                                    scope: cardFormScope,
                                    styling: PrimerFieldStyling(
                                        backgroundColor: Color.orange.opacity(0.1),
                                        borderColor: .clear,
                                        cornerRadius: 8,
                                        borderWidth: 0,
                                        font: .system(.body, design: .monospaced),
                                        padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
                                    )
                                )
                                .frame(height: 50)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        isCardFlipped = true
                                    }
                                }
                                
                                Button {
                                    withAnimation(.spring()) {
                                        isCardFlipped.toggle()
                                    }
                                } label: {
                                    Image(systemName: "creditcard.viewfinder")
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    
                    // Cardholder name - Default style using real SDK component
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cardholder Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Real SDK cardholder name field with default styling
                        CardholderNameInputField(
                            scope: cardFormScope,
                            styling: PrimerFieldStyling(
                                backgroundColor: Color.gray.opacity(0.1),
                                borderColor: .clear,
                                cornerRadius: 8,
                                borderWidth: 0,
                                padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
                            )
                        )
                        .frame(height: 50)
                    }
                }
                .padding()
                
                // Submit button - Custom animated style
                if let state = cardState {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Submit Button")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("*")
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            cardFormScope.onSubmit()
                        }) {
                            ZStack {
                                // Background animation
                                if state.isValid {
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.green, Color.blue],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .mask(
                                            RoundedRectangle(cornerRadius: 16)
                                        )
                                        .overlay(
                                            GeometryReader { geometry in
                                                Rectangle()
                                                    .fill(Color.white.opacity(0.3))
                                                    .frame(width: 100)
                                                    .offset(x: -100)
                                                    .rotationEffect(.degrees(-15))
                                                    .modifier(ShimmerEffect())
                                            }
                                            .mask(RoundedRectangle(cornerRadius: 16))
                                        )
                                }
                                
                                Text("Submit Payment")
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(state.isValid ? Color.clear : Color.gray.opacity(0.3))
                                    .cornerRadius(16)
                            }
                            .frame(height: 56)
                        }
                        .disabled(!state.isValid)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
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
                    }
                }
            }
        }
    }
    
}

/// Card visualization component
@available(iOS 15.0, *)
private struct CardVisualization: View {
    let cardNumber: String
    let expiryDate: String
    let cardholderName: String
    @Binding var isFlipped: Bool
    
    var body: some View {
        ZStack {
            // Card back
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.8))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Rectangle()
                            .fill(Color.black)
                            .frame(height: 40)
                            .padding(.top, 20)
                        
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 200, height: 30)
                            
                            Text("CVV")
                                .foregroundColor(.white)
                                .padding(.horizontal)
                        }
                        .padding()
                        
                        Spacer()
                    }
                )
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : 180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 1 : 0)
            
            // Card front
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 200)
                .overlay(
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("BANK")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        Text(formatCardNumber(cardNumber))
                            .font(.system(size: 22, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("EXPIRES")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(expiryDate.isEmpty ? "MM/YY" : expiryDate)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text(cardholderName.isEmpty ? "YOUR NAME" : cardholderName.uppercased())
                                    .font(.system(.body, design: .default))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                )
                .rotation3DEffect(
                    .degrees(isFlipped ? -180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 0 : 1)
        }
        .animation(.spring(), value: isFlipped)
    }
    
    private func formatCardNumber(_ number: String) -> String {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        if cleaned.isEmpty {
            return "•••• •••• •••• ••••"
        }
        
        var formatted = ""
        for (index, char) in cleaned.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(char)
        }
        
        // Pad with bullets
        let remaining = 16 - cleaned.count
        if remaining > 0 {
            let bullets = String(repeating: "•", count: remaining)
            var paddedBullets = ""
            for (index, char) in bullets.enumerated() {
                let adjustedIndex = cleaned.count + index
                if adjustedIndex > 0 && adjustedIndex % 4 == 0 {
                    paddedBullets += " "
                }
                paddedBullets += String(char)
            }
            formatted += paddedBullets
        }
        
        return formatted
    }
    
}

/// Shimmer effect modifier
@available(iOS 15.0, *)
private struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
            .offset(x: phase * 200)
    }
}
