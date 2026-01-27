//
//  PrimerKlarnaScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Type alias for Klarna screen customization component.
@available(iOS 15.0, *)
public typealias KlarnaScreenComponent = (any PrimerKlarnaScope) -> any View

/// Type alias for Klarna authorize button customization component.
@available(iOS 15.0, *)
public typealias KlarnaButtonComponent = (any PrimerKlarnaScope) -> any View

/// Scope protocol for Klarna payment method.
/// Provides state observation, category selection, authorization, and UI customization.
@available(iOS 15.0, *)
@MainActor
public protocol PrimerKlarnaScope: PrimerPaymentMethodScope where State == KlarnaState {

  /// The current state of the Klarna payment flow as an async stream.
  var state: AsyncStream<KlarnaState> { get }

  /// The presentation context determining navigation behavior (back button vs cancel button).
  var presentationContext: PresentationContext { get }

  /// The dismissal mechanisms available for this scope.
  var dismissalMechanism: [DismissalMechanism] { get }

  /// The Klarna SDK payment view for the selected category, if loaded.
  var paymentView: UIView? { get }

  // MARK: - Payment Flow Actions

  /// Selects a payment category and loads the corresponding Klarna SDK view.
  /// - Parameter categoryId: The identifier of the selected payment category.
  func selectPaymentCategory(_ categoryId: String)

  /// Authorizes the Klarna payment after the user has interacted with the SDK view.
  func authorizePayment()

  /// Finalizes the Klarna payment when authorization indicated finalization is required.
  func finalizePayment()

  // MARK: - Navigation Methods

  /// Called when user taps back button.
  func onBack()

  /// Called when user taps cancel/dismiss button.
  func onCancel()

  // MARK: - Screen-Level Customization

  /// Custom screen component to replace the entire Klarna screen.
  var screen: KlarnaScreenComponent? { get set }

  /// Custom authorize button component.
  var authorizeButton: KlarnaButtonComponent? { get set }

  /// Custom finalize button component.
  var finalizeButton: KlarnaButtonComponent? { get set }
}
