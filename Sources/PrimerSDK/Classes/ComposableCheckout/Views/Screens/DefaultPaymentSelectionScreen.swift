//
//  DefaultPaymentSelectionScreen.swift
//
//
//  Created on 17.06.2025.
//

import SwiftUI

/// Default payment method selection screen with scope integration
@available(iOS 15.0, *)
internal struct DefaultPaymentSelectionScreen: View, LogReporter {

    // MARK: - Properties

    let scope: any PaymentMethodSelectionScope

    // MARK: - State

    @State private var paymentMethods: [PrimerComposablePaymentMethod] = []
    @State private var currency: ComposableCurrency?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var stateTask: Task<Void, Never>?
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
        .onDisappear {
            stateTask?.cancel()
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 16) {
            Text("Select Payment Method")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)

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
                .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)

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
                    DefaultPaymentMethodItemView(
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

        stateTask = Task { @MainActor in
            for await state in scope.state() {
                handleStateChange(state)
            }
        }
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
private struct DefaultPaymentMethodItemView: View {

    let paymentMethod: PrimerComposablePaymentMethod
    let currency: ComposableCurrency?
    let onSelection: () -> Void

    @Environment(\.designTokens) private var tokens

    @ViewBuilder
    private var paymentMethodContent: some View {
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
                Text(paymentMethod.paymentMethodName ?? "Payment Method")
                    .font(.headline)
                    .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
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
    }

    var body: some View {
        Button(action: onSelection) {
            paymentMethodContent
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(tokens?.primerColorGray100 ?? Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(tokens?.primerColorBorderOutlinedDefault ?? Color(.separator), lineWidth: 1)
                )
        )
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
                paymentMethodName: "Credit or Debit Card",
                description: "Pay with Visa, Mastercard, or American Express",
                surcharge: nil
            ),
            PrimerComposablePaymentMethod(
                paymentMethodType: "PAYPAL",
                paymentMethodName: "PayPal",
                description: "Pay with your PayPal account",
                surcharge: nil
            )
        ],
        currency: ComposableCurrency(code: "USD", symbol: "$")
    )

    func state() -> AsyncStream<PaymentMethodSelectionState> {
        PublishedAsyncStream.create(from: self, keyPath: \._state)
    }

    func onPaymentMethodSelected(_ paymentMethod: PrimerComposablePaymentMethod) {
        // Mock implementation
    }
}
