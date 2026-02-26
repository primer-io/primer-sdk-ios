//
//  PrimerCheckoutScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Closure type for the `onBeforePaymentCreate` callback.
/// Provides payment method data and a decision handler to continue or abort payment creation.
@available(iOS 15.0, *)
public typealias BeforePaymentCreateHandler = (_ data: PrimerCheckoutPaymentMethodData,
                                               _ decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void) -> Void

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
  var loadingScreen: Component? { get set }

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
  func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for methodType: PrimerPaymentMethodType)
    -> T?

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

  // MARK: - Payment Callbacks

  /// Called before a payment is created. Use the decision handler to provide an idempotency key
  /// or abort payment creation. If not set, payments proceed without an idempotency key.
  var onBeforePaymentCreate: BeforePaymentCreateHandler? { get set }

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
///
/// `PrimerCheckoutState` provides a way to observe the checkout lifecycle and respond
/// to state changes. Use the `state` async stream on `PrimerCheckoutScope` to receive
/// state updates.
///
/// Example usage:
/// ```swift
/// for await state in checkoutScope.state {
///     switch state {
///     case .initializing:
///         showLoadingIndicator()
///     case .ready(let amount, let currency):
///         showPaymentMethods(amount: amount, currency: currency)
///     case .success(let result):
///         showSuccessScreen(paymentId: result.paymentId)
///     case .failure(let error):
///         showErrorScreen(error: error)
///     case .dismissed:
///         handleDismissal()
///     }
/// }
/// ```
public enum PrimerCheckoutState: Equatable {
  /// Initial state while loading configuration and payment methods.
  /// The SDK is fetching the client session and preparing available payment methods.
  case initializing

  /// Ready state with payment methods loaded and checkout available.
  /// - Parameters:
  ///   - totalAmount: The total payment amount in minor units (e.g., cents for USD).
  ///   - currencyCode: The ISO 4217 currency code (e.g., "USD", "EUR", "GBP").
  case ready(totalAmount: Int, currencyCode: String)

  /// Payment completed successfully.
  /// Contains the full payment result with payment ID, status, and other details.
  case success(PaymentResult)

  /// Checkout has been dismissed by user action or programmatically.
  /// This is a terminal state indicating the checkout flow has ended without payment.
  case dismissed

  /// Payment or checkout failed with an error.
  /// Contains the specific error with diagnostics information for debugging.
  case failure(PrimerError)

  public static func == (lhs: PrimerCheckoutState, rhs: PrimerCheckoutState) -> Bool {
    switch (lhs, rhs) {
    case (.initializing, .initializing),
      (.dismissed, .dismissed):
      true
    case let (.ready(lhsAmount, lhsCurrency), .ready(rhsAmount, rhsCurrency)):
      lhsAmount == rhsAmount && lhsCurrency == rhsCurrency
    case let (.success(lhsResult), .success(rhsResult)):
      lhsResult.paymentId == rhsResult.paymentId
    case let (.failure(lhsError), .failure(rhsError)):
      lhsError.errorId == rhsError.errorId
    default:
      false
    }
  }
}
