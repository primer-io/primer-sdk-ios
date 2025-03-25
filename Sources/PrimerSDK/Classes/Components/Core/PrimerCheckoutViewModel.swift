//
//  PrimerCheckoutViewModel.swift
//
//
//  Created by Boris on 6.2.25..
//

import SwiftUI

/**
 * ViewModel that implements the PrimerCheckoutScope interface and manages checkout state.
 */
@available(iOS 15.0, *)
@MainActor
class PrimerCheckoutViewModel: ObservableObject, PrimerCheckoutScope {
    // MARK: - Published Properties

    @Published private(set) var clientToken: String?
    @Published private(set) var isClientTokenProcessed = false
    @Published private(set) var isCheckoutComplete = false
    @Published private(set) var error: ComponentsPrimerError?

    // MARK: - Private Properties

    private var paymentMethodsContinuation: AsyncStream<[any PaymentMethodProtocol]>.Continuation?
    private var selectedMethodContinuation: AsyncStream<(any PaymentMethodProtocol)?>.Continuation?

    private var availablePaymentMethods: [any PaymentMethodProtocol] = []
    private var currentSelectedMethod: (any PaymentMethodProtocol)?

    // MARK: - Initialization

    init() {
        // Initialize with empty state
    }

    // MARK: - Public Methods

    /// Process the client token and initialize the SDK.
    /// - Parameter token: The client token string
    func processClientToken(_ token: String) async {
        guard clientToken != token else {
            // Already processed this token
            return
        }

        do {
            self.clientToken = token

            // Configure SDK with token
            try await configureSDK(with: token)

            // Load available payment methods
            self.availablePaymentMethods = await loadPaymentMethods()

            // Notify any listeners
            paymentMethodsContinuation?.yield(availablePaymentMethods)

            isClientTokenProcessed = true
        } catch {
            setError(ComponentsPrimerError.clientTokenError(error))
        }
    }

    /// Set an error that occurred during checkout.
    /// - Parameter error: The error that occurred
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

    private func configureSDK(with token: String) async throws {
        // Here would be the SDK configuration logic
        // For now, just simulate network delay
        try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
    }

    private func loadPaymentMethods() async -> [any PaymentMethodProtocol] {
        // Simulate loading payment methods from SDK
        return [
            CardPaymentMethod(),
            // Add other payment methods as they become available
        ]
    }
}
