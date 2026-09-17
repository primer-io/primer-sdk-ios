//
//  PrimerSelectionSession.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Observable wrapper around the payment-method-selection scope.
///
/// Bridges the scope's `AsyncStream<PrimerPaymentMethodSelectionState>` into a `@Published` property
/// once, so `PrimerPaymentMethods` / `PrimerVaultedPaymentMethods` observe via `@ObservedObject`.
@available(iOS 15.0, *)
@MainActor
public final class PrimerSelectionSession: ObservableObject {

  /// The latest selection state, bridged from `scope.state`.
  @Published public private(set) var state: PrimerPaymentMethodSelectionState

  /// The customer's saved (vaulted) payment methods.
  ///
  /// Published, so a list you build yourself re-renders when the set changes — after ``delete(_:)``,
  /// or when the SDK's own saved-methods screen deletes one.
  @Published public private(set) var vaultedPaymentMethods:
    [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]

  /// The selection behavior surface (method selection, vaulted actions, navigation).
  let scope: PrimerPaymentMethodSelectionScope

  private let internalScope: (any PaymentMethodSelectionScopeInternal)?
  private var observationTask: Task<Void, Never>?
  private var vaultObservationTask: Task<Void, Never>?

  init(scope: PrimerPaymentMethodSelectionScope) {
    self.scope = scope
    internalScope = scope as? any PaymentMethodSelectionScopeInternal
    state = internalScope?.currentState ?? PrimerPaymentMethodSelectionState()
    vaultedPaymentMethods = internalScope?.vaultedPaymentMethods ?? []
    observationTask = Task { @MainActor [weak self] in
      for await newState in scope.state {
        self?.state = newState
      }
    }
    vaultObservationTask = Task { @MainActor [weak self, internalScope] in
      guard let stream = internalScope?.vaultedPaymentMethodsStream else { return }
      for await methods in stream {
        self?.vaultedPaymentMethods = methods
      }
    }
  }

  deinit {
    observationTask?.cancel()
    vaultObservationTask?.cancel()
  }

  // MARK: - Selection

  /// Selects a payment method, starting its flow.
  public func select(_ method: CheckoutPaymentMethod) {
    scope.onPaymentMethodSelected(paymentMethod: method)
  }

  public func cancel() { scope.cancel() }

  // MARK: - Vaulted

  /// Pays with a saved payment method.
  ///
  /// This is the pay verb, so call it from your pay button rather than from a row tap. A card that
  /// needs CVV recapture raises the SDK's CVV screen first, and that screen finishes the payment.
  /// The outcome arrives through `.primerCheckoutSession(_:theme:onCompletion:)`.
  ///
  /// Keep which row looks selected in your own view state. Returns immediately; the payment runs on.
  public func selectVaulted(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) {
    internalScope?.selectVaultedPaymentMethod(method)
    Task { await scope.payWithVaultedPaymentMethod() }
  }

  /// Marks a saved method as the one the SDK's own screens act on, without paying. Internal, because
  /// a merchant tracks their own highlight — this exists so ``PrimerVaultedPaymentMethods`` can keep
  /// the SDK's selection in step with the row it shows.
  func setSelectedVaulted(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) {
    internalScope?.selectVaultedPaymentMethod(method)
  }

  /// Deletes a saved payment method, then refreshes ``vaultedPaymentMethods``.
  ///
  /// Deletion is immediate — add your own confirmation step if you want one. The SDK's own saved-methods
  /// screen routes through its built-in confirmation before it deletes.
  public func delete(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) async throws {
    try await internalScope?.deleteVaultedPaymentMethod(method)
  }

  /// Presents the SDK's saved-payment-methods screen, where the customer can pick a different method
  /// or delete one. Works both inline and in the managed ``PrimerCheckout`` modal.
  ///
  /// ``PrimerVaultedPaymentMethods`` already wires this into its default header.
  public func showAll() {
    scope.showAllVaultedPaymentMethods()
  }

}
