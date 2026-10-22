//
//  PrimerQRCodeState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// QR code flow: `loading` -> `displaying` -> `success` | `failure`
@available(iOS 15.0, *)
struct PrimerQRCodeState: Equatable, @unchecked Sendable {

  /// When switching on this enum, always include a `default` case to handle future additions.
  enum Status: Equatable {
    case loading
    case displaying
    case success
    case failure(String)
  }

  var status: Status
  var paymentMethod: CheckoutPaymentMethod?
  var qrCodeImageData: Data?

  init(
    status: Status = .loading,
    paymentMethod: CheckoutPaymentMethod? = nil,
    qrCodeImageData: Data? = nil
  ) {
    self.status = status
    self.paymentMethod = paymentMethod
    self.qrCodeImageData = qrCodeImageData
  }
}
