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
/// The field used to appear inline inside ``PrimerVaultedPaymentMethods``, which left a merchant
/// building their own saved-card list and their own pay button with nowhere for it to go. Owning the
/// screen means the SDK can always ask, whatever the surrounding layout is. Drop-In and Android
/// already work this way.
///
/// The code lives in this view for as long as the screen does. It never reaches the selection state,
/// so nothing outside can read it and it cannot outlive the payment.
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
          .font(PrimerFont.titleXLarge(tokens: tokens))
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
        // The selection was cleared underneath us — deleted, or the vault reloaded empty. There is
        // nothing to charge, so say so rather than leaving a field that can never submit.
        Text(CheckoutComponentsStrings.vaultCvvGenericError)
          .font(PrimerFont.body(tokens: tokens))
          .foregroundColor(CheckoutColors.textNegative(tokens: tokens))
      }

      Spacer()
    }
    .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
    .background(CheckoutColors.background(tokens: tokens))
  }

  // MARK: - Pay Button

  private func makePayButton() -> some View {
    Button(action: submit) {
      Group {
        if isSubmitting {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: CheckoutColors.background(tokens: tokens)))
            .accessibilityLabel(CheckoutComponentsStrings.a11yLoading)
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
            isValid || isSubmitting
              ? CheckoutColors.borderFocus(tokens: tokens)
              : CheckoutColors.gray300(tokens: tokens))
      )
    }
    .disabled(!isValid || isSubmitting)
    .accessibility(
      config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.Vault.cvvPayButton,
        label: isSubmitting
          ? CheckoutComponentsStrings.a11ySubmitButtonLoading : CheckoutComponentsStrings.payButton,
        traits: [.isButton]
      ))
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
      // The payment navigates on to processing and then to its outcome, so this only matters when
      // the submit never started — the button has to come back rather than spin forever.
      isSubmitting = false
    }
  }
}
