//
//  PrimerQRCodeScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Type alias for QR code screen customization component.
@available(iOS 15.0, *)
public typealias QRCodeScreenComponent = (any PrimerQRCodeScope) -> any View

/// Scope protocol for QR code payment methods (e.g., PromptPay, Xfers).
///
/// Provides state observation and UI customization for payment methods that display
/// a QR code for the user to scan. The SDK automatically polls for completion
/// after the QR code is displayed.
///
/// ## State Flow
/// ```
/// loading → displaying → success | failure
/// ```
///
/// ## Usage
/// ```swift
/// if let qrScope = checkoutScope.getPaymentMethodScope(
///   PrimerQRCodeScope.self
/// ) {
///   for await state in qrScope.state {
///     if let imageData = state.qrCodeImageData {
///       // Display QR code image
///     }
///   }
/// }
/// ```
@available(iOS 15.0, *)
@MainActor
public protocol PrimerQRCodeScope: PrimerPaymentMethodScope where State == QRCodeState {

  /// Async stream emitting the current QR code state whenever it changes.
  var state: AsyncStream<QRCodeState> { get }

  /// Custom screen component to replace the entire QR code screen.
  var screen: QRCodeScreenComponent? { get set }
}
