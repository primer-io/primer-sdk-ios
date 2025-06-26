//
//  PrimerCheckoutScope.swift
//  PrimerSDK
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// The main scope interface for PrimerCheckout, providing lifecycle control and customizable UI components.
/// This protocol matches the Android Composable API exactly for cross-platform consistency.
@available(iOS 15.0, *)
@MainActor
public protocol PrimerCheckoutScope: AnyObject {

    /// The current state of the checkout flow as an async stream.
    var state: AsyncStream<PrimerCheckoutState> { get }

    // MARK: - Customizable Screens

    /// Container view that wraps all checkout content.
    /// Default implementation provides standard checkout container.
    var container: ((_ content: @escaping () -> AnyView) -> AnyView)? { get set }

    /// Splash screen shown during initialization.
    /// Default implementation shows Primer branding.
    var splashScreen: (() -> AnyView)? { get set }

    /// Loading screen shown during async operations.
    /// Default implementation shows activity indicator.
    var loadingScreen: (() -> AnyView)? { get set }

    // Note: Success screen removed - CheckoutComponents dismisses immediately on success
    // The delegate handles presenting the result screen via PrimerResultViewController

    /// Error screen shown when an error occurs.
    /// Default implementation shows error icon and message.
    var errorScreen: ((_ message: String) -> AnyView)? { get set }

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

    // MARK: - Generic Payment Method Screen Customization

    /// Sets a custom screen for a specific payment method scope type.
    /// This allows type-safe customization of any payment method screen.
    /// - Parameters:
    ///   - scopeType: The scope type (e.g., PrimerCardFormScope.self)
    ///   - screenBuilder: The custom screen builder closure
    ///
    /// Example usage:
    /// ```swift
    /// checkoutScope.setPaymentMethodScreen(PrimerCardFormScope.self) { scope in
    ///     CustomCardFormView(scope: scope)
    /// }
    /// ```
    func setPaymentMethodScreen<T: PrimerPaymentMethodScope>(
        _ scopeType: T.Type,
        screenBuilder: @escaping (T) -> AnyView
    )

    /// Non-generic overload for PrimerCardFormScope to avoid existential type issues
    func setPaymentMethodScreen(
        _ scopeType: (any PrimerCardFormScope).Type,
        screenBuilder: @escaping (any PrimerCardFormScope) -> AnyView
    )

    /// Sets a custom screen for a specific payment method type with scope type specification.
    /// This allows payment method specific customization while maintaining type safety.
    /// - Parameters:
    ///   - paymentMethodType: The payment method type string
    ///   - scopeType: The scope type for type safety
    ///   - screenBuilder: The custom screen builder closure
    ///
    /// Example usage:
    /// ```swift
    /// checkoutScope.setPaymentMethodScreen(for: "PAYMENT_CARD", scopeType: PrimerCardFormScope.self) { scope in
    ///     CustomCardFormView(scope: scope)
    /// }
    /// ```
    func setPaymentMethodScreen<T: PrimerPaymentMethodScope>(
        for paymentMethodType: String,
        scopeType: T.Type,
        screenBuilder: @escaping (T) -> AnyView
    )

    /// Gets a custom screen for a specific payment method scope type.
    /// - Parameter scopeType: The scope type to get the screen for
    /// - Returns: The custom screen builder closure if set, nil otherwise
    func getPaymentMethodScreen<T: PrimerPaymentMethodScope>(_ scopeType: T.Type) -> ((T) -> AnyView)?

    /// Gets a custom screen for a specific payment method type.
    /// - Parameters:
    ///   - paymentMethodType: The payment method type string
    ///   - scopeType: The scope type for type safety
    /// - Returns: The custom screen builder closure if set, nil otherwise
    func getPaymentMethodScreen<T: PrimerPaymentMethodScope>(
        for paymentMethodType: String,
        scopeType: T.Type
    ) -> ((T) -> AnyView)?

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
