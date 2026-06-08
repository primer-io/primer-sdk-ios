//
//  PrimerSelectionSession.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Observable wrapper around the payment-method-selection scope.
///
/// Bridges the scope's `AsyncStream<PrimerPaymentMethodSelectionState>` into a `@Published` property
/// once, so `PrimerPaymentMethods` / `PrimerVaultedPaymentMethods` observe via `@ObservedObject`.
@available(iOS 15.0, *)
@MainActor
public final class PrimerSelectionSession: ObservableObject {

  /// The latest selection state, bridged from `scope.state`.
  @Published public private(set) var state: PrimerPaymentMethodSelectionState

  /// The selection behavior surface (method selection, vaulted actions, navigation).
  let scope: PrimerPaymentMethodSelectionScope

  private let internalScope: (any PaymentMethodSelectionScopeInternal)?
  private var observationTask: Task<Void, Never>?

  init(scope: PrimerPaymentMethodSelectionScope) {
    self.scope = scope
    internalScope = scope as? any PaymentMethodSelectionScopeInternal
    state = internalScope?.currentState ?? PrimerPaymentMethodSelectionState()
    observationTask = Task { @MainActor [weak self] in
      for await newState in scope.state {
        self?.state = newState
      }
    }
  }

  deinit {
    observationTask?.cancel()
  }

  /// Saved (vaulted) payment methods, loaded once during checkout initialization.
  public var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] {
    internalScope?.vaultedPaymentMethods ?? []
  }

  // MARK: - Selection

  /// Selects a payment method, starting its flow.
  public func select(_ method: CheckoutPaymentMethod) {
    scope.onPaymentMethodSelected(paymentMethod: method)
  }

  public func cancel() { scope.cancel() }

  // MARK: - Vaulted

  /// Marks a vaulted method as selected so a subsequent submit targets it.
  public func selectVaulted(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) {
    internalScope?.selectVaultedPaymentMethod(method)
  }

  /// Routes to the delete-confirmation screen for a vaulted method.
  public func delete(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) {
    internalScope?.navigateToDeleteConfirmation(method)
  }

  /// Navigates to the full list of saved payment methods.
  public func showAll() {
    scope.showAllVaultedPaymentMethods()
  }

  /// Updates and validates the CVV for the selected vaulted card during CVV recapture.
  /// Drives `state.cvvInput` / `state.isCvvValid` / `state.cvvError`.
  public func updateCvvInput(_ cvv: String) {
    scope.updateCvvInput(cvv)
  }

  /// Pays with the currently selected vaulted method. Used by the SDK's own vaulted submit button.
  /// When the card requires CVV recapture, the first call reveals the CVV field; the next call
  /// (once `state.isCvvValid`) submits with the captured CVV.
  func submitSelectedVaulted() async {
    await scope.payWithVaultedPaymentMethod()
  }
}
