//
//  PrimerQRCodeScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
public typealias QRCodeScreenComponent = (any PrimerQRCodeScope) -> any View

@available(iOS 15.0, *)
@MainActor
public protocol PrimerQRCodeScope: PrimerPaymentMethodScope where State == QRCodeState {

  var state: AsyncStream<QRCodeState> { get }
  var presentationContext: PresentationContext { get }
  var dismissalMechanism: [DismissalMechanism] { get }
  var screen: QRCodeScreenComponent? { get set }

  // MARK: - Payment Method Lifecycle

  func start()

  // MARK: - Navigation Methods

  func onBack()
  func onCancel()
}
