//
//  PrimerVaultedPaymentMethods.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// The saved (vaulted) payment-methods list, composed from a header, per-item row, and submit slot.
///
/// Resolves its ``PrimerSelectionSession`` from the environment. Mirrors Android v3's
/// `PrimerVaultedPaymentMethods`. Tapping an item selects it; the submit button pays with the
/// currently selected vaulted method.
///
/// Slots are type-erased (`AnyView`) rather than generic — the 3-argument item/submit builders hit
/// Swift's generic-default inference limits, so this view trades the opaque-return ergonomics of
/// ``PrimerCardForm`` for guaranteed composition. Wrap custom slot content in `AnyView`.
@available(iOS 15.0, *)
public struct PrimerVaultedPaymentMethods: View {

  public typealias VaultedMethod = PrimerHeadlessUniversalCheckout.VaultedPaymentMethod

  @Environment(\.primerSelectionSession) private var session

  private let header: (PrimerSelectionSession) -> AnyView
  private let item: (VaultedMethod, Bool, @escaping () -> Void) -> AnyView
  private let submitButton: (Bool, Bool, @escaping () -> Void) -> AnyView

  public init(
    header: @escaping (PrimerSelectionSession) -> AnyView
      = { AnyView(VaultedPaymentMethodsDefaults.header($0)) },
    item: @escaping (VaultedMethod, _ isSelected: Bool, _ onSelect: @escaping () -> Void) -> AnyView
      = { AnyView(VaultedPaymentMethodsDefaults.item($0, isSelected: $1, onSelect: $2)) },
    submitButton: @escaping (_ isLoading: Bool, _ isEnabled: Bool, _ onSubmit: @escaping () -> Void) -> AnyView
      = { AnyView(VaultedPaymentMethodsDefaults.submitButton(isLoading: $0, isEnabled: $1, onSubmit: $2)) }
  ) {
    self.header = header
    self.item = item
    self.submitButton = submitButton
  }

  public var body: some View {
    if let session {
      Bound(session: session, header: header, item: item, submitButton: submitButton)
    } else {
      VaultedPaymentMethodsDefaults.unavailable()
    }
  }

  private struct Bound: View {
    @ObservedObject var session: PrimerSelectionSession
    let header: (PrimerSelectionSession) -> AnyView
    let item: (VaultedMethod, Bool, @escaping () -> Void) -> AnyView
    let submitButton: (Bool, Bool, @escaping () -> Void) -> AnyView
    @Environment(\.designTokens) private var tokens

    var body: some View {
      VStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
        header(session)
        ForEach(session.vaultedPaymentMethods, id: \.id) { vaulted in
          item(vaulted, session.state.selectedVaultedPaymentMethod?.id == vaulted.id) {
            session.selectVaulted(vaulted)
          }
        }
        // SDK-handled CVV recapture (not a customizable slot, matching Android).
        VaultedPaymentMethodsDefaults.cvvInput(session)
        submitButton(session.state.isVaultPaymentLoading, isSubmitEnabled) {
          Task { await session.submitSelectedVaulted() }
        }
      }
    }

    // Disabled until a method is selected, and — when CVV recapture is required — until a valid
    // CVV is entered, so a tap can never submit an empty CVV.
    private var isSubmitEnabled: Bool {
      guard session.state.selectedVaultedPaymentMethod != nil else { return false }
      return !session.state.requiresCvvInput || session.state.isCvvValid
    }
  }
}
