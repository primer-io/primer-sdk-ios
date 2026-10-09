//
//  VaultedCardCvvRecaptureScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Collects the security code for a saved card whose client session asks for it, then pays.
///
/// The code stays in this view. It never reaches the selection state and cannot outlive the payment.
@available(iOS 15.0, *)
struct VaultedCardCvvRecaptureScreen: View, LogReporter {
  let scope: any PaymentMethodSelectionScopeInternal
  let navigator: CheckoutNavigator

  @Environment(\.designTokens) private var tokens

  @State private var cvv = ""
  @State private var isValid = false
  @State private var errorMessage: String?
  @State private var isSubmitting = false

  private var vaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? {
    scope.currentState.selectedVaultedPaymentMethod
  }

  var body: some View {
    VStack(alignment: .leading, spacing: PrimerSpacing.large(tokens: tokens)) {
      CheckoutHeaderView(showBackButton: true, onBack: navigator.navigateBack)

      if let vaultedPaymentMethod {
        Text(CheckoutComponentsStrings.vaultCvvTitle)
          .primerTypography(.titleXLarge, tokens: tokens)
          .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
          .accessibilityAddTraits(.isHeader)

        VaultedPaymentMethodCard(vaultedPaymentMethod: vaultedPaymentMethod)

        VaultedCardCVVInput(
          cvv: $cvv,
          isValid: $isValid,
          errorMessage: $errorMessage,
          cardNetwork: vaultedPaymentMethod.cardNetwork,
          onCvvChange: validate
        )

        makePayButton()
      } else {
        // The selection was cleared underneath us, so there is nothing left to charge.
        Text(CheckoutComponentsStrings.vaultCvvGenericError)
          .primerTypography(.body, tokens: tokens)
          .foregroundColor(CheckoutColors.textNegative(tokens: tokens))
      }

      Spacer()
    }
    .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
    .background(CheckoutColors.background(tokens: tokens))
  }

  // MARK: - Pay Button

  private func makePayButton() -> some View {
    PrimerCheckoutButton(
      CheckoutComponentsStrings.payButton,
      isEnabled: isValid,
      isLoading: isSubmitting,
      accessibilityConfiguration: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.Vault.cvvPayButton,
        label: isSubmitting
          ? CheckoutComponentsStrings.a11ySubmitButtonLoading : CheckoutComponentsStrings.payButton,
        traits: [.isButton]
      ),
      action: submit
    )
  }

  // MARK: - Actions

  private func validate(_ newValue: String) {
    let result = scope.validateCvv(newValue)
    isValid = result.isValid
    errorMessage = result.errorMessage
  }

  private func submit() {
    guard isValid, !isSubmitting else { return }
    isSubmitting = true
    logger.info(message: "[Vault] Submitting recaptured CVV")

    Task {
      await scope.payWithVaultedPaymentMethodAndCvv(cvv)
      // This only matters when the submit never started, so the button comes back rather than spins.
      isSubmitting = false
    }
  }
}
