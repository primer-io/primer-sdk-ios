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
    private var availablePaymentMethods: [any PaymentMethodProtocol] = []
    private var currentSelectedMethod: (any PaymentMethodProtocol)?

    // Task manager to handle concurrent operations
    private let taskManager = TaskManager()

    // Streams for payment methods and selection
    private var paymentMethodsStream: ContinuableStream<[any PaymentMethodProtocol]>?
    private var selectedMethodStream: ContinuableStream<(any PaymentMethodProtocol)?>?

    // MARK: - Initialization
    init() {
        // Initialize with empty state
    }

    // MARK: - Public Methods

    /// Process the client token and initialize the SDK.
    func processClientToken(_ token: String) async {
        guard clientToken != token else { return }

        do {
            self.clientToken = token
            try await configureSDK(with: token)
            self.availablePaymentMethods = await loadPaymentMethods()
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

    /// Returns an AsyncStream of available payment methods.
    func paymentMethods() -> AsyncStream<[any PaymentMethodProtocol]> {
        if let stream = paymentMethodsStream?.stream {
            return stream
        } else {
            // Create a new stream that immediately yields available methods
            let continuable = ContinuableStream<[any PaymentMethodProtocol]> { [weak self] continuation in
                guard let self = self else { return }
                continuation.yield(self.availablePaymentMethods)
            }
            paymentMethodsStream = continuable
            return continuable.stream
        }
    }

    /// Returns an AsyncStream of the currently selected payment method.
    func selectedPaymentMethod() -> AsyncStream<(any PaymentMethodProtocol)?> {
        if let stream = selectedMethodStream?.stream {
            return stream
        } else {
            // Create a new continuously updatable stream.
            let continuable = ContinuableStream<(any PaymentMethodProtocol)?> { [weak self] continuation in
                guard let self = self else { return }
                // Yield the current value immediately.
                continuation.yield(self.currentSelectedMethod)
            }
            selectedMethodStream = continuable
            return continuable.stream
        }
    }

    /// Updates the selected payment method and actively notifies subscribers.
    func selectPaymentMethod(_ method: (any PaymentMethodProtocol)?) async {
        currentSelectedMethod = method
        // Actively yield the new method to the stored continuation.
        selectedMethodStream?.yield(method)
    }

    // MARK: - Private Helpers

    private func configureSDK(with token: String) async throws {
        // This would integrate with the actual Primer SDK
        // For now, simulate initialization delay
        try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
    }

    private func loadPaymentMethods() async -> [any PaymentMethodProtocol] {
        // In a real implementation, this would load payment methods from the SDK
        // For now, return a card payment method
        return [CardPaymentMethod()]
    }

    deinit {
        // Ensure all streams are properly closed
        paymentMethodsStream?.finish()
        selectedMethodStream?.finish()

        // Cancel any pending tasks
        Task.detached { [taskManager] in
            await taskManager.cancelAllTasks()
        }
    }
}
