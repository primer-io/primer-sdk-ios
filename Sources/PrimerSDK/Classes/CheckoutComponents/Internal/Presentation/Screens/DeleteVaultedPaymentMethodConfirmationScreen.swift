//
//  DeleteVaultedPaymentMethodConfirmationScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Screen displaying a confirmation dialog for deleting a vaulted payment method
@available(iOS 15.0, *)
struct DeleteVaultedPaymentMethodConfirmationScreen: View, LogReporter {
  let vaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod
  let navigator: CheckoutNavigator
  let scope: any PaymentMethodSelectionScopeInternal

  @Environment(\.designTokens) private var tokens

  @State private var isDeleting = false
  @State private var deleteTask: Task<Void, Never>?

  // MARK: - Body

  var body: some View {
    VStack(spacing: 0) {
      makeHeader()
      makePaymentMethodCard()
      makeConfirmationSection()
      Spacer()
    }
    .background(CheckoutColors.background(tokens: tokens))
    .onDisappear {
      deleteTask?.cancel()
      deleteTask = nil
    }
  }

  // MARK: - Header

  private func makeHeader() -> some View {
    CheckoutHeaderView(
      showBackButton: true,
      onBack: navigator.navigateBack,
      rightButton: .doneButton(action: navigator.navigateBack)
    )
  }

  // MARK: - Payment Method Card (Read-only)

  private func makePaymentMethodCard() -> some View {
    VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
      // Title
      HStack {
        Text(CheckoutComponentsStrings.allSavedPaymentMethods)
          .primerTypography(.titleXLarge, tokens: tokens)
          .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        Spacer()
      }

      // Card display (non-interactive, reusing VaultedPaymentMethodCard)
      VaultedPaymentMethodCard(
        vaultedPaymentMethod: vaultedPaymentMethod
      )
    }
    .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
    .padding(.bottom, PrimerSpacing.large(tokens: tokens))
  }

  // MARK: - Confirmation Section

  private func makeConfirmationSection() -> some View {
    VStack(alignment: .leading, spacing: PrimerSpacing.small(tokens: tokens)) {
      Text(CheckoutComponentsStrings.deletePaymentMethodConfirmation)
        .primerTypography(.bodySmall, tokens: tokens)
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))

      HStack(spacing: PrimerSpacing.small(tokens: tokens)) {
        makeCancelButton()
        makeDeleteButton()
      }
    }
    .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
  }

  // MARK: - Cancel Button

  private func makeCancelButton() -> some View {
    PrimerCheckoutButton(
      style: .outlined,
      accessibilityConfiguration: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.Common.cancelButton,
        label: CheckoutComponentsStrings.a11yCancel,
        traits: [.isButton]
      ),
      action: navigator.navigateBack
    ) {
      Text(CheckoutComponentsStrings.cancelButton)
    }
  }

  // MARK: - Delete Button

  private func makeDeleteButton() -> some View {
    PrimerCheckoutButton(
      CheckoutComponentsStrings.deleteButton,
      isLoading: isDeleting,
      accessibilityConfiguration: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.Common.deleteButton,
        label: CheckoutComponentsStrings.deleteButton,
        traits: [.isButton]
      ),
      action: handleDelete
    )
  }

  // MARK: - Actions

  private func handleDelete() {
    guard !isDeleting else { return }

    isDeleting = true

    deleteTask = Task { [self] in
      do {
        try await scope.deleteVaultedPaymentMethod(vaultedPaymentMethod)
        logger.info(message: "[Vault] Successfully deleted payment method from confirmation screen")
      } catch {
        logger.error(
          message: "[Vault] Failed to delete payment method: \(error.localizedDescription)")
      }

      if Task.isCancelled { return }
      isDeleting = false
      navigator.navigateBack()
    }
  }
}
