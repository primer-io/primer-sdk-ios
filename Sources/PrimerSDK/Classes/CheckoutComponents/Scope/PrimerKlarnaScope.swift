//
//  PrimerKlarnaScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Closure that provides a custom screen for Klarna payment steps.
@available(iOS 15.0, *)
public typealias KlarnaScreenComponent = (any PrimerKlarnaScope) -> any View

/// Closure that provides a custom button for Klarna payment actions.
@available(iOS 15.0, *)
public typealias KlarnaButtonComponent = (any PrimerKlarnaScope) -> any View

/// Scope protocol for Klarna payment methods.
///
/// Klarna payments follow a multi-step flow:
/// 1. **Category selection** — user picks a Klarna payment category (Pay Now, Pay Later, etc.)
/// 2. **Authorization** — Klarna SDK renders the payment view for user approval
/// 3. **Finalization** — completes the payment after authorization
///
/// Observe `state` to track the current step:
/// ```swift
/// for await klarnaState in klarnaScope.state {
///     switch klarnaState.step {
///     case .categorySelection:
///         showCategories(klarnaState.categories)
///     case .viewReady:
///         displayKlarnaPaymentView(klarnaScope.paymentView)
///     case .awaitingFinalization:
///         klarnaScope.finalizePayment()
///     }
/// }
/// ```
@available(iOS 15.0, *)
@MainActor
public protocol PrimerKlarnaScope: PrimerPaymentMethodScope where State == PrimerKlarnaState {

  /// Async stream of Klarna payment state including current step and available categories.
  var state: AsyncStream<PrimerKlarnaState> { get }

  /// The Klarna SDK payment view. Display this when `state.step` is `.viewReady`.
  var paymentView: UIView? { get }

  // MARK: - Payment Flow Actions

  /// Selects a Klarna payment category and loads the corresponding payment view.
  /// - Parameter categoryId: The identifier of the selected Klarna payment category.
  func selectPaymentCategory(_ categoryId: String)

  /// Authorizes the Klarna payment after the user completes the payment view.
  func authorizePayment()

  /// Finalizes the Klarna payment. Call when `state.step` is `.awaitingFinalization`.
  func finalizePayment()

  // MARK: - Screen-Level Customization

  /// Replaces the entire Klarna screen with a custom view.
  var screen: KlarnaScreenComponent? { get set }

  /// Replaces the authorize button with a custom view.
  var authorizeButton: KlarnaButtonComponent? { get set }

  /// Replaces the finalize button with a custom view.
  var finalizeButton: KlarnaButtonComponent? { get set }
}
