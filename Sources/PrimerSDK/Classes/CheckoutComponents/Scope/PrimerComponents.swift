//
//  PrimerComponents.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - PrimerComponents

/// Immutable configuration container for all UI customization options.
/// Configuration is frozen at initialization and cannot be modified at runtime.
///
/// ## Overview
/// `PrimerComponents` provides a central configuration point for customizing
/// checkout flow screens, payment method selection, and individual payment method forms.
///
/// ## Payment Method Configurations
/// Payment method-specific configurations (card form, PayPal, Apple Pay, etc.) are stored
/// using a protocol-based registry pattern. Use `configuration(for:)` to retrieve them:
///
/// ```swift
/// let components = PrimerComponents(
///     paymentMethodConfigurations: [
///         PrimerComponents.CardForm(title: "Card Payment"),
///         PrimerComponents.PayPal(buttonText: "Pay with PayPal")
///     ]
/// )
///
/// // Type-safe retrieval
/// if let cardForm = components.configuration(for: PrimerComponents.CardForm.self) {
///     print(cardForm.title ?? "Default title")
/// }
/// ```
@available(iOS 15.0, *)
public struct PrimerComponents {

    /// Checkout flow screens configuration
    public let checkout: Checkout

    /// Payment method selection screen configuration
    public let paymentMethodSelection: PaymentMethodSelection

    /// Custom container wrapper for checkout content
    public let container: ContainerComponent?

    /// Internal dictionary storage for O(1) lookup by payment method type
    private let paymentMethodConfigurations: [String: any PaymentMethodConfiguration]

    /// Creates a new PrimerComponents configuration.
    /// - Parameters:
    ///   - checkout: Checkout flow screens. Default: `Checkout()`
    ///   - paymentMethodSelection: Payment method picker. Default: `PaymentMethodSelection()`
    ///   - paymentMethodConfigurations: Payment method-specific configurations (card, PayPal, etc.). Default: empty array
    ///   - container: Content wrapper. Default: nil (no wrapper)
    public init(
        checkout: Checkout = Checkout(),
        paymentMethodSelection: PaymentMethodSelection = PaymentMethodSelection(),
        paymentMethodConfigurations: [any PaymentMethodConfiguration] = [],
        container: ContainerComponent? = nil
    ) {
        self.checkout = checkout
        self.paymentMethodSelection = paymentMethodSelection
        self.container = container

        // Build O(1) lookup dictionary from array
        var configDict: [String: any PaymentMethodConfiguration] = [:]
        for config in paymentMethodConfigurations {
            configDict[type(of: config).paymentMethodType] = config
        }
        self.paymentMethodConfigurations = configDict
    }

    // MARK: - Type-Safe Configuration Access

    /// Retrieves a payment method configuration by its concrete type.
    ///
    /// This is the primary method for accessing configurations in a type-safe manner.
    ///
    /// - Parameter type: The concrete configuration type to retrieve (e.g., `CardForm.self`)
    /// - Returns: The configuration instance if present, `nil` otherwise
    ///
    /// ## Example
    /// ```swift
    /// if let cardForm = components.configuration(for: PrimerComponents.CardForm.self) {
    ///     let title = cardForm.title ?? "Card Payment"
    /// }
    /// ```
    public func configuration<T: PaymentMethodConfiguration>(for type: T.Type) -> T? {
        guard let config = paymentMethodConfigurations[T.paymentMethodType] else {
            return nil
        }
        return config as? T
    }

    /// Retrieves a payment method configuration by its string identifier.
    ///
    /// - Parameter paymentMethodType: The payment method type identifier (e.g., `"PAYMENT_CARD"`)
    /// - Returns: The configuration instance if present, `nil` otherwise
    ///
    /// ## Example
    /// ```swift
    /// if let config = components.configuration(for: "PAYMENT_CARD") {
    ///     print("Found config for: \(type(of: config).paymentMethodType)")
    /// }
    /// ```
    public func configuration(for paymentMethodType: String) -> (any PaymentMethodConfiguration)? {
        paymentMethodConfigurations[paymentMethodType]
    }

    /// Retrieves a payment method configuration by its enum value.
    ///
    /// - Parameter paymentMethodType: The payment method type enum (e.g., `.paymentCard`)
    /// - Returns: The configuration instance if present, `nil` otherwise
    ///
    /// ## Example
    /// ```swift
    /// if let config = components.configuration(for: .paymentCard) {
    ///     print("Found config for payment card")
    /// }
    /// ```
    public func configuration(for paymentMethodType: PrimerPaymentMethodType) -> (any PaymentMethodConfiguration)? {
        paymentMethodConfigurations[paymentMethodType.rawValue]
    }

    /// Checks if a configuration exists for a specific payment method type.
    ///
    /// - Parameter paymentMethodType: The payment method type identifier
    /// - Returns: `true` if a configuration exists, `false` otherwise
    public func hasConfiguration(for paymentMethodType: String) -> Bool {
        paymentMethodConfigurations[paymentMethodType] != nil
    }

    /// All configured payment method type identifiers.
    public var configuredPaymentMethodTypes: [String] {
        Array(paymentMethodConfigurations.keys)
    }
}
