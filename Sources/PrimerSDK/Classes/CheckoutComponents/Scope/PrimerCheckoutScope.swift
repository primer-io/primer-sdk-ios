//
//  PrimerCheckoutScope.swift
//  PrimerSDK
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// The main scope interface for PrimerCheckout, providing lifecycle control and customizable UI components.
@available(iOS 15.0, *)
@MainActor
public protocol PrimerCheckoutScope: AnyObject {

    /// The current state of the checkout flow as an async stream.
    var state: AsyncStream<PrimerCheckoutState> { get }

    // MARK: - Customizable Screens

    /// Container view that wraps all checkout content.
    /// Default implementation provides standard checkout container.
    var container: ((_ content: @escaping () -> AnyView) -> any View)? { get set }

    /// Splash screen shown during initialization.
    /// Default implementation shows Primer branding.
    var splashScreen: (() -> any View)? { get set }

    /// Loading screen shown during async operations.
    /// Default implementation shows activity indicator.
    var loadingScreen: (() -> any View)? { get set }

    // Note: Success screen removed - CheckoutComponents dismisses immediately on success
    // The delegate handles presenting the result screen via PrimerResultViewController

    /// Error screen shown when an error occurs.
    /// Default implementation shows error icon and message.
    var errorScreen: ((_ message: String) -> any View)? { get set }

    // MARK: - Nested Scopes

    /// Scope for payment method selection screen.
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
    /// - `.manual`: Payments require explicit confirmation via `CheckoutComponentsPrimer.resumePayment()`
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

    /// Ready state with payment methods loaded.
    case ready

    /// Payment completed successfully.
    case success(PaymentResult)

    /// Checkout has been dismissed by user or merchant.
    case dismissed

    /// An error occurred during checkout.
    case failure(PrimerError)

    public static func == (lhs: PrimerCheckoutState, rhs: PrimerCheckoutState) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing),
             (.ready, .ready),
             (.dismissed, .dismissed):
            return true
        case let (.success(lhsResult), .success(rhsResult)):
            return lhsResult.paymentId == rhsResult.paymentId
        case let (.failure(lhsError), .failure(rhsError)):
            return lhsError.errorId == rhsError.errorId
        default:
            return false
        }
    }
}
