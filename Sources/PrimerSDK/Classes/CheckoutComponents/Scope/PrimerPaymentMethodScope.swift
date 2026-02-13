//
//  PrimerPaymentMethodScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import SwiftUI

/// Base protocol for all payment method scopes, providing common lifecycle and state management.
///
/// Every payment method scope follows a consistent lifecycle:
/// 1. **`start()`** — Initialize the payment flow (load data, set up state).
/// 2. **User interaction** — The user fills in details or approves the payment.
/// 3. **`submit()`** — Validate input and trigger tokenization/payment processing.
/// 4. **`cancel()`** — Terminate the flow at any point (called by navigation helpers).
///
/// Observe `state` to react to changes in the payment method's progress:
/// ```swift
/// for await currentState in scope.state {
///     updateUI(for: currentState)
/// }
/// ```
@available(iOS 15.0, *)
@MainActor
public protocol PrimerPaymentMethodScope: AnyObject {

  associatedtype State: Equatable

  /// Async stream emitting the payment method's current state whenever it changes.
  var state: AsyncStream<State> { get }

  // MARK: - Presentation

  /// How this scope was presented (determines back vs cancel button).
  var presentationContext: PresentationContext { get }

  /// Available dismissal mechanisms (close button, gestures).
  var dismissalMechanism: [DismissalMechanism] { get }

  // MARK: - Lifecycle Methods

  /// Initializes the payment flow for this method.
  ///
  /// Call once when the scope becomes active (e.g., user selects this payment method).
  /// Implementations typically load remote configuration, prepare the UI state,
  /// and emit the first state update on the `state` stream.
  func start()

  /// Validates input and begins payment processing.
  ///
  /// Call after the user has completed all required input. Implementations validate
  /// fields, then trigger tokenization and server-side payment creation.
  /// The state stream reflects progress (e.g., loading indicators, success, or errors).
  func submit()

  /// Terminates the payment flow and cleans up resources.
  ///
  /// Safe to call at any point. After cancellation the scope should not emit further
  /// state updates. Navigation helpers (`onBack`, `onDismiss`) call this by default.
  func cancel()

  // MARK: - Navigation Support

  /// Navigates back to the previous screen. Default implementation calls `cancel()`.
  func onBack()

  /// Handles dismissal (e.g., close button tap). Default implementation calls `cancel()`.
  func onDismiss()
}

// MARK: - Default Implementations

@available(iOS 15.0, *)
extension PrimerPaymentMethodScope {

  public var presentationContext: PresentationContext { .fromPaymentSelection }

  public var dismissalMechanism: [DismissalMechanism] { [] }

  public func onBack() {
    cancel()
  }

  public func onDismiss() {
    cancel()
  }
}

// MARK: - Payment Method Protocol

/// Protocol for payment method implementations that can create their associated scopes.
/// Enables self-registration and dynamic scope creation for different payment methods.
@available(iOS 15.0, *)
public protocol PaymentMethodProtocol {

  associatedtype ScopeType: PrimerPaymentMethodScope

  /// The payment method type identifier (e.g., "PAYMENT_CARD", "PAYPAL", "APPLE_PAY")
  static var paymentMethodType: String { get }

  /// Creates a scope instance for this payment method
  /// - Parameters:
  ///   - checkoutScope: The parent checkout scope for navigation and coordination
  ///   - diContainer: The dependency injection container for resolving services
  /// - Returns: A configured scope instance for this payment method
  @MainActor
  static func createScope(
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol
  ) throws -> ScopeType

  /// Creates the view for this payment method by retrieving its scope and rendering the appropriate UI.
  /// This method handles both custom screens (if provided) and default screens.
  /// - Parameter checkoutScope: The parent checkout scope that manages this payment method
  /// - Returns: The view for this payment method, or nil if the scope cannot be retrieved
  @MainActor
  static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView?

  /// Provides custom UI for this payment method using ViewBuilder.
  /// - Parameter content: A ViewBuilder closure that uses the payment method's scope as a parameter,
  ///                      allowing full access to the payment method's state and behavior.
  @MainActor
  func content<V: View>(@ViewBuilder content: @escaping (ScopeType) -> V) -> AnyView

  /// Provides the default UI implementation for this payment method.
  @MainActor
  func defaultContent() -> AnyView
}

// MARK: - Payment Method Registry

/// Registry for managing payment method implementations and their scope creation.
/// Provides dynamic scope creation based on payment method types.
@available(iOS 15.0, *)
@MainActor
class PaymentMethodRegistry: LogReporter {

  private typealias ScopeCreator =
    @MainActor (PrimerCheckoutScope, any ContainerProtocol) throws -> any PrimerPaymentMethodScope
  private typealias ViewCreator = @MainActor (any PrimerCheckoutScope) -> AnyView?

  private var creators: [String: ScopeCreator] = [:]
  private var viewBuilders: [String: ViewCreator] = [:]
  private var typeToIdentifier: [String: String] = [:]

  static let shared = PaymentMethodRegistry()

  private init() {}

  /// Registers a payment method implementation
  /// - Parameter paymentMethodType: The payment method implementation to register
  func register<T: PaymentMethodProtocol>(_ paymentMethodType: T.Type) {
    let typeKey = paymentMethodType.paymentMethodType
    creators[typeKey] = { checkoutScope, diContainer in
      try paymentMethodType.createScope(checkoutScope: checkoutScope, diContainer: diContainer)
    }

    // Register view builder for dynamic UI creation
    viewBuilders[typeKey] = { checkoutScope in
      paymentMethodType.createView(checkoutScope: checkoutScope)
    }

    // Register type-to-identifier mapping for type-safe lookups
    let scopeTypeName = String(describing: T.ScopeType.self)
    typeToIdentifier[scopeTypeName] = typeKey

    // PAYMENT METHOD OPTIONS INTEGRATION: Log when payment methods requiring special settings are registered
    // Based on PrimerPaymentMethodOptionsProtocol: applePayOptions, klarnaOptions, stripeOptions
    if typeKey == PrimerPaymentMethodType.applePay.rawValue {
      logger.info(
        message:
          "✅ [PaymentMethodRegistry] Apple Pay registered - requires PrimerSettings.paymentMethodOptions.applePayOptions"
      )
    } else if typeKey == PrimerPaymentMethodType.klarna.rawValue
      || typeKey == PrimerPaymentMethodType.primerTestKlarna.rawValue
    {
      logger.info(
        message:
          "✅ [PaymentMethodRegistry] Klarna registered - requires PrimerSettings.paymentMethodOptions.klarnaOptions"
      )
    } else if typeKey.contains("STRIPE") {
      logger.info(
        message:
          "✅ [PaymentMethodRegistry] Stripe (\(typeKey)) registered - requires PrimerSettings.paymentMethodOptions.stripeOptions"
      )
    } else {
      logger.debug(message: "✅ [PaymentMethodRegistry] Payment method \(typeKey) registered")
    }
  }

  /// Creates a scope for the specified payment method type (type-erased)
  /// - Parameters:
  ///   - paymentMethodType: The payment method type identifier
  ///   - checkoutScope: The parent checkout scope
  ///   - diContainer: The dependency injection container
  /// - Returns: A configured scope instance, or nil if the payment method is not registered
  func createScope(
    for paymentMethodType: String,
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol
  ) throws -> (any PrimerPaymentMethodScope)? {
    guard let creator = creators[paymentMethodType] else {
      return nil
    }

    return try creator(checkoutScope, diContainer)
  }

  /// Creates a scope for the specified payment method type (generic)
  /// - Parameters:
  ///   - paymentMethodType: The payment method type identifier
  ///   - checkoutScope: The parent checkout scope
  ///   - diContainer: The dependency injection container
  /// - Returns: A configured scope instance, or nil if the payment method is not registered
  func createScope<T: PrimerPaymentMethodScope>(
    for paymentMethodType: String,
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol
  ) throws -> T? {
    guard let creator = creators[paymentMethodType] else {
      return nil
    }

    let scope = try creator(checkoutScope, diContainer)
    return scope as? T
  }

  /// Creates a scope for the specified scope type (type-safe with metatype)
  /// - Parameters:
  ///   - scopeType: The scope type to create (e.g., PrimerCardFormScope.self)
  ///   - checkoutScope: The parent checkout scope
  ///   - diContainer: The dependency injection container
  /// - Returns: A configured scope instance, or nil if the scope type is not registered
  func createScope<T: PrimerPaymentMethodScope>(
    _ scopeType: T.Type,
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol
  ) throws -> T? {
    let typeName = String(describing: scopeType)
    guard let paymentMethodType = typeToIdentifier[typeName] else {
      return nil
    }

    return try createScope(
      for: paymentMethodType, checkoutScope: checkoutScope, diContainer: diContainer)
  }

  /// Creates a scope for the specified payment method enum case
  /// - Parameters:
  ///   - methodType: The payment method type enum case
  ///   - checkoutScope: The parent checkout scope
  ///   - diContainer: The dependency injection container
  /// - Returns: A configured scope instance, or nil if the payment method is not registered
  func createScope<T: PrimerPaymentMethodScope>(
    for methodType: PrimerPaymentMethodType,
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol
  ) throws -> T? {
    try createScope(
      for: methodType.rawValue, checkoutScope: checkoutScope, diContainer: diContainer)
  }

  var registeredTypes: [String] {
    Array(creators.keys)
  }

  /// Retrieves the view for a specific payment method type
  /// - Parameters:
  ///   - paymentMethodType: The payment method type identifier
  ///   - checkoutScope: The parent checkout scope
  /// - Returns: The view for this payment method, or nil if not registered
  func getView(for paymentMethodType: String, checkoutScope: any PrimerCheckoutScope) -> AnyView? {
    guard let viewBuilder = viewBuilders[paymentMethodType] else {
      return nil
    }
    return viewBuilder(checkoutScope)
  }

  /// Internal registration method for direct creator registration.
  /// Used by payment methods that need parameterized registration (e.g., WebRedirect APMs).
  func registerInternal(
    typeKey: String,
    scopeCreator: @escaping @MainActor (PrimerCheckoutScope, any ContainerProtocol) throws -> any PrimerPaymentMethodScope,
    viewCreator: @escaping @MainActor (any PrimerCheckoutScope) -> AnyView?
  ) {
    creators[typeKey] = scopeCreator
    viewBuilders[typeKey] = viewCreator
  }

  /// Resets the registry by clearing all registered payment methods.
  /// This method is intended for testing purposes only.
  func reset() {
    creators.removeAll()
    viewBuilders.removeAll()
    typeToIdentifier.removeAll()
  }
}
