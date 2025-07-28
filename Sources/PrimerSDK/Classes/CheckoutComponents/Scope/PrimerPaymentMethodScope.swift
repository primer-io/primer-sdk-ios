//
//  PrimerPaymentMethodScope.swift
//  PrimerSDK
//
//  Created by Boris on 26.6.25.
//

import SwiftUI
import Foundation

/// Base protocol for all payment method scopes, providing common lifecycle and state management.
/// This protocol enables unified payment method handling with type-safe scope associations.
@available(iOS 15.0, *)
@MainActor
public protocol PrimerPaymentMethodScope: AnyObject {

    /// The type of state this scope manages
    associatedtype State: Equatable

    /// The current state of the payment method scope as an async stream.
    var state: AsyncStream<State> { get }

    // MARK: - Lifecycle Methods

    /// Starts the payment method flow and initializes the scope.
    /// Called when the payment method is selected and the scope becomes active.
    func start()

    /// Submits the payment method for processing.
    /// Called when the user confirms the payment with this method.
    func submit()

    /// Cancels the payment method flow and returns to payment method selection.
    /// Called when the user cancels or navigates back.
    func cancel()

    // MARK: - Navigation Support

    /// Called when the scope should handle navigation back to the previous screen.
    /// Default implementation calls cancel().
    func onBack()

    /// Called when the scope should dismiss itself (e.g., on error or completion).
    /// Default implementation calls cancel().
    func onDismiss()
}

// MARK: - Default Implementations

@available(iOS 15.0, *)
extension PrimerPaymentMethodScope {

    /// Default implementation navigates back by canceling the current flow.
    public func onBack() {
        cancel()
    }

    /// Default implementation dismisses by canceling the current flow.
    public func onDismiss() {
        cancel()
    }
}

// MARK: - Payment Method Protocol

/// Protocol for payment method implementations that can create their associated scopes.
/// Enables self-registration and dynamic scope creation for different payment methods.
@available(iOS 15.0, *)
public protocol PaymentMethodProtocol {

    /// The type of scope this payment method creates
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

    /// Provides custom UI for this payment method using ViewBuilder.
    /// - Parameter content: A ViewBuilder closure that uses the payment method's scope as a parameter,
    ///                      allowing full access to the payment method's state and behavior.
    @MainActor
    func content<V: View>(@ViewBuilder content: @escaping (ScopeType) -> V) -> AnyView

    /// Provides the default UI implementation for this payment method.
    @MainActor
    func defaultContent() -> AnyView
}

// MARK: - Payment Method Type Extensions

/// Extension to provide CheckoutComponents-specific functionality to PrimerPaymentMethodType
@available(iOS 15.0, *)
extension PrimerPaymentMethodType {
    /// Human-readable display name for the payment method in CheckoutComponents
    public var checkoutComponentsDisplayName: String {
        switch self {
        case .paymentCard:
            return "Card"
        case .applePay:
            return "Apple Pay"
        case .googlePay:
            return "Google Pay"
        case .payPal:
            return "PayPal"
        default:
            return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

// MARK: - Payment Method Registry

/// Registry for managing payment method implementations and their scope creation.
/// Provides dynamic scope creation based on payment method types.
@available(iOS 15.0, *)
@MainActor
internal class PaymentMethodRegistry: LogReporter {

    /// Type-erased payment method creator function
    private typealias ScopeCreator = @MainActor (PrimerCheckoutScope, any ContainerProtocol) throws -> any PrimerPaymentMethodScope

    /// Registry mapping payment method types to their scope creators
    private var creators: [String: ScopeCreator] = [:]

    /// Registry mapping scope types to their payment method identifiers
    private var typeToIdentifier: [String: String] = [:]

    /// Shared instance for global registration
    static let shared = PaymentMethodRegistry()

    private init() {}

    /// Registers a payment method implementation
    /// - Parameter paymentMethodType: The payment method implementation to register
    func register<T: PaymentMethodProtocol>(_ paymentMethodType: T.Type) {
        let typeKey = paymentMethodType.paymentMethodType
        creators[typeKey] = { checkoutScope, diContainer in
            try paymentMethodType.createScope(checkoutScope: checkoutScope, diContainer: diContainer)
        }

        // Register type-to-identifier mapping for type-safe lookups
        let scopeTypeName = String(describing: T.ScopeType.self)
        typeToIdentifier[scopeTypeName] = typeKey

        // PAYMENT METHOD OPTIONS INTEGRATION: Log when payment methods requiring settings are registered
        if typeKey == PrimerPaymentMethodType.applePay.rawValue {
            // Apple Pay payment method registered - will require ApplePayOptions from settings
            logger.info(message: "✅ [PaymentMethodRegistry] Apple Pay payment method registered - requires PrimerSettings.paymentMethodOptions.applePayOptions configuration")
        } else if typeKey == PrimerPaymentMethodType.googlePay.rawValue {
            // Google Pay payment method registered - could use URL scheme for redirects
            logger.info(message: "✅ [PaymentMethodRegistry] Google Pay payment method registered - may use URL scheme from PrimerSettings")
        } else if typeKey.contains("STRIPE") {
            // Stripe payment method registered - will require StripeOptions from settings
            logger.info(message: "✅ [PaymentMethodRegistry] Stripe payment method (\(typeKey)) registered - requires PrimerSettings.paymentMethodOptions.stripeOptions configuration")
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
        return try createScope(for: methodType.rawValue, checkoutScope: checkoutScope, diContainer: diContainer)
    }

    /// Returns all registered payment method types
    var registeredTypes: [String] {
        Array(creators.keys)
    }
}
