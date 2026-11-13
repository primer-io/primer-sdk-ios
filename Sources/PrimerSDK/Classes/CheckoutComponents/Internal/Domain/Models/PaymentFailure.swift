//
//  PaymentFailure.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation

/// A failed payment together with the payment the headless layer created before failing.
struct PaymentFailure: LocalizedError {
  let error: PrimerError
  let checkoutData: PrimerCheckoutData?

  var errorDescription: String? { error.errorDescription }
}

extension PaymentFailure {
  /// Splits a thrown error into the `PrimerError` and any payment carried alongside it.
  init(unwrapping error: Error) {
    self = error as? PaymentFailure
      ?? PaymentFailure(error: error as? PrimerError ?? .unknown(message: error.localizedDescription), checkoutData: nil)
  }
}

extension PrimerError {
  /// The payment a `.paymentFailed` decline was raised for, when the Payments API returned an id.
  var failedPaymentCheckoutData: PrimerCheckoutData? {
    guard case let .paymentFailed(_, paymentId, orderId, status, _) = self,
          !paymentId.isEmpty, paymentId != "unknown" else { return nil }
    return PrimerCheckoutData(
      payment: PrimerCheckoutDataPayment(id: paymentId, orderId: orderId, paymentFailureReason: nil, status: status)
    )
  }
}
