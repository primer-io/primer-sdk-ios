//
//  PaymentFlow.swift
//
//
//  Created by Boris on 6.2.25..
//

import SwiftUI

/// The headless core component that encapsulates payment processing logic and state.
@available(iOS 14.0, *)
actor PaymentFlow: PaymentFlowScope {
    // MARK: - Internal State
    private var _paymentMethods: [PaymentMethod] = []
    private var _selectedMethod: PaymentMethod?

    // AsyncStream continuations to emit updates.
    private var paymentMethodsContinuation: AsyncStream<[PaymentMethod]>.Continuation?
    private var selectedMethodContinuation: AsyncStream<PaymentMethod?>.Continuation?

    /// Initialize with default payment methods.
    init() {
        // In a production system, fetch or update available payment methods dynamically.
        _paymentMethods = [
            CardPaymentMethod(id: "card", name: "Credit Card"),
            PayPalPaymentMethod(id: "paypal", name: "PayPal"),
            ApplePayPaymentMethod(id: "applePay", name: "Apple Pay")
        ]
    }

    // MARK: - AsyncStream Providers

    func getPaymentMethods() async -> AsyncStream<[PaymentMethod]> {
        AsyncStream { continuation in
            self.paymentMethodsContinuation = continuation
            continuation.yield(self._paymentMethods)
            // TODO: Implement dynamic updates if payment methods change.
        }
    }

    func getSelectedMethod() async -> AsyncStream<PaymentMethod?> {
        AsyncStream { continuation in
            self.selectedMethodContinuation = continuation
            continuation.yield(self._selectedMethod)
            // TODO: Implement dynamic updates if the selection changes.
        }
    }

    // MARK: - Internal Update Helpers

    private func updatePaymentMethods() {
        paymentMethodsContinuation?.yield(_paymentMethods)
    }

    private func updateSelectedMethod() {
        selectedMethodContinuation?.yield(_selectedMethod)
    }

    // MARK: - PaymentFlowScope Implementation

    func selectPaymentMethod(_ method: PaymentMethod?) async {
        _selectedMethod = method
        updateSelectedMethod()
    }

    /// Returns the payment method content wrapped in AnyView.
    /// (Since the protocol requirement is @MainActor, this function will be executed on the main actor.)
    nonisolated func paymentMethodContent<Content: View>(
        for method: PaymentMethod,
        @ViewBuilder content: @escaping (any PaymentMethodContentScope) -> Content
    ) -> AnyView {
        // PaymentMethodContentView is a SwiftUI view, which is implicitly main-actor isolated.
        // We can directly instantiate it here.
        return AnyView(PaymentMethodContentView(method: method, content: content))
    }
}
