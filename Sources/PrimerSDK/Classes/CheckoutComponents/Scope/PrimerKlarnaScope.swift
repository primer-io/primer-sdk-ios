//
//  PrimerKlarnaScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
public typealias KlarnaScreenComponent = (any PrimerKlarnaScope) -> any View

@available(iOS 15.0, *)
public typealias KlarnaButtonComponent = (any PrimerKlarnaScope) -> any View

@available(iOS 15.0, *)
@MainActor
public protocol PrimerKlarnaScope: PrimerPaymentMethodScope where State == KlarnaState {

  var state: AsyncStream<KlarnaState> { get }

  var presentationContext: PresentationContext { get }

  var dismissalMechanism: [DismissalMechanism] { get }

  var paymentView: UIView? { get }

  // MARK: - Payment Flow Actions

  func selectPaymentCategory(_ categoryId: String)

  func authorizePayment()

  func finalizePayment()

  // MARK: - Navigation Methods

  func onBack()

  func onCancel()

  // MARK: - Screen-Level Customization

  var screen: KlarnaScreenComponent? { get set }

  var authorizeButton: KlarnaButtonComponent? { get set }

  var finalizeButton: KlarnaButtonComponent? { get set }
}
