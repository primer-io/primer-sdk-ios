//
//  CardFormProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Provider view that wraps content with card form scope access and navigation handling.
///
/// Use `CardFormProvider` when embedding the card form in your own navigation hierarchy:
/// ```swift
/// CardFormProvider(
///     onSuccess: { result in
///         print("Payment succeeded: \(result.paymentId)")
///     },
///     onError: { error in
///         print("Payment failed: \(error)")
///     },
///     onCancel: {
///         print("User cancelled")
///     }
/// ) { scope in
///     CardFormScreen(scope: scope)
/// }
/// ```
///
/// Callbacks are invoked when provided. If no callbacks are provided, navigation events
/// are handled by the SDK's default behavior.
@available(iOS 15.0, *)
public struct CardFormProvider<Content: View>: View, LogReporter {
    private let onSuccess: ((CheckoutPaymentResult) -> Void)?
    private let onError: ((String) -> Void)?
    private let onCancel: (() -> Void)?
    private let content: (any PrimerCardFormScope) -> Content

    @Environment(\.primerCheckoutScope) private var checkoutScope

    /// Creates a CardFormProvider.
    /// - Parameters:
    ///   - onSuccess: Called when payment succeeds with the result
    ///   - onError: Called when payment fails with error message
    ///   - onCancel: Called when user cancels the form
    ///   - content: ViewBuilder that receives the card form scope
    public init(
        onSuccess: ((CheckoutPaymentResult) -> Void)? = nil,
        onError: ((String) -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (any PrimerCardFormScope) -> Content
    ) {
        self.onSuccess = onSuccess
        self.onError = onError
        self.onCancel = onCancel
        self.content = content
    }

    public var body: some View {
        if let checkoutScope,
           let cardFormScope = checkoutScope.getPaymentMethodScope(DefaultCardFormScope.self) {
            content(cardFormScope)
                .environment(\.primerCardFormScope, cardFormScope)
                .task {
                    await observeCheckoutState()
                }
        } else {
            // Fallback when scope is not available
            Text("Card form scope not available")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - State Observation

    /// Observes checkout state changes and invokes appropriate callbacks.
    /// Uses iOS-native async/await pattern with AsyncStream.
    private func observeCheckoutState() async {
        guard let checkoutScope else { return }

        for await state in checkoutScope.state {
            await handleStateChange(state)
        }
    }

    /// Handles checkout state changes by invoking the appropriate callback.
    @MainActor
    private func handleStateChange(_ state: PrimerCheckoutState) {
        switch state {
        case let .success(result):
            if let onSuccess {
                // Convert PaymentResult to CheckoutPaymentResult
                let amountString = result.amount.map { String($0) } ?? ""
                onSuccess(CheckoutPaymentResult(paymentId: result.paymentId, amount: amountString))
            }

        case let .failure(error):
            onError?(error.localizedDescription)

        case .dismissed:
            onCancel?()

        case .initializing, .ready:
            // No action needed for these states
            break
        }
    }
}
