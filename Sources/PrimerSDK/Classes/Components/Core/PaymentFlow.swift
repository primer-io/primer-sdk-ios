//
//  PaymentFlow.swift
//
//
//  Created by Boris on 6.2.25..
//

import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

/// The headless core component that encapsulates payment processing logic and state.
/// This actor leverages Swift Concurrency (async/await) as per Apple's guidelines.
actor PaymentFlow: PaymentFlowScope {

    // MARK: Internal State

    private var _paymentMethods: [PaymentMethod] = []
    private var _selectedMethod: PaymentMethod?

    // AsyncStream continuations to emit updates.
    private var paymentMethodsContinuation: AsyncStream<[PaymentMethod]>.Continuation?
    private var selectedMethodContinuation: AsyncStream<PaymentMethod?>.Continuation?

    /// Initialize with default payment methods.
    init() {
        // TODO: In a production system, fetch or update available payment methods dynamically.
        _paymentMethods = [
            CardPaymentMethod(id: "card", name: "Credit Card"),
            PayPalPaymentMethod(id: "paypal", name: "PayPal"),
            ApplePayPaymentMethod(id: "applePay", name: "Apple Pay")
        ]
    }

    // MARK: AsyncStream Providers

    /// Provides an `AsyncStream` for payment methods.
    func getPaymentMethods() async -> AsyncStream<[PaymentMethod]> {
        return AsyncStream { continuation in
            self.paymentMethodsContinuation = continuation
            continuation.yield(self._paymentMethods)
            // TODO: Implement dynamic updates if payment methods change.
        }
    }

    /// Provides an `AsyncStream` for the currently selected payment method.
    func getSelectedMethod() async -> AsyncStream<PaymentMethod?> {
        return AsyncStream { continuation in
            self.selectedMethodContinuation = continuation
            continuation.yield(self._selectedMethod)
            // TODO: Implement dynamic updates if the selection changes.
        }
    }

    // MARK: Internal Update Helpers

    private func updatePaymentMethods() {
        paymentMethodsContinuation?.yield(_paymentMethods)
    }

    private func updateSelectedMethod() {
        selectedMethodContinuation?.yield(_selectedMethod)
    }

    // MARK: PaymentFlowScope Implementation

    func selectPaymentMethod(_ method: PaymentMethod?) async {
        _selectedMethod = method
        updateSelectedMethod()
    }

    #if canImport(SwiftUI)
    nonisolated func paymentMethodContent<Content: View>(
        for method: PaymentMethod,
        @ViewBuilder content: @escaping (any PaymentMethodContentScope) -> Content
    ) -> AnyView {
        // Wrap the helper view in AnyView for type erasure.
        AnyView(PaymentMethodContentView(method: method, content: content))
    }
    #endif
}
