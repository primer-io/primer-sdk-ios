//
//  PrimerWebRedirectState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Web redirect flow: `idle` -> `loading` -> `redirecting` -> `polling` -> `success` | `failure`
@available(iOS 15.0, *)
struct PrimerWebRedirectState: Equatable, @unchecked Sendable {

  /// When switching on this enum, always include a `default` case to handle future additions.
  enum Status: Equatable {
    case idle
    case loading
    case redirecting
    case polling
    case success
    case failure(String)
  }

  var status: Status
  var paymentMethod: CheckoutPaymentMethod?
  var surchargeAmount: String?

  init(
    status: Status = .idle,
    paymentMethod: CheckoutPaymentMethod? = nil,
    surchargeAmount: String? = nil
  ) {
    self.status = status
    self.paymentMethod = paymentMethod
    self.surchargeAmount = surchargeAmount
  }
}
