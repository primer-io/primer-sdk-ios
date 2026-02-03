//
//  PrimerPayPalScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Type alias for PayPal screen customization component.
@available(iOS 15.0, *)
public typealias PayPalScreenComponent = (any PrimerPayPalScope) -> any View

/// Type alias for PayPal button customization component.
@available(iOS 15.0, *)
public typealias PayPalButtonComponent = (any PrimerPayPalScope) -> any View

/// Scope protocol for PayPal payment method.
/// Provides state observation and UI customization for redirect-based PayPal payments.
@available(iOS 15.0, *)
@MainActor
public protocol PrimerPayPalScope: PrimerPaymentMethodScope where State == PayPalState {

  /// The current state of the PayPal payment flow as an async stream.
  var state: AsyncStream<PayPalState> { get }

  /// The presentation context determining navigation behavior (back button vs cancel button).
  var presentationContext: PresentationContext { get }

  /// The dismissal mechanisms available for this scope.
  var dismissalMechanism: [DismissalMechanism] { get }

  // MARK: - Payment Method Lifecycle

  /// Called when the payment method is selected and the scope becomes active.
  func start()

  /// Initiates the PayPal payment flow, opening web authentication.
  func submit()

  /// Cancels the PayPal payment flow.
  func cancel()

  // MARK: - Navigation Methods

  /// Called when user taps back button.
  func onBack()

  /// Called when user taps cancel/dismiss button.
  func onCancel()

  // MARK: - Screen-Level Customization

  /// Custom screen component to replace the entire PayPal screen.
  var screen: PayPalScreenComponent? { get set }

  /// Custom button component to replace the PayPal submit button.
  var payButton: PayPalButtonComponent? { get set }

  /// Custom text for the submit button (default: "Continue with PayPal").
  var submitButtonText: String? { get set }
}
