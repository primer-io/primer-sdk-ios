//
//  PrimerShippingCallbacks.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Express Checkout shipping hooks for Apple Pay. Pass them to ``PrimerCheckoutSession``,
/// ``PrimerCheckout`` or ``PrimerCheckoutPresenter`` and enable shipping through
/// `PrimerApplePayOptions.ShippingOptions`.
///
/// Both callbacks run while the Apple Pay sheet is open and must return within 20 seconds; a slower
/// response fails the attempt with an in-sheet error and nothing is charged.
///
/// ```swift
/// let session = PrimerCheckoutSession(clientToken: token)
/// session.shippingCallbacks = PrimerShippingCallbacks(
///   onShippingAddressChange: { address in try await api.shippingOptions(for: address) },
///   onShippingOptionChange: { option in try await api.commitShipping(option) }
/// )
/// ```
///
/// - Parameters:
///   - onShippingAddressChange: Called when the sheet opens and whenever the shopper changes the
///     shipping address. Apple redacts the address before authorization, so expect only country,
///     postal code, city and state. Return the options available for it; an empty list shows Apple
///     Pay's "cannot deliver to this address" message. When `nil`, no options are shown and a
///     warning is logged.
///   - onShippingOptionChange: Called when the shopper selects one of your options, and for the
///     default option as soon as the list is shown. Have your backend `PATCH` the client session
///     with `order.shipping.methodId`, `order.shipping.amount` and any tax changes, then return.
///     The SDK re-reads the session, verifies the shipping matches ``PrimerShippingOption/id`` and
///     ``PrimerShippingOption/amount``, refreshes the sheet total, and only then allows
///     authorization. When `nil`, the shipping amount is never committed and a warning is logged.
@available(iOS 15.0, *)
public struct PrimerShippingCallbacks: Sendable {

  public let onShippingAddressChange: (@Sendable (PrimerAddress) async throws -> [PrimerShippingOption])?
  public let onShippingOptionChange: (@Sendable (PrimerShippingOption) async throws -> Void)?

  public init(
    onShippingAddressChange: (@Sendable (PrimerAddress) async throws -> [PrimerShippingOption])? = nil,
    onShippingOptionChange: (@Sendable (PrimerShippingOption) async throws -> Void)? = nil
  ) {
    self.onShippingAddressChange = onShippingAddressChange
    self.onShippingOptionChange = onShippingOptionChange
  }
}

/// `PrimerAddress` is a final class whose stored properties are all immutable and `Sendable`; the
/// `NSObject` base is what prevents the compiler inferring the conformance.
extension PrimerAddress: @unchecked Sendable {}
