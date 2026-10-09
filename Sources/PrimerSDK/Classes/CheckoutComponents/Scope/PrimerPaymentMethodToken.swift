//
//  PrimerPaymentMethodToken.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

/// A payment method saved without a payment, delivered in ``PrimerCheckoutState/vaulted(_:)``.
@available(iOS 15.0, *)
public struct PrimerPaymentMethodToken: Sendable, Equatable {
  /// The multi-use token. Store it on your backend and charge it later.
  public let token: String
  /// The payment method type the shopper saved, for example `"PAYMENT_CARD"` or `"KLARNA"`.
  public let paymentMethodType: String

  public init(token: String, paymentMethodType: String) {
    self.token = token
    self.paymentMethodType = paymentMethodType
  }
}
