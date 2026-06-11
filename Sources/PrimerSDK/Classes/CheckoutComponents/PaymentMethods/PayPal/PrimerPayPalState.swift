//
//  PrimerPayPalState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// PayPal flow: `idle` -> `loading` -> `redirecting` -> `processing` -> `success` | `failure`
@available(iOS 15.0, *)
struct PrimerPayPalState: Equatable, @unchecked Sendable {

  /// When switching on this enum, always include a `default` case to handle future additions.
  enum Step: Equatable {
    case idle
    case loading
    case redirecting
    case processing
    case success
    case failure(String)
  }

  var step: Step
  var paymentMethod: CheckoutPaymentMethod?
  var surchargeAmount: String?

  init(
    step: Step = .idle,
    paymentMethod: CheckoutPaymentMethod? = nil,
    surchargeAmount: String? = nil
  ) {
    self.step = step
    self.paymentMethod = paymentMethod
    self.surchargeAmount = surchargeAmount
  }
}
