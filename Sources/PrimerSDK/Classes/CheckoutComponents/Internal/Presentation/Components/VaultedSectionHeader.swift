//
//  VaultedSectionHeader.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Title for a saved-payment-methods section, with an optional action opening the SDK's full
/// vault-management screen.
///
/// Shared by the SDK's own selection screen and the public ``VaultedPaymentMethodsDefaults/header(_:)``
/// so both offer the same affordance — the merchant's embedded list would otherwise have no way to
/// reach the screen that deletes saved methods.
@available(iOS 15.0, *)
struct VaultedSectionHeader: View {
  let onShowAll: (() -> Void)?

  @Environment(\.designTokens) private var tokens

  var body: some View {
    HStack {
      Text(CheckoutComponentsStrings.savedPaymentMethods)
        .font(PrimerFont.titleLarge(tokens: tokens))
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        .accessibilityAddTraits(.isHeader)

      Spacer()

      if let onShowAll {
        Button(action: onShowAll) {
          HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
            Text(CheckoutComponentsStrings.showAll)
              .font(PrimerFont.titleLarge(tokens: tokens))
            Image(systemName: "chevron.down")
              .font(PrimerFont.caption(tokens: tokens))
          }
          .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        }
        .accessibility(
          config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.PaymentSelection.showAllButton,
            label: CheckoutComponentsStrings.a11yShowAll,
            traits: [.isButton]
          ))
      }
    }
  }
}
