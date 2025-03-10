//
//  DefaultPaymentMethodContentScope.swift
//
//
//  Created by Boris on 6.2.25..
//

import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

/// The default implementation of PaymentMethodContentScope for any payment method.
struct DefaultPaymentMethodContentScope: PaymentMethodContentScope {
    let method: PaymentMethod

    // Simulated state; in a real system, this state would be derived from backend/network updates.
    var simulatedState = PaymentMethodState(
        isLoading: false,
        validationState: PaymentValidationState(isValid: true)
    )

    /// Returns the current simulated state.
    func getState() async -> PaymentMethodState {
        // TODO: Replace simulated state with actual state mapping from your processing logic.
        simulatedState
    }

    /// Simulate payment submission.
    func submit() async -> Result<PaymentResult, Error> {
        // TODO: Replace with real payment submission logic.
        try? await Task.sleep(nanoseconds: 2 * 1_000_000_000) // simulate a 2-second delay
        return .success(PaymentResult(success: true, message: "Payment processed successfully"))
    }

    #if canImport(SwiftUI)
    /// Provides default SwiftUI UI for the payment method.
    func defaultContent() -> AnyView {
        if let tokens = Environment(\.designTokens).wrappedValue {
            return AnyView(
                VStack(spacing: 12) {
                    Text("Default UI for \(method.name)")
                        .font(.system(size: 16, weight: .medium))  // Replace with tokens if needed
                        .foregroundColor(tokens.colorBrand)
                        .padding(8)
                        .background(tokens.colorGray100)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red, lineWidth: 3)
                        )
                }
                .padding(16)
            )
        } else {
            return AnyView(Text("Loading design tokens..."))
        }
    }
    #endif
}
