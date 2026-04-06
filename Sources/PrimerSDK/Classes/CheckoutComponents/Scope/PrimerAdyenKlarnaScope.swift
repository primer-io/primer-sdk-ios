//
//  PrimerAdyenKlarnaScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Type alias for Adyen Klarna screen customization component.
@available(iOS 15.0, *)
public typealias AdyenKlarnaScreenComponent = (any PrimerAdyenKlarnaScope) -> any View

/// Type alias for Adyen Klarna button customization component.
@available(iOS 15.0, *)
public typealias AdyenKlarnaButtonComponent = (any PrimerAdyenKlarnaScope) -> any View

/// Scope protocol for the Adyen Klarna payment method.
///
/// Provides state observation, payment option selection, and UI customization for
/// Klarna payments routed through Adyen. The user selects a Klarna payment option
/// (e.g., Pay Later, Slice It), then is redirected to complete payment.
///
/// ## State Flow
/// ```
/// idle → loading → optionSelection → submitting → redirecting → polling → success | failure
/// ```
///
/// ## Usage
/// ```swift
/// if let adyenKlarnaScope: PrimerAdyenKlarnaScope = checkoutScope.getPaymentMethodScope(
///   for: .adyenKlarna
/// ) {
///   for await state in adyenKlarnaScope.state {
///     switch state.status {
///     case .optionSelection:
///       // Show payment option picker
///       for option in state.paymentOptions {
///         Button(option.name) {
///           adyenKlarnaScope.selectOption(option)
///         }
///       }
///     case .success:
///       print("Payment completed")
///     default:
///       break
///     }
///   }
/// }
/// ```
@available(iOS 15.0, *)
@MainActor
public protocol PrimerAdyenKlarnaScope: PrimerPaymentMethodScope where State == PrimerAdyenKlarnaState {

    /// The payment method type identifier (`"ADYEN_KLARNA"`).
    var paymentMethodType: String { get }

    /// Selects a Klarna payment option and initiates the redirect payment flow.
    func selectOption(_ option: AdyenKlarnaPaymentOption)

    // MARK: - Screen-Level Customization

    /// Custom screen component to replace the entire Adyen Klarna screen.
    var screen: AdyenKlarnaScreenComponent? { get set }

    /// Custom button component to replace the submit button.
    var payButton: AdyenKlarnaButtonComponent? { get set }

    /// Custom text for the submit button.
    var submitButtonText: String? { get set }
}
