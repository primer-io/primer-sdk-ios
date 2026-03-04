//
//  PrimerAchScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

/// Closure that provides a custom screen for ACH payment steps.
@available(iOS 15.0, *)
public typealias AchScreenComponent = (any PrimerAchScope) -> any View

/// Closure that provides a custom button for ACH payment actions.
@available(iOS 15.0, *)
public typealias AchButtonComponent = (any PrimerAchScope) -> any View

/// Scope protocol for ACH bank payment methods (Stripe ACH).
///
/// ACH payments follow a multi-step flow:
/// 1. **User details collection** — first name, last name, email
/// 2. **Bank account collection** — presented via `bankCollectorViewController`
/// 3. **Mandate acceptance** — user reviews and accepts or declines the ACH mandate
///
/// Observe `state` to track the current step and react to transitions:
/// ```swift
/// for await achState in achScope.state {
///     switch achState.step {
///     case .userDetailsCollection:
///         showUserDetailsForm()
///     case .bankAccountCollection:
///         presentBankCollector(achScope.bankCollectorViewController)
///     case .mandateAcceptance:
///         showMandate(achState.mandateText)
///     case .processing:
///         showLoadingIndicator()
///     }
/// }
/// ```
@available(iOS 15.0, *)
@MainActor
public protocol PrimerAchScope: PrimerPaymentMethodScope where State == PrimerAchState {

  /// Async stream of ACH payment state including current step, user details, and validation.
  var state: AsyncStream<PrimerAchState> { get }

  /// The bank collector view controller provided by Stripe SDK.
  /// Present this when `state.step` is `.bankAccountCollection`.
  var bankCollectorViewController: UIViewController? { get }

  // MARK: - User Details Actions

  /// Updates the first name field value.
  func updateFirstName(_ value: String)

  /// Updates the last name field value.
  func updateLastName(_ value: String)

  /// Updates the email address field value.
  func updateEmailAddress(_ value: String)

  /// Validates and submits user details, advancing to bank account collection.
  func submitUserDetails()

  // MARK: - Mandate Actions

  /// Accepts the ACH mandate, proceeding to payment processing.
  func acceptMandate()

  /// Declines the ACH mandate, cancelling the payment flow.
  func declineMandate()

  // MARK: - Screen-Level Customization

  /// Replaces the entire ACH screen (all steps) with a custom view.
  var screen: AchScreenComponent? { get set }

  /// Replaces the user details collection screen with a custom view.
  var userDetailsScreen: AchScreenComponent? { get set }

  /// Replaces the mandate acceptance screen with a custom view.
  var mandateScreen: AchScreenComponent? { get set }

  /// Replaces the submit/continue button with a custom view.
  var submitButton: AchButtonComponent? { get set }
}
