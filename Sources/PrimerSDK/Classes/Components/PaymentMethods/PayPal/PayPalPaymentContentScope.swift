//
//  PayPalPaymentContentScope.swift
//
//
//  Created by Boris on 6.2.25..
//

import SwiftUI

/// PaymentMethodContentScope implementation for PayPal (placeholder).
class PayPalPaymentContentScope: PaymentMethodContentScope {
    let method: PaymentMethod
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var validationState: PaymentValidationState = PaymentValidationState(isValid: true)

    init(method: PaymentMethod) {
        self.method = method
        // PayPal typically requires no additional input, so it's immediately valid.
    }

    func getState() async -> PaymentMethodState {
        PaymentMethodState(isLoading: isLoading, validationState: validationState)
    }

    func submit() async -> Result<PaymentResult, Error> {
        // Simulate redirecting to PayPal and processing payment.
        isLoading = true
        defer { isLoading = false }
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        // In a real scenario, you'd invoke PayPal SDK and await result.
        return .success(PaymentResult(success: true, message: "Paid with PayPal"))
    }

    func defaultContent() -> AnyView {
        if let tokens = Environment(\.designTokens).wrappedValue {
            return AnyView(
                Text("PayPal payment will be handled externally.")
                    .foregroundColor(tokens.primerColorBrand)
                    .padding(8)
                    .background(tokens.primerColorGray100)
                    .cornerRadius(8)
                    .padding(16)
            )
        } else {
            return AnyView(Text("Loading design tokens..."))
        }
    }
}
