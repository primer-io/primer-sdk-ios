//
//  VaultSection.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Section displaying vaulted/saved payment methods with a placeholder card
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
      makeHeader()
      makeContent()
    }
  }

  // MARK: - Header

  private func makeHeader() -> some View {
    HStack {
      Text(CheckoutComponentsStrings.savedPaymentMethods)
        .font(PrimerFont.titleLarge(tokens: tokens))
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

      Spacer()

      Button(action: scope.showAllVaultedPaymentMethods) {
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
    Button(action: {
      Task {
        await scope.payWithVaultedPaymentMethod()
      }
    }) {
      HStack {
        if isLoading {
          ProgressView()
            .progressViewStyle(
              CircularProgressViewStyle(tint: CheckoutColors.background(tokens: tokens)))
        } else {
          Text(CheckoutComponentsStrings.payButton)
        }
      }
      .font(PrimerFont.titleLarge(tokens: tokens))
      .foregroundColor(CheckoutColors.background(tokens: tokens))
      .frame(maxWidth: .infinity)
      .padding(PrimerSpacing.medium(tokens: tokens))
      .background(
        RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
          .fill(
            isPayButtonEnabled
              ? CheckoutColors.borderFocus(tokens: tokens) : CheckoutColors.gray300(tokens: tokens))
      )
    }
    .disabled(!isPayButtonEnabled)
    .accessibility(
      config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.Vault.payButton,
        label: CheckoutComponentsStrings.payButton,
        traits: [.isButton]
      ))
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
