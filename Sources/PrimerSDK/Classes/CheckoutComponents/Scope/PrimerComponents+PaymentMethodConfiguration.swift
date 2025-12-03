//
//  PrimerComponents+PaymentMethodConfiguration.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - PaymentMethodConfiguration Protocol

/// Base protocol for all payment method configurations.
/// Each payment method type (card, PayPal, Apple Pay, etc.) conforms to this protocol
/// to provide customizable UI components within `PrimerComponents`.
///
/// ## Overview
/// Payment method configurations are stored in `PrimerComponents` and retrieved using
/// type-safe accessor methods:
///
/// ```swift
/// let components = PrimerComponents(
///     paymentMethodConfigurations: [
///         PrimerComponents.CardForm(title: "Card Payment"),
///         PrimerComponents.PayPal(buttonText: "Pay with PayPal")
///     ]
/// )
///
/// // Access via type-safe accessor
/// if let cardForm = components.configuration(for: PrimerComponents.CardForm.self) {
///     let title = cardForm.title ?? "Default Title"
/// }
/// ```
///
/// ## Conformance
/// Types conforming to this protocol must provide:
/// - A static `paymentMethodType` identifier matching `PrimerPaymentMethodType.rawValue`
///
/// Each payment method configuration defines its own scope-aware `screen` property
/// with the appropriate scope type for full customization access.
@available(iOS 15.0, *)
public protocol PaymentMethodConfiguration {

    /// The payment method type identifier.
    /// Must match the corresponding `PrimerPaymentMethodType.rawValue`.
    ///
    /// Example: `"PAYMENT_CARD"`, `"PAYPAL"`, `"APPLE_PAY"`
    static var paymentMethodType: String { get }
}
