//
//  PrimerCheckoutScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Closure type for the `onBeforePaymentCreate` callback.
/// Provides payment method data and a decision handler to continue or abort payment creation.
@available(iOS 15.0, *)
public typealias BeforePaymentCreateHandler = @Sendable (_ data: PrimerCheckoutPaymentMethodData,
                                                        _ decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void) -> Void

/// The main scope interface for PrimerCheckout, providing lifecycle control and customizable UI components.
@available(iOS 15.0, *)
@MainActor
protocol PrimerCheckoutScope: AnyObject {

  /// The current state of the checkout flow as an async stream.
  var state: AsyncStream<PrimerCheckoutState> { get }

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

  // MARK: - Per-protocol scope access (existential metatypes)

  /// Gets a payment method scope as its protocol existential, resolved from the metatype.
  func getPaymentMethodScope(_ scopeType: (any PrimerCardFormScope).Type) -> (any PrimerCardFormScope)?
  func getPaymentMethodScope(_ scopeType: (any PrimerKlarnaScope).Type) -> (any PrimerKlarnaScope)?
  func getPaymentMethodScope(_ scopeType: (any PrimerAdyenKlarnaScope).Type) -> (any PrimerAdyenKlarnaScope)?
  func getPaymentMethodScope(_ scopeType: (any PrimerWebRedirectScope).Type) -> (any PrimerWebRedirectScope)?
  func getPaymentMethodScope(_ scopeType: (any PrimerFormRedirectScope).Type) -> (any PrimerFormRedirectScope)?
  func getPaymentMethodScope(_ scopeType: (any PrimerBillingAddressRedirectScope).Type)
    -> (any PrimerBillingAddressRedirectScope)?
  func getPaymentMethodScope(_ scopeType: (any PrimerApplePayScope).Type) -> (any PrimerApplePayScope)?
  func getPaymentMethodScope(_ scopeType: (any PrimerPayPalScope).Type) -> (any PrimerPayPalScope)?
  func getPaymentMethodScope(_ scopeType: (any PrimerQRCodeScope).Type) -> (any PrimerQRCodeScope)?
  func getPaymentMethodScope(_ scopeType: (any PrimerAchScope).Type) -> (any PrimerAchScope)?

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

// MARK: - Default no-op implementations
//
// Each per-protocol overload defaults to nil so SDK test-mock conformers don't have to stub all
// ten. The SDK's `DefaultCheckoutScope` overrides every one with the real cache-backed lookup.

@available(iOS 15.0, *)
extension PrimerCheckoutScope {
  func getPaymentMethodScope(_: (any PrimerCardFormScope).Type) -> (any PrimerCardFormScope)? { nil }
  func getPaymentMethodScope(_: (any PrimerKlarnaScope).Type) -> (any PrimerKlarnaScope)? { nil }
  func getPaymentMethodScope(_: (any PrimerAdyenKlarnaScope).Type) -> (any PrimerAdyenKlarnaScope)? { nil }
  func getPaymentMethodScope(_: (any PrimerWebRedirectScope).Type) -> (any PrimerWebRedirectScope)? { nil }
  func getPaymentMethodScope(_: (any PrimerFormRedirectScope).Type) -> (any PrimerFormRedirectScope)? { nil }
  func getPaymentMethodScope(_: (any PrimerBillingAddressRedirectScope).Type)
    -> (any PrimerBillingAddressRedirectScope)? { nil }
  func getPaymentMethodScope(_: (any PrimerApplePayScope).Type) -> (any PrimerApplePayScope)? { nil }
  func getPaymentMethodScope(_: (any PrimerPayPalScope).Type) -> (any PrimerPayPalScope)? { nil }
  func getPaymentMethodScope(_: (any PrimerQRCodeScope).Type) -> (any PrimerQRCodeScope)? { nil }
  func getPaymentMethodScope(_: (any PrimerAchScope).Type) -> (any PrimerAchScope)? { nil }
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
/// When switching on this enum, always include a `default` case to handle future additions.
@available(iOS 15.0, *)
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
