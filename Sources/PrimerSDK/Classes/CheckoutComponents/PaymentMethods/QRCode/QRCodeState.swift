//
//  QRCodeState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// State for QR code payment methods (e.g., PromptPay, Xfers).
///
/// Tracks the QR code generation and payment polling lifecycle.
///
/// ## Flow
/// ```
/// loading → displaying → success | failure
/// ```
@available(iOS 15.0, *)
public struct QRCodeState: Equatable {

  /// The current status of the QR code payment flow.
  public enum Status: Equatable {
    /// QR code is being generated.
    case loading
    /// QR code is displayed and the SDK is polling for payment completion.
    case displaying
    /// Payment completed successfully.
    case success
    /// Payment failed with the given error message.
    case failure(String)
  }

  /// Current payment status.
  public var status: Status

  /// The payment method details, if available.
  public var paymentMethod: CheckoutPaymentMethod?

  /// The QR code image data (PNG format) to display. Available when status is `.displaying`.
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
