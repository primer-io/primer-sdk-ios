//
//  PrimerPaymentMethodScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import Foundation

/// Base protocol for all payment method scopes, providing common lifecycle and state management.
/// This protocol enables unified payment method handling with type-safe scope associations.
@available(iOS 15.0, *)
@MainActor
public protocol PrimerPaymentMethodScope: AnyObject {

    associatedtype State: Equatable

    /// The current state of the payment method scope as an async stream.
    var state: AsyncStream<State> { get }

    // MARK: - Lifecycle Methods

    /// Called when the payment method is selected and the scope becomes active.
    func start()

    /// Called when the user confirms the payment with this method.
    func submit()

    /// Called when the user cancels or navigates back.
    func cancel()

    // MARK: - Navigation Support

    /// Default implementation calls cancel().
    func onBack()

    /// Default implementation calls cancel().
    func onDismiss()
}

// MARK: - Default Implementations

@available(iOS 15.0, *)
extension PrimerPaymentMethodScope {

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

    private typealias ScopeCreator = @MainActor (PrimerCheckoutScope, any ContainerProtocol) throws -> any PrimerPaymentMethodScope
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
            logger.info(message: "✅ [PaymentMethodRegistry] Apple Pay registered - requires PrimerSettings.paymentMethodOptions.applePayOptions")
        } else if typeKey == PrimerPaymentMethodType.klarna.rawValue || typeKey == PrimerPaymentMethodType.primerTestKlarna.rawValue {
            logger.info(message: "✅ [PaymentMethodRegistry] Klarna registered - requires PrimerSettings.paymentMethodOptions.klarnaOptions")
        } else if typeKey.contains("STRIPE") {
            logger.info(message: "✅ [PaymentMethodRegistry] Stripe (\(typeKey)) registered - requires PrimerSettings.paymentMethodOptions.stripeOptions")
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

        return try createScope(for: paymentMethodType, checkoutScope: checkoutScope, diContainer: diContainer)
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
        try createScope(for: methodType.rawValue, checkoutScope: checkoutScope, diContainer: diContainer)
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

    /// Resets the registry by clearing all registered payment methods.
    /// This method is intended for testing purposes only.
    func reset() {
        creators.removeAll()
        viewBuilders.removeAll()
        typeToIdentifier.removeAll()
    }
}
