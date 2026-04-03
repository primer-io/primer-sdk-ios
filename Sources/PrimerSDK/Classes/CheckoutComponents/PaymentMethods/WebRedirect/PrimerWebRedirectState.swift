//
//  PrimerWebRedirectState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Web redirect flow: `idle` -> `loading` -> `redirecting` -> `polling` -> `success` | `failure`
@available(iOS 15.0, *)
public struct PrimerWebRedirectState: Equatable, @unchecked Sendable {

  /// When switching on this enum, always include a `default` case to handle future additions.
  public enum Status: Equatable {
    case idle
    case loading
    case redirecting
    case polling
    case success
    case failure(String)
  }

  public internal(set) var status: Status
  public internal(set) var paymentMethod: CheckoutPaymentMethod?
  public internal(set) var surchargeAmount: String?

  public init(
    status: Status = .idle,
    paymentMethod: CheckoutPaymentMethod? = nil,
    surchargeAmount: String? = nil
  ) {
    self.status = status
    self.paymentMethod = paymentMethod
    self.surchargeAmount = surchargeAmount
  }
}
