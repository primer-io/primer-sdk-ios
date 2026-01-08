//
//  ApplePayPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Apple Pay payment method implementation conforming to PaymentMethodProtocol.
/// Provides Apple Pay functionality with scope creation for CheckoutComponents.
@available(iOS 15.0, *)
struct ApplePayPaymentMethod: PaymentMethodProtocol {

    // MARK: - PaymentMethodProtocol

    /// The scope type this payment method creates
    typealias ScopeType = DefaultApplePayScope

    /// The payment method type identifier for Apple Pay
    static let paymentMethodType: String = "APPLE_PAY"

    /// Creates an Apple Pay scope for this payment method.
    /// - Parameters:
    ///   - checkoutScope: The parent checkout scope for navigation coordination
    ///   - diContainer: The dependency injection container for resolving services
    /// - Returns: A configured DefaultApplePayScope instance
    @MainActor
    static func createScope(
        checkoutScope: PrimerCheckoutScope,
        diContainer: any ContainerProtocol
    ) throws -> DefaultApplePayScope {
        // Check if checkoutScope is DefaultCheckoutScope to access internal methods
        guard let defaultCheckoutScope = checkoutScope as? DefaultCheckoutScope else {
            throw PrimerError.invalidArchitecture(
                description: "ApplePayPaymentMethod requires DefaultCheckoutScope",
                recoverSuggestion: "Ensure you're using the default CheckoutComponents implementation"
            )
        }

        // Determine presentation context based on available payment methods
        let paymentMethodContext: PresentationContext
        if defaultCheckoutScope.availablePaymentMethods.count > 1 {
            // Multiple payment methods - came from payment selection, show back button
            paymentMethodContext = .fromPaymentSelection
        } else {
            // Single payment method - direct navigation, no back button
            paymentMethodContext = .direct
        }

        return DefaultApplePayScope(
            checkoutScope: defaultCheckoutScope,
            presentationContext: paymentMethodContext
        )
    }

    /// Creates the view for this payment method.
    @MainActor
    static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
        guard let applePayScope = checkoutScope.getPaymentMethodScope(DefaultApplePayScope.self) else {
            return nil
        }
        if let customScreen = applePayScope.screen {
            return AnyView(customScreen(applePayScope))
        } else {
            return AnyView(ApplePayScreen(scope: applePayScope))
        }
    }

    /// Provides custom UI for this payment method using ViewBuilder.
    /// - Parameter content: A ViewBuilder closure that uses the Apple Pay scope as a parameter
    @MainActor
    func content<V: View>(@ViewBuilder content: @escaping (DefaultApplePayScope) -> V) -> AnyView {
        // This method would be called with a custom ViewBuilder implementation
        fatalError("Custom content method should be implemented by the CheckoutComponents framework")
    }

    /// Provides the default UI implementation for Apple Pay.
    @MainActor
    func defaultContent() -> AnyView {
        // This would return the default ApplePayScreen
        fatalError("Default content method should be implemented by the CheckoutComponents framework")
    }
}

// MARK: - Registration Helper

@available(iOS 15.0, *)
extension ApplePayPaymentMethod {

    /// Registers the Apple Pay payment method with the global registry.
    /// This should be called during SDK initialization.
    @MainActor
    static func register() {
        PaymentMethodRegistry.shared.register(ApplePayPaymentMethod.self)
    }
}
