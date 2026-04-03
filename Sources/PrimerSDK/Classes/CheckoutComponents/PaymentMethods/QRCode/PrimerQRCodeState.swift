//
//  PrimerQRCodeState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// QR code flow: `loading` -> `displaying` -> `success` | `failure`
@available(iOS 15.0, *)
public struct PrimerQRCodeState: Equatable, @unchecked Sendable {

  /// When switching on this enum, always include a `default` case to handle future additions.
  public enum Status: Equatable {
    case loading
    case displaying
    case success
    case failure(String)
  }

  public internal(set) var status: Status
  public internal(set) var paymentMethod: CheckoutPaymentMethod?
  public internal(set) var qrCodeImageData: Data?

  public init(
    status: Status = .loading,
    paymentMethod: CheckoutPaymentMethod? = nil,
    qrCodeImageData: Data? = nil
  ) {
    self.status = status
    self.paymentMethod = paymentMethod
    self.qrCodeImageData = qrCodeImageData
  }
}
