//
//  PrimerShippingAddressChange.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// The wallet sheet opened, or the shopper changed the shipping address. ``shippingAddress`` is
/// redacted by the wallet to country, postal code, city and state.
@available(iOS 15.0, *)
public struct PrimerShippingAddressChange: Sendable {

  public let paymentMethodType: String
  public let shippingAddress: PrimerAddress

  public init(paymentMethodType: String, shippingAddress: PrimerAddress) {
    self.paymentMethodType = paymentMethodType
    self.shippingAddress = shippingAddress
  }
}
