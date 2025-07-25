//
//  CustomCardFormLayoutDemo.swift
//  Debug App
//
//  Created by Claude on 24.7.25.
//

import SwiftUI
import PrimerSDK

/// Demonstrates dynamic card form layouts
@available(iOS 15.0, *)
struct CustomCardFormLayoutDemo: View {
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
            
            Text("Dynamic layouts demo has been dismissed")
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
            Text("Dynamic Card Form Layouts")
                .font(.headline)
                .padding()
            
            Text("Switch between different layout arrangements at runtime")
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
                        .navigationBarTitle("Dynamic Layouts", displayMode: .inline)
                }
            )
        }
        
        // Get the card form scope
        if let cardFormScope: DefaultCardFormScope = checkoutScope.getPaymentMethodScope(for: .paymentCard) {
            // Override the card form screen with dynamic layout options
            cardFormScope.screen = { _ in
                AnyView(DynamicLayoutCardFormView(cardFormScope: cardFormScope))
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
            fatalError("No session configuration provided - CustomCardFormLayoutDemo requires configured session from main controller")
        }
        
        return configuredSession
    }
}

/// Layout options for the demo
@available(iOS 15.0, *)
private enum CardFormLayout: String, CaseIterable {
    case vertical = "Vertical"
    case horizontal = "Horizontal"
    case grid = "Grid 2x2"
    case compact = "Compact"
}


/// Custom card form view with dynamic layout switching
@available(iOS 15.0, *)
private struct DynamicLayoutCardFormView: View {
    let cardFormScope: DefaultCardFormScope
    
    @State private var selectedLayout: CardFormLayout = .vertical
    @State private var cardState: StructuredCardFormState?
    @State private var stateTask: Task<Void, Never>?
    
    var body: some View {
        VStack(spacing: 0) {
            // Layout selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CardFormLayout.allCases, id: \.self) { layout in
                        Button {
                            selectedLayout = layout
                        } label: {
                            Text(layout.rawValue)
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedLayout == layout ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedLayout == layout ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding()
            }
            .background(Color.gray.opacity(0.05))
            
            ScrollView {
                VStack(spacing: 20) {
                    // Dynamic layout content
                    Group {
                        switch selectedLayout {
                        case .vertical:
                            verticalLayout
                        case .horizontal:
                            horizontalLayout
                        case .grid:
                            gridLayout
                        case .compact:
                            compactLayout
                        }
                    }
                    .padding()
                    
                    // Submit button
                    if let state = cardState {
                        Button(action: {
                            cardFormScope.onSubmit()
                        }) {
                            Text("Submit Payment")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(state.isValid ? Color.green : Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(!state.isValid)
                        .padding(.horizontal)
                    }
                }
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
    
    @ViewBuilder
    private var verticalLayout: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Card Number")
                    .font(.caption)
                    .foregroundColor(.secondary)
                // Mock card number field
                mockLayoutField(
                    placeholder: "1234 5678 9012 3456",
                    styling: PrimerFieldStyling(
                        backgroundColor: Color.blue.opacity(0.05),
                        borderColor: .blue,
                        cornerRadius: 8,
                        borderWidth: 1
                    )
                )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Expiry Date")
                    .font(.caption)
                    .foregroundColor(.secondary)
                // Mock expiry date field
                mockLayoutField(
                    placeholder: "MM/YY",
                    styling: PrimerFieldStyling(
                        backgroundColor: Color.green.opacity(0.05),
                        borderColor: .green,
                        cornerRadius: 8,
                        borderWidth: 1
                    )
                )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("CVV")
                    .font(.caption)
                    .foregroundColor(.secondary)
                // Mock CVV field
                mockLayoutField(
                    placeholder: "123",
                    styling: PrimerFieldStyling(
                        backgroundColor: Color.orange.opacity(0.05),
                        borderColor: .orange,
                        cornerRadius: 8,
                        borderWidth: 1
                    )
                )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Cardholder Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                // Mock cardholder name field
                mockLayoutField(
                    placeholder: "John Smith",
                    styling: PrimerFieldStyling(
                        backgroundColor: Color.purple.opacity(0.05),
                        borderColor: .purple,
                        cornerRadius: 8,
                        borderWidth: 1
                    )
                )
            }
        }
    }
    
    @ViewBuilder
    private var horizontalLayout: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Card Number")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    // Mock card number field
                    mockLayoutField(
                        placeholder: "1234 5678 9012 3456",
                        styling: PrimerFieldStyling(
                            backgroundColor: Color.blue.opacity(0.05),
                            borderColor: .blue,
                            cornerRadius: 8,
                            borderWidth: 1
                        )
                    )
                    .frame(width: 200)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expiry")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    // Mock expiry date field
                    mockLayoutField(
                        placeholder: "MM/YY",
                        styling: PrimerFieldStyling(
                            backgroundColor: Color.green.opacity(0.05),
                            borderColor: .green,
                            cornerRadius: 8,
                            borderWidth: 1
                        )
                    )
                    .frame(width: 100)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("CVV")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    // Mock CVV field
                    mockLayoutField(
                        placeholder: "123",
                        styling: PrimerFieldStyling(
                            backgroundColor: Color.orange.opacity(0.05),
                            borderColor: .orange,
                            cornerRadius: 8,
                            borderWidth: 1
                        )
                    )
                    .frame(width: 80)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    // Mock cardholder name field
                    mockLayoutField(
                        placeholder: "John Smith",
                        styling: PrimerFieldStyling(
                            backgroundColor: Color.purple.opacity(0.05),
                            borderColor: .purple,
                            cornerRadius: 8,
                            borderWidth: 1
                        )
                    )
                    .frame(width: 150)
                }
            }
        }
    }
    
    @ViewBuilder
    private var gridLayout: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Card Number")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    // Mock card number field
                    mockLayoutField(
                        placeholder: "1234 5678 9012 3456",
                        styling: PrimerFieldStyling(
                            backgroundColor: Color.blue.opacity(0.05),
                            borderColor: .blue,
                            cornerRadius: 8,
                            borderWidth: 1
                        )
                    )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expiry")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    // Mock expiry date field
                    mockLayoutField(
                        placeholder: "MM/YY",
                        styling: PrimerFieldStyling(
                            backgroundColor: Color.green.opacity(0.05),
                            borderColor: .green,
                            cornerRadius: 8,
                            borderWidth: 1
                        )
                    )
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CVV")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    // Mock CVV field
                    mockLayoutField(
                        placeholder: "123",
                        styling: PrimerFieldStyling(
                            backgroundColor: Color.orange.opacity(0.05),
                            borderColor: .orange,
                            cornerRadius: 8,
                            borderWidth: 1
                        )
                    )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cardholder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    // Mock cardholder name field
                    mockLayoutField(
                        placeholder: "John Smith",
                        styling: PrimerFieldStyling(
                            backgroundColor: Color.purple.opacity(0.05),
                            borderColor: .purple,
                            cornerRadius: 8,
                            borderWidth: 1
                        )
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var compactLayout: some View {
        VStack(spacing: 12) {
            // Mock card number field
            mockLayoutField(
                placeholder: "1234 5678 9012 3456",
                label: "Card Number",
                styling: PrimerFieldStyling(
                    backgroundColor: Color.blue.opacity(0.05),
                    borderColor: .blue,
                    cornerRadius: 8,
                    borderWidth: 1,
                    padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
                )
            )
            
            HStack(spacing: 12) {
                // Mock expiry date field
                mockLayoutField(
                    placeholder: "MM/YY",
                    label: "Expiry",
                    styling: PrimerFieldStyling(
                        backgroundColor: Color.green.opacity(0.05),
                        borderColor: .green,
                        cornerRadius: 8,
                        borderWidth: 1,
                        padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
                    )
                )
                
                // Mock CVV field
                mockLayoutField(
                    placeholder: "123",
                    label: "CVV",
                    styling: PrimerFieldStyling(
                        backgroundColor: Color.orange.opacity(0.05),
                        borderColor: .orange,
                        cornerRadius: 8,
                        borderWidth: 1,
                        padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
                    )
                )
            }
            
            // Mock cardholder name field
            mockLayoutField(
                placeholder: "John Smith",
                label: "Cardholder Name",
                styling: PrimerFieldStyling(
                    backgroundColor: Color.purple.opacity(0.05),
                    borderColor: .purple,
                    cornerRadius: 8,
                    borderWidth: 1,
                    padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
                )
            )
        }
    }
    
    @ViewBuilder
    private func mockLayoutField(placeholder: String, label: String? = nil, styling: PrimerFieldStyling?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label = label, !label.isEmpty {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            let effectiveStyling = styling ?? PrimerFieldStyling()
            
            ZStack {
                RoundedRectangle(cornerRadius: effectiveStyling.cornerRadius ?? 8)
                    .fill(effectiveStyling.backgroundColor ?? Color.gray.opacity(0.05))
                    .frame(height: 50)
                RoundedRectangle(cornerRadius: effectiveStyling.cornerRadius ?? 8)
                    .stroke(effectiveStyling.borderColor ?? Color.gray.opacity(0.3), lineWidth: effectiveStyling.borderWidth ?? 1)
                    .frame(height: 50)
                Text(placeholder)
                    .foregroundColor(effectiveStyling.placeholderColor?.opacity(0.5) ?? Color.gray.opacity(0.5))
                    .padding(.horizontal, effectiveStyling.padding?.leading ?? 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
