//
//  DefaultPaymentSelectionScreen.swift
//  
//
//  Created on 17.06.2025.
//

import SwiftUI
import Combine

/// Default payment method selection screen with scope integration
@available(iOS 15.0, *)
internal struct DefaultPaymentSelectionScreen: View, LogReporter {
    
    // MARK: - Properties
    
    let scope: any PaymentMethodSelectionScope
    
    // MARK: - State
    
    @State private var paymentMethods: [PrimerComposablePaymentMethod] = []
    @State private var currency: Currency?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.designTokens) private var tokens
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                
                if isLoading {
                    loadingView
                } else if let errorMessage = errorMessage {
                    errorView(errorMessage)
                } else {
                    paymentMethodsList
                }
            }
            .background(tokens?.primerColorBackground ?? Color(.systemBackground))
        }
        .onAppear {
            setupStateBinding()
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 16) {
            Text("Select Payment Method")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(tokens?.primerColorText ?? .primary)
            
            if let currency = currency {
                Text("Currency: \(currency.code)")
                    .font(.subheadline)
                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
            }
        }
        .padding(.top, 24)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: tokens?.primerColorBrand ?? .blue))
                .scaleEffect(1.2)
            
            Text("Loading payment methods...")
                .font(.body)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Unable to Load Payment Methods")
                .font(.headline)
                .foregroundColor(tokens?.primerColorText ?? .primary)
            
            Text(message)
                .font(.body)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                // Retry logic would go here
                logger.debug(message: "🔄 [DefaultPaymentSelectionScreen] Retry button tapped")
            }
            .buttonStyle(.borderedProminent)
            .tint(tokens?.primerColorBrand ?? .blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    @ViewBuilder
    private var paymentMethodsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(paymentMethods) { paymentMethod in
                    PaymentMethodItemView(
                        paymentMethod: paymentMethod,
                        currency: currency,
                        onSelection: {
                            handlePaymentMethodSelection(paymentMethod)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupStateBinding() {
        logger.debug(message: "🔗 [DefaultPaymentSelectionScreen] Setting up state binding")
        
        scope.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self = self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func handleStateChange(_ state: PaymentMethodSelectionState) {
        logger.debug(message: "🔄 [DefaultPaymentSelectionScreen] State changed: \(state)")
        
        switch state {
        case .loading:
            isLoading = true
            errorMessage = nil
        case .ready(let methods, let curr):
            paymentMethods = methods
            currency = curr
            isLoading = false
            errorMessage = nil
            logger.info(message: "✅ [DefaultPaymentSelectionScreen] Loaded \(methods.count) payment methods")
        case .error(let error):
            isLoading = false
            errorMessage = error
            logger.error(message: "❌ [DefaultPaymentSelectionScreen] Error: \(error)")
        }
    }
    
    private func handlePaymentMethodSelection(_ paymentMethod: PrimerComposablePaymentMethod) {
        logger.info(message: "💳 [DefaultPaymentSelectionScreen] Payment method selected: \(paymentMethod.paymentMethodType)")
        scope.onPaymentMethodSelected(paymentMethod)
    }
}

// MARK: - Payment Method Item View

@available(iOS 15.0, *)
private struct PaymentMethodItemView: View {
    
    let paymentMethod: PrimerComposablePaymentMethod
    let currency: Currency?
    let onSelection: () -> Void
    
    @Environment(\.designTokens) private var tokens
    
    var body: some View {
        Button(action: onSelection) {
            HStack(spacing: 16) {
                // Payment method icon
                Image(systemName: paymentMethodIcon)
                    .font(.system(size: 24))
                    .foregroundColor(tokens?.primerColorBrand ?? .blue)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill((tokens?.primerColorBrand ?? .blue).opacity(0.1))
                    )
                
                // Payment method details
                VStack(alignment: .leading, spacing: 4) {
                    Text(paymentMethod.name)
                        .font(.headline)
                        .foregroundColor(tokens?.primerColorText ?? .primary)
                        .multilineTextAlignment(.leading)
                    
                    if let description = paymentMethod.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(tokens?.primerColorSurface ?? Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(tokens?.primerColorBorder ?? Color(.separator), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var paymentMethodIcon: String {
        switch paymentMethod.paymentMethodType {
        case "PAYMENT_CARD":
            return "creditcard"
        case "PAYPAL":
            return "p.circle"
        case "APPLE_PAY":
            return "applelogo"
        default:
            return "dollarsign.circle"
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, *)
struct DefaultPaymentSelectionScreen_Previews: PreviewProvider {
    static var previews: some View {
        DefaultPaymentSelectionScreen(scope: MockPaymentMethodSelectionScope())
    }
}

// MARK: - Mock Scope for Preview

@available(iOS 15.0, *)
private class MockPaymentMethodSelectionScope: PaymentMethodSelectionScope, ObservableObject {
    @Published private var _state: PaymentMethodSelectionState = .ready(
        paymentMethods: [
            PrimerComposablePaymentMethod(
                paymentMethodType: "PAYMENT_CARD",
                name: "Credit or Debit Card",
                description: "Pay with Visa, Mastercard, or American Express",
                surcharge: nil
            ),
            PrimerComposablePaymentMethod(
                paymentMethodType: "PAYPAL",
                name: "PayPal",
                description: "Pay with your PayPal account",
                surcharge: nil
            )
        ],
        currency: Currency(code: "USD", decimalDigits: 2)
    )
    
    var state: AnyPublisher<PaymentMethodSelectionState, Never> {
        $_state.eraseToAnyPublisher()
    }
    
    func onPaymentMethodSelected(_ paymentMethod: PrimerComposablePaymentMethod) {
        // Mock implementation
    }
}