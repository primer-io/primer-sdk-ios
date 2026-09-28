//
//  VaultSection.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
struct VaultSection: View {
  let vaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod
  let scope: PrimerPaymentMethodSelectionScope
  let isLoading: Bool

  @Environment(\.designTokens) private var tokens

  var body: some View {
    VStack(alignment: .leading, spacing: PrimerSpacing.medium(tokens: tokens)) {
      VaultedSectionHeader(onShowAll: scope.showAllVaultedPaymentMethods)
      makeContent()
    }
  }

  // MARK: - Content

  private func makeContent() -> some View {
    VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
      VaultedPaymentMethodCard(vaultedPaymentMethod: vaultedPaymentMethod, isSelected: true)

      makePayButton()
    }
    .padding(PrimerSpacing.small(tokens: tokens))
    .background(
      RoundedRectangle(cornerRadius: PrimerRadius.large(tokens: tokens))
        .fill(CheckoutColors.gray100(tokens: tokens))
    )
  }

  // MARK: - Pay Button

  private func makePayButton() -> some View {
    PrimerCheckoutButton(
      CheckoutComponentsStrings.payButton,
      isLoading: isLoading,
      accessibilityConfiguration: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.Vault.payButton,
        label: CheckoutComponentsStrings.payButton,
        traits: [.isButton]
      ),
      action: {
        Task {
          await scope.payWithVaultedPaymentMethod()
        }
      }
    )
  }

}
