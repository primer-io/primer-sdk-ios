//
//  VaultSection.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

@available(iOS 15.0, *)
struct VaultSection: View {
  let vaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod
  let scope: PrimerPaymentMethodSelectionScope
  let isLoading: Bool
  @Binding var showsCvvInput: Bool

  @Environment(\.designTokens) private var tokens
  @Environment(\.bridgeController) private var bridgeController

  @State private var cvv = ""
  @State private var isCvvValid = false
  @State private var cvvError: String?

  private var isPayEnabled: Bool { !showsCvvInput || isCvvValid }

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
        cvvInput: showsCvvInput ? makeCvvInput() : nil
      )
      .environment(\.isInputEnabled, !isLoading)
      .onChange(of: showsCvvInput) {
        if !$0 { (cvv, isCvvValid, cvvError) = ("", false, nil) }
        bridgeController?.invalidateContentSize()
      }

      makePayButton()
    }
    .padding(PrimerSpacing.small(tokens: tokens))
    .background(
      RoundedRectangle(cornerRadius: PrimerRadius.large(tokens: tokens))
        .fill(CheckoutColors.backgroundSecondary(tokens: tokens))
    )
  }

  private func makeCvvInput() -> VaultedCardCVVInput {
    VaultedCardCVVInput(
      cvv: $cvv,
      isValid: $isCvvValid,
      errorMessage: $cvvError,
      cardNetwork: vaultedPaymentMethod.cardNetwork,
      onCvvChange: { (isCvvValid, cvvError) = scope.validateCvv($0) }
    )
  }

  // MARK: - Pay Button

  private func makePayButton() -> some View {
    PrimerCheckoutButton(
      CheckoutComponentsStrings.payButton,
      isEnabled: isPayEnabled,
      isLoading: isLoading,
      accessibilityConfiguration: .submitButton(
        identifier: AccessibilityIdentifiers.Vault.payButton,
        title: CheckoutComponentsStrings.payButton,
        isEnabled: isPayEnabled,
        isLoading: isLoading
      ),
      action: pay
    )
  }

  private func pay() {
    if showsCvvInput {
      Task { await scope.payWithVaultedPaymentMethodAndCvv(cvv) }
    } else if scope.requiresCvvInput {
      showsCvvInput = true
    } else {
      Task { await scope.payWithVaultedPaymentMethod() }
    }
  }

}
