//
//  QRCodeState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
public struct QRCodeState: Equatable {

  public enum Status: Equatable {
    case loading
    case displaying
    case success
    case failure(String)
  }

  public var status: Status
  public var paymentMethod: CheckoutPaymentMethod?
  public var qrCodeImageData: Data?

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
