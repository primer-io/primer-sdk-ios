//
//  PrimerBankSelectorScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Scope protocol for bank selector payment methods (iDEAL, Dotpay).
/// Provides state observation, bank search/selection, and UI customization
/// for redirect-based bank payment flows.
@available(iOS 15.0, *)
@MainActor
public protocol PrimerBankSelectorScope: PrimerPaymentMethodScope where State == BankSelectorState {

  // MARK: - State Observation

  /// Asynchronous stream of bank selector state updates.
  /// Emits: loading -> ready -> selected
  var state: AsyncStream<BankSelectorState> { get }

  // MARK: - Presentation Context

  /// Determines navigation button behavior (back vs cancel).
  var presentationContext: PresentationContext { get }

  /// Dismissal mechanisms configured for this checkout session.
  var dismissalMechanism: [DismissalMechanism] { get }

  // MARK: - Lifecycle (inherited from PrimerPaymentMethodScope)

  /// Fetches the bank list from the API and transitions state to ready.
  func start()

  /// Tokenizes with the selected bank and delegates to checkout scope.
  /// For bank selector, this is triggered internally by selectBank(_:).
  func submit()

  /// Cancels the bank selection flow.
  func cancel()

  // MARK: - Bank Selection Actions

  /// Filters the displayed bank list by the given query string.
  /// Filtering is case-insensitive and diacritics-insensitive.
  /// Pass empty string to restore the full list.
  func search(query: String)

  /// Selects a bank and immediately initiates the payment flow.
  /// - Parameter bank: The bank to select (must not be disabled).
  func selectBank(_ bank: Bank)

  // MARK: - Navigation

  /// Navigates back to payment method selection (if fromPaymentSelection)
  /// or dismisses the checkout (if direct).
  func onBack()

  /// Dismisses the checkout entirely.
  func onCancel()

  // MARK: - UI Customization

  /// Replace the entire bank selector screen with a custom view.
  var screen: BankSelectorScreenComponent? { get set }

  /// Customize individual bank item rendering.
  var bankItemComponent: BankItemComponent? { get set }

  /// Customize the search bar appearance.
  var searchBarComponent: Component? { get set }

  /// Customize the empty state (no search results).
  var emptyStateComponent: Component? { get set }
}
