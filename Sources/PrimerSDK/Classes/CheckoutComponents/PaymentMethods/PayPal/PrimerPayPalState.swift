//
//  PrimerPayPalState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// PayPal flow: `idle` -> `loading` -> `redirecting` -> `processing` -> `success` | `failure`
@available(iOS 15.0, *)
public struct PrimerPayPalState: Equatable {

  public enum Step: Equatable {
    case idle
    case loading
    case redirecting
    case processing
    case success
    case failure(String)
  }

  public internal(set) var step: Step
  public internal(set) var paymentMethod: CheckoutPaymentMethod?
  public internal(set) var surchargeAmount: String?

  public init(
    step: Step = .idle,
    paymentMethod: CheckoutPaymentMethod? = nil,
    surchargeAmount: String? = nil
  ) {
    self.step = step
    self.paymentMethod = paymentMethod
    self.surchargeAmount = surchargeAmount
  }
}
