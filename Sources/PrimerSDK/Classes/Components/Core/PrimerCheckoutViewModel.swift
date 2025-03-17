//
//  PrimerCheckoutViewModel.swift
//
//
//  Created by Boris on 6.2.25..
//

import SwiftUI

/// ViewModel that implements the PrimerCheckoutScope and manages checkout state.
@MainActor
class PrimerCheckoutViewModel: ObservableObject, PrimerCheckoutScope {
    @Published private(set) var isClientTokenProcessed = false
    @Published private(set) var isCheckoutComplete = false
    @Published private(set) var error: ComponentsPrimerError?

    private var paymentMethodsContinuation: AsyncStream<[any PaymentMethodProtocol]>.Continuation?
    private var selectedMethodContinuation: AsyncStream<(any PaymentMethodProtocol)?>.Continuation?

    private var availablePaymentMethods: [any PaymentMethodProtocol] = []
    private var currentSelectedMethod: (any PaymentMethodProtocol)?

    init() {
        // Initialize empty state
    }

    /// Process the client token and initialize the SDK.
    func processClientToken(_ token: String) async {
        do {
            // Parse the token and initialize the SDK
            try await Task.sleep(nanoseconds: 1 * 1_000_000_000) // Simulate network delay

            // Load payment methods
            availablePaymentMethods = await loadPaymentMethods()
            paymentMethodsContinuation?.yield(availablePaymentMethods)

            isClientTokenProcessed = true
        } catch {
            setError(ComponentsPrimerError.clientTokenError(error))
        }
    }

    /// Set an error that occurred during checkout.
    func setError(_ error: ComponentsPrimerError) {
        self.error = error
    }

    /// Complete the checkout process successfully.
    func completeCheckout() {
        isCheckoutComplete = true
    }

    // MARK: - PrimerCheckoutScope Implementation

    func paymentMethods() -> AsyncStream<[any PaymentMethodProtocol]> {
        AsyncStream { continuation in
            self.paymentMethodsContinuation = continuation
            continuation.yield(availablePaymentMethods)
        }
    }

    func selectedPaymentMethod() -> AsyncStream<(any PaymentMethodProtocol)?> {
        AsyncStream { continuation in
            self.selectedMethodContinuation = continuation
            continuation.yield(currentSelectedMethod)
        }
    }

    func selectPaymentMethod(_ method: (any PaymentMethodProtocol)?) async {
        currentSelectedMethod = method
        selectedMethodContinuation?.yield(method)
    }

    // MARK: - Private Helpers

    private func loadPaymentMethods() async -> [any PaymentMethodProtocol] {
        // Dummy payment methods for demonstration
        return [
            CardPaymentMethod(),
//            KlarnaPaymentMethod()
        ]
    }
}
