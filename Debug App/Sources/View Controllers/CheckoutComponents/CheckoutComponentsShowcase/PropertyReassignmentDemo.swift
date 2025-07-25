//
//  PropertyReassignmentDemo.swift
//  Debug App
//
//  Created by Claude on 24.7.25.
//

import SwiftUI
import PrimerSDK

/// Demonstrates runtime property reassignment and dynamic customization
@available(iOS 15.0, *)
struct PropertyReassignmentDemo: View {
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
            
            Text("Property reassignment demo has been dismissed")
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
            Text("Runtime Property Reassignment")
                .font(.headline)
                .padding()
            
            Text("Dynamically change component properties based on user actions")
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
                        .navigationBarTitle("Property Reassignment", displayMode: .inline)
                }
            )
        }
        
        // Get the card form scope
        if let cardFormScope: DefaultCardFormScope = checkoutScope.getPaymentMethodScope(for: .paymentCard) {
            // Override the card form screen with property reassignment demo
            cardFormScope.screen = { _ in
                AnyView(DynamicPropertiesCardFormView(cardFormScope: cardFormScope))
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
            fatalError("No session configuration provided - PropertyReassignmentDemo requires configured session from main controller")
        }
        
        return configuredSession
    }
}

/// Card form view with dynamic property changes
@available(iOS 15.0, *)
private struct DynamicPropertiesCardFormView: View {
    let cardFormScope: DefaultCardFormScope
    
    @State private var cardState: StructuredCardFormState?
    @State private var isDarkMode = false
    @State private var showLabels = true
    @State private var fieldStyle: FieldStyle = .rounded
    @State private var fieldSpacing: CGFloat = 16
    @State private var stateTask: Task<Void, Never>?
    
    enum FieldStyle: String, CaseIterable {
        case rounded = "Rounded"
        case plain = "Plain"
        case bordered = "Bordered"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Control panel
                VStack(spacing: 16) {
                    Text("Runtime Controls")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Toggle("Dark Mode", isOn: $isDarkMode)
                    
                    Toggle("Show Labels", isOn: $showLabels)
                    
                    HStack {
                        Text("Field Style:")
                        Spacer()
                        Picker("Style", selection: $fieldStyle) {
                            ForEach(FieldStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Field Spacing: \(Int(fieldSpacing))pt")
                            .font(.caption)
                        Slider(value: $fieldSpacing, in: 8...32, step: 4)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Card form with dynamic properties using real SDK fields
                VStack(spacing: fieldSpacing) {
                    fieldWrapper(label: "Card Number") {
                        // Mock card number field
                        mockInputField(
                            placeholder: "1234 5678 9012 3456",
                            label: showLabels ? nil : "Card Number"
                        )
                    }
                    
                    HStack(spacing: fieldSpacing) {
                        fieldWrapper(label: "Expiry") {
                            // Mock expiry date field
                            mockInputField(
                                placeholder: "MM/YY",
                                label: showLabels ? nil : "Expiry"
                            )
                        }
                        
                        fieldWrapper(label: "CVV") {
                            // Mock CVV field
                            mockInputField(
                                placeholder: "123",
                                label: showLabels ? nil : "CVV"
                            )
                        }
                    }
                    
                    fieldWrapper(label: "Cardholder Name") {
                        // Mock cardholder name field
                        mockInputField(
                            placeholder: "John Smith",
                            label: showLabels ? nil : "Cardholder Name"
                        )
                    }
                }
                .padding()
                .background(isDarkMode ? Color.black : Color.white)
                .cornerRadius(16)
                .shadow(radius: isDarkMode ? 0 : 4)
                
                // Submit button
                if let state = cardState {
                    Button(action: {
                        cardFormScope.onSubmit()
                    }) {
                        Text("Submit Payment")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(state.isValid ? (isDarkMode ? Color.green.opacity(0.8) : Color.green) : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(fieldStyle == .rounded ? 25 : 8)
                    }
                    .disabled(!state.isValid)
                }
            }
            .padding()
        }
        .background(isDarkMode ? Color.black.opacity(0.9) : Color(.systemBackground))
        .preferredColorScheme(isDarkMode ? .dark : .light)
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
    
    @ViewBuilder
    private func fieldWrapper<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        if showLabels {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(isDarkMode ? .white.opacity(0.7) : .secondary)
                content()
            }
        } else {
            content()
        }
    }
    
    /// Creates dynamic field styling based on current UI state
    private func dynamicFieldStyling() -> PrimerFieldStyling {
        switch fieldStyle {
        case .rounded:
            return PrimerFieldStyling(
                textColor: isDarkMode ? .white : .primary,
                backgroundColor: isDarkMode ? Color.white.opacity(0.1) : Color.gray.opacity(0.1),
                borderColor: .clear,
                cornerRadius: 8,
                borderWidth: 0,
                padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
            )
        case .plain:
            return PrimerFieldStyling(
                textColor: isDarkMode ? .white : .primary,
                backgroundColor: isDarkMode ? Color.white.opacity(0.05) : Color.gray.opacity(0.05),
                borderColor: .clear,
                cornerRadius: 4,
                borderWidth: 0,
                padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
            )
        case .bordered:
            return PrimerFieldStyling(
                textColor: isDarkMode ? .white : .primary,
                backgroundColor: .clear,
                borderColor: isDarkMode ? Color.white.opacity(0.3) : Color.gray.opacity(0.5),
                focusedBorderColor: isDarkMode ? Color.blue.opacity(0.8) : .blue,
                cornerRadius: 8,
                borderWidth: 1,
                padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
            )
        }
    }
    
    @ViewBuilder
    private func mockInputField(placeholder: String, label: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label = label, !label.isEmpty {
                Text(label)
                    .font(.caption)
                    .foregroundColor(isDarkMode ? .white.opacity(0.7) : .black.opacity(0.7))
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: dynamicFieldStyling().cornerRadius ?? 8)
                    .fill(dynamicFieldStyling().backgroundColor ?? .clear)
                    .frame(height: 50)
                RoundedRectangle(cornerRadius: dynamicFieldStyling().cornerRadius ?? 8)
                    .stroke(dynamicFieldStyling().borderColor ?? .gray.opacity(0.5), lineWidth: dynamicFieldStyling().borderWidth ?? 1)
                    .frame(height: 50)
                Text(placeholder)
                    .foregroundColor((dynamicFieldStyling().placeholderColor ?? dynamicFieldStyling().textColor ?? .gray).opacity(0.5))
                    .padding(.horizontal, dynamicFieldStyling().padding?.leading ?? 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
