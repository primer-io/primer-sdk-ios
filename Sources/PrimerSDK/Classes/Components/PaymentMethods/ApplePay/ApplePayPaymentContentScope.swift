//
//  ApplePayPaymentContentScope.swift
//
//
//  Created by Boris on 6.2.25..
//

import SwiftUI

/// PaymentMethodContentScope implementation for Apple Pay (placeholder).
class ApplePayPaymentContentScope: PaymentMethodContentScope {
    let method: PaymentMethod
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var validationState: PaymentValidationState = PaymentValidationState(isValid: true)

    init(method: PaymentMethod) {
        self.method = method
        // Apple Pay requires no manual input if Wallet is configured, so it's valid by default.
    }

    func getState() async -> PaymentMethodState {
        PaymentMethodState(isLoading: isLoading, validationState: validationState)
    }

    func submit() async -> Result<PaymentResult, Error> {
        // Simulate invoking Apple Pay.
        isLoading = true
        defer { isLoading = false }
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        // In a real implementation, you'd trigger the Apple Pay flow and await its result.
        return .success(PaymentResult(success: true, message: "Paid with Apple Pay"))
    }

    func defaultContent() -> AnyView {
        if let tokens = Environment(\.designTokens).wrappedValue {
            return AnyView(
                Text("Apple Pay will use Wallet for payment.")
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
