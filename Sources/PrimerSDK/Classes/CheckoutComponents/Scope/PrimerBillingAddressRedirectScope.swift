//
//  PrimerBillingAddressRedirectScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Type alias for billing address redirect screen customization component.
@available(iOS 15.0, *)
public typealias BillingAddressRedirectScreenComponent = (any PrimerBillingAddressRedirectScope) -> any View

/// Type alias for billing address redirect button customization component.
@available(iOS 15.0, *)
public typealias BillingAddressRedirectButtonComponent = (any PrimerBillingAddressRedirectScope) -> any View

/// Scope protocol for payment methods that require a billing address form before redirect (e.g., Affirm).
///
/// Provides billing address field management, state observation, and UI customization
/// for payment methods that collect a billing address before redirecting to an external
/// page to complete payment.
///
/// ## State Flow
/// ```
/// ready → submitting → redirecting → polling → success | failure
/// ```
///
/// ## Usage
/// ```swift
/// if let affirmScope = checkoutScope.getPaymentMethodScope(
///   PrimerBillingAddressRedirectScope.self
/// ) {
///   affirmScope.updateCountryCode("US")
///   affirmScope.updateAddressLine1("123 Main St")
///   affirmScope.updateCity("San Francisco")
///   affirmScope.updateState("CA")
///   affirmScope.updatePostalCode("94105")
///
///   for await state in affirmScope.state {
///     if state.isFormValid {
///       affirmScope.submit()
///     }
///   }
/// }
/// ```
@available(iOS 15.0, *)
@MainActor
public protocol PrimerBillingAddressRedirectScope: PrimerPaymentMethodScope
where State == PrimerBillingAddressRedirectState {

  var paymentMethodType: String { get }

  // MARK: - Billing Address Fields

  func updateCountryCode(_ value: String)
  func updateAddressLine1(_ value: String)
  func updateAddressLine2(_ value: String)
  func updatePostalCode(_ value: String)
  func updateCity(_ value: String)
  func updateState(_ value: String)

  // MARK: - Screen-Level Customization

  var screen: BillingAddressRedirectScreenComponent? { get set }
  var submitButton: BillingAddressRedirectButtonComponent? { get set }
  var submitButtonText: String? { get set }
}
