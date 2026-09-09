//
//  PrimerVaultedPaymentMethods.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// The returning-customer shortcut for saved (vaulted) payment methods, composed from a header, an
/// item row, and a submit slot.
///
/// Resolves its ``PrimerSelectionSession`` from the environment. Renders the selected method — the
/// first saved one until the customer picks another — and pays with it on submit. The header's
/// "Show all" opens the SDK screen listing every saved method, which is also the only place a
/// customer can delete one. Renders nothing when the customer has no saved methods.
///
/// To show every method inline instead, iterate ``PrimerSelectionSession/vaultedPaymentMethods`` in
/// your own layout and call ``PrimerSelectionSession/selectVaulted(_:)`` and
/// ``PrimerSelectionSession/delete(_:)`` directly.
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
      // Nothing saved means no section at all, not an empty frame with a submit button.
      if let selected = session.state.selectedVaultedPaymentMethod {
        VStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
          header(session)
          // One row, not the whole vault: this is the returning-customer shortcut, and the header's
          // "Show all" opens the screen that lists every saved method. Merchants who want the full
          // list inline iterate ``PrimerSelectionSession/vaultedPaymentMethods`` themselves.
          item(selected, true) { session.selectVaulted(selected) }
          // SDK-handled CVV recapture (not a customizable slot).
          VaultedPaymentMethodsDefaults.cvvInput(session)
          submitButton(session.state.isVaultPaymentLoading, isSubmitEnabled) {
            Task { await session.submitSelectedVaulted() }
          }
        }
      }
    }

    // Only evaluated with a method selected; blocks submit until a valid CVV is entered when
    // recapture is required, so a tap can never submit an empty CVV.
    private var isSubmitEnabled: Bool {
      !session.state.requiresCvvInput || session.state.isCvvValid
    }
  }
}
