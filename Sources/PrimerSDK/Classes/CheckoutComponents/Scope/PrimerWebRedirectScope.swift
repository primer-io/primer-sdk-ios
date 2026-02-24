//
//  PrimerWebRedirectScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Type alias for web redirect screen customization component.
@available(iOS 15.0, *)
public typealias WebRedirectScreenComponent = (any PrimerWebRedirectScope) -> any View

/// Type alias for web redirect button customization component.
@available(iOS 15.0, *)
public typealias WebRedirectButtonComponent = (any PrimerWebRedirectScope) -> any View

/// Scope protocol for web redirect payment methods (e.g., Twint).
///
/// Provides state observation and UI customization for payment methods that redirect
/// the user to an external web page to complete payment, then poll for the result.
///
/// ## State Flow
/// ```
/// idle → loading → redirecting → polling → success | failure
/// ```
///
/// ## Usage
/// ```swift
/// if let webRedirectScope = checkoutScope.getPaymentMethodScope(
///   PrimerWebRedirectScope.self
/// ) {
///   for await state in webRedirectScope.state {
///     switch state.status {
///     case .success:
///       print("Payment completed")
///     case .failure(let message):
///       print("Payment failed: \(message)")
///     default:
///       break
///     }
///   }
/// }
/// ```
@available(iOS 15.0, *)
@MainActor
public protocol PrimerWebRedirectScope: PrimerPaymentMethodScope where State == WebRedirectState {

    /// The payment method type identifier (e.g., "TWINT").
    var paymentMethodType: String { get }

    /// Async stream emitting the current web redirect state whenever it changes.
    var state: AsyncStream<WebRedirectState> { get }

    // MARK: - Screen-Level Customization

    /// Custom screen component to replace the entire web redirect screen.
    var screen: WebRedirectScreenComponent? { get set }

    /// Custom button component to replace the submit button.
    var payButton: WebRedirectButtonComponent? { get set }

    /// Custom text for the submit button (default: payment method specific).
    var submitButtonText: String? { get set }
}
