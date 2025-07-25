//
//  SingleInputFieldDemo.swift
//  Debug App
//
//  Created by Claude on 24.7.25.
//

import SwiftUI
import PrimerSDK

/// Demonstrates single input field at a time with step-by-step navigation
@available(iOS 15.0, *)
struct SingleInputFieldDemo: View {
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
            
            Text("Step-by-step navigation demo has been dismissed")
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
            Text("Step-by-Step Navigation")
                .font(.headline)
                .padding()
            
            Text("Shows one input field at a time with Previous/Next navigation controls")
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
                        .navigationBarTitle("Step-by-Step Card Form", displayMode: .inline)
                }
            )
        }
        
        // Get the card form scope
        if let cardFormScope: DefaultCardFormScope = checkoutScope.getPaymentMethodScope(for: .paymentCard) {
            // Override the card form screen with step-by-step navigation
            cardFormScope.screen = { _ in
                AnyView(SingleInputFieldCardFormView(cardFormScope: cardFormScope))
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
            fatalError("No session configuration provided - SingleInputFieldDemo requires configured session from main controller")
        }
        
        return configuredSession
    }
}

/// Custom card form view showing one field at a time using real SDK components
@available(iOS 15.0, *)
private struct SingleInputFieldCardFormView: View {
    let cardFormScope: DefaultCardFormScope
    
    @State private var currentFieldIndex = 0
    @State private var cardState: StructuredCardFormState?
    @State private var stateTask: Task<Void, Never>?
    
    var body: some View {
        VStack(spacing: 0) {
            if let state = cardState {
                // Progress indicator
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ForEach(0..<totalFieldCount, id: \.self) { index in
                            Circle()
                                .fill(index == currentFieldIndex ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text("Step \(currentFieldIndex + 1) of \(totalFieldCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Current field container
                VStack(spacing: 24) {
                    // Display only the current field using real SDK components
                    VStack(alignment: .leading, spacing: 12) {
                        currentFieldTitle
                        currentFieldView
                    }
                    .frame(height: 120, alignment: .top)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Navigation controls
                    HStack(spacing: 20) {
                        Button {
                            if currentFieldIndex > 0 {
                                currentFieldIndex -= 1
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .frame(width: 60, height: 60)
                                .background(currentFieldIndex > 0 ? Color.blue : Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .disabled(currentFieldIndex == 0)
                        
                        Spacer()
                        
                        if currentFieldIndex < totalFieldCount - 1 {
                            Button {
                                currentFieldIndex += 1
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .frame(width: 60, height: 60)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                        } else {
                            // Submit button on last field
                            Button {
                                cardFormScope.onSubmit()
                            } label: {
                                HStack {
                                    Text("Submit")
                                    Image(systemName: "checkmark")
                                }
                                .font(.headline)
                                .frame(height: 60)
                                .frame(maxWidth: .infinity)
                                .background(state.isValid ? Color.green : Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(30)
                            }
                            .disabled(!state.isValid)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            } else {
                ProgressView()
            }
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
    
    private var totalFieldCount: Int {
        // Basic fields: card number, expiry, cvv, cardholder
        4
    }
    
    @ViewBuilder
    private var currentFieldTitle: some View {
        switch currentFieldIndex {
        case 0:
            Text("Card Number")
                .font(.headline)
                .foregroundColor(.blue)
        case 1:
            Text("Expiry Date")
                .font(.headline)
                .foregroundColor(.green)
        case 2:
            Text("CVV")
                .font(.headline)
                .foregroundColor(.orange)
        case 3:
            Text("Cardholder Name")
                .font(.headline)
                .foregroundColor(.purple)
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var currentFieldView: some View {
        switch currentFieldIndex {
        case 0:
            // Real card number field from SDK with step-specific styling
            CardNumberInputField(
                scope: cardFormScope,
                styling: PrimerFieldStyling(
                    backgroundColor: Color.blue.opacity(0.05),
                    borderColor: .blue,
                    focusedBorderColor: .blue,
                    cornerRadius: 8,
                    borderWidth: 2,
                    padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
                )
            )
            .frame(height: 50)
        case 1:
            // Real expiry date field from SDK with step-specific styling
            ExpiryDateInputField(
                scope: cardFormScope,
                styling: PrimerFieldStyling(
                    backgroundColor: Color.green.opacity(0.05),
                    borderColor: .green,
                    focusedBorderColor: .green,
                    cornerRadius: 8,
                    borderWidth: 2,
                    padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
                )
            )
            .frame(height: 50)
        case 2:
            // Real CVV field from SDK with step-specific styling
            CVVInputField(
                scope: cardFormScope,
                styling: PrimerFieldStyling(
                    backgroundColor: Color.orange.opacity(0.05),
                    borderColor: .orange,
                    focusedBorderColor: .orange,
                    cornerRadius: 8,
                    borderWidth: 2,
                    padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
                )
            )
            .frame(height: 50)
        case 3:
            // Real cardholder name field from SDK with step-specific styling
            CardholderNameInputField(
                scope: cardFormScope,
                styling: PrimerFieldStyling(
                    backgroundColor: Color.purple.opacity(0.05),
                    borderColor: .purple,
                    focusedBorderColor: .purple,
                    cornerRadius: 8,
                    borderWidth: 2,
                    padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
                )
            )
            .frame(height: 50)
        default:
            EmptyView()
        }
    }
}
