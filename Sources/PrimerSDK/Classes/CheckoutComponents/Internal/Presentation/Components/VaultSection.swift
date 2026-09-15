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
  let requiresCvvInput: Bool
  @Binding var cvvInput: String
  @Binding var isCvvValid: Bool
  @Binding var cvvError: String?

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
      VaultedPaymentMethodCard(
        vaultedPaymentMethod: vaultedPaymentMethod,
        isSelected: true,
        cvvInputContent: requiresCvvInput
          ? {
            AnyView(
              VaultedCardCVVInput(
                cvv: $cvvInput,
                isValid: $isCvvValid,
                errorMessage: $cvvError,
                cardNetwork: cardNetwork,
                onCvvChange: scope.updateCvvInput
              ))
          } : nil
      )

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
    PrimerButton(
      CheckoutComponentsStrings.payButton,
      isEnabled: isPayButtonEnabled,
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

  // MARK: - Helpers

  private var isPayButtonEnabled: Bool {
    if isLoading {
      return false
    }
    if requiresCvvInput {
      return isCvvValid
    }
    return true
  }

  private var cardNetwork: CardNetwork {
    let network =
      vaultedPaymentMethod.paymentInstrumentData.network ?? vaultedPaymentMethod
      .paymentInstrumentData.binData?.network ?? "Card"
    return CardNetwork(rawValue: network.uppercased()) ?? .unknown
  }
}
