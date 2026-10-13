//
//  PrimerShippingOption.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// A shipping option your app offers for the shopper's address during Express Checkout.
///
/// - Parameters:
///   - id: Your identifier for the option. It is echoed back in
///     ``ShippingOptionChangeHandler`` and must match the `order.shipping.methodId`
///     your backend writes to the client session.
///   - name: Shown as the option's title in the wallet sheet.
///   - description: Shown under the title, for example "3-5 business days".
///   - amount: Shipping cost in minor units. Your backend must write the same value to
///     `order.shipping.amount`; the SDK verifies it after the commit.
@available(iOS 15.0, *)
public struct PrimerShippingOption: Equatable, Sendable {

  public let id: String
  public let name: String
  public let description: String
  public let amount: Int

  public init(id: String, name: String, description: String, amount: Int) {
    self.id = id
    self.name = name
    self.description = description
    self.amount = amount
  }
}
