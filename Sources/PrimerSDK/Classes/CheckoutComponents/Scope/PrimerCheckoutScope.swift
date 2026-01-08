//
//  PrimerCheckoutScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// The main scope interface for PrimerCheckout, providing lifecycle control and customizable UI components.
@available(iOS 15.0, *)
@MainActor
public protocol PrimerCheckoutScope: AnyObject {

    /// The current state of the checkout flow as an async stream.
    var state: AsyncStream<PrimerCheckoutState> { get }

    // MARK: - Customizable Screens

    /// Default implementation provides standard checkout container.
    var container: ContainerComponent? { get set }

    /// Custom splash screen shown during SDK initialization.
    /// Default implementation shows Primer branding.
    var splashScreen: Component? { get set }

    /// Custom loading screen shown during payment processing.
    /// Default implementation shows a centered loading indicator with "Loading" text.
    var loading: Component? { get set }

    // Note: Success screen removed - CheckoutComponents dismisses immediately on success
    // The delegate handles presenting the result screen via PrimerResultViewController

    /// Default implementation shows error icon and message.
    var errorScreen: ErrorComponent? { get set }

    // MARK: - Nested Scopes

    var paymentMethodSelection: PrimerPaymentMethodSelectionScope { get }

    // MARK: - Dynamic Payment Method Scope Access

    /// Gets a payment method scope using type-safe metatype (recommended approach).
    /// This is the preferred method for static type-safe access to payment method scopes.
    /// - Parameter scopeType: The scope type to create (e.g., PrimerCardFormScope.self)
    /// - Returns: A configured scope instance for the payment method, or nil if not registered
    ///
    /// Example usage:
    /// ```swift
    /// let cardFormScope = checkoutScope.getPaymentMethodScope(PrimerCardFormScope.self)
    /// ```
    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(_ scopeType: T.Type) -> T?

    /// Gets a payment method scope using enum-based type specification.
    /// This method provides discoverable access to payment method scopes via enum cases.
    /// - Parameter methodType: The payment method type enum case
    /// - Returns: A configured scope instance for the payment method, or nil if not registered
    ///
    /// Example usage:
    /// ```swift
    /// let cardFormScope: PrimerCardFormScope = checkoutScope.getPaymentMethodScope(for: .paymentCard)
    /// ```
    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for methodType: PrimerPaymentMethodType) -> T?

    /// Gets a payment method scope for the specified payment method string identifier.
    /// This method provides dynamic access for runtime-determined payment methods.
    /// - Parameter paymentMethodType: The payment method type identifier (e.g., "PAYMENT_CARD", "PAYPAL")
    /// - Returns: A configured scope instance for the payment method, or nil if not registered
    ///
    /// Example usage:
    /// ```swift
    /// let cardFormScope: PrimerCardFormScope = checkoutScope.getPaymentMethodScope(for: "PAYMENT_CARD")
    /// ```
    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for paymentMethodType: String) -> T?

    // MARK: - Payment Method Screen Customization
    // Removed: setPaymentMethodScreen and getPaymentMethodScreen methods
    // Use PaymentMethodProtocol.content() for custom UI with ViewBuilder pattern

    // MARK: - Payment Settings

    /// Payment handling mode (auto vs manual).
    /// - `.auto`: Payments are automatically processed after tokenization (default)
    /// - `.manual`: Payments require explicit confirmation from your backend
    var paymentHandling: PrimerPaymentHandling { get }

    // MARK: - Navigation

    /// Dismisses the checkout flow.
    func onDismiss()
}

// MARK: - State Definition

/// Represents the current state of the checkout flow.
public enum PrimerCheckoutState: Equatable {
    /// Initial state while loading configuration and payment methods.
    case initializing

    /// Ready state with payment methods loaded, including payment amount information.
    /// - Parameters:
    ///   - totalAmount: The total payment amount in minor units (e.g., cents)
    ///   - currencyCode: The ISO 4217 currency code (e.g., "USD", "EUR")
    case ready(totalAmount: Int, currencyCode: String)

    case success(PaymentResult)

    /// Checkout has been dismissed by user or merchant.
    case dismissed

    case failure(PrimerError)

    public static func == (lhs: PrimerCheckoutState, rhs: PrimerCheckoutState) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing),
             (.dismissed, .dismissed):
            return true
        case let (.ready(lhsAmount, lhsCurrency), .ready(rhsAmount, rhsCurrency)):
            return lhsAmount == rhsAmount && lhsCurrency == rhsCurrency
        case let (.success(lhsResult), .success(rhsResult)):
            return lhsResult.paymentId == rhsResult.paymentId
        case let (.failure(lhsError), .failure(rhsError)):
            return lhsError.errorId == rhsError.errorId
        default:
            return false
        }
    }
}
