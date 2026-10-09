//
//  VaultedPaymentMethodsListScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Screen displaying all vaulted/saved payment methods with edit mode support
@available(iOS 15.0, *)
struct VaultedPaymentMethodsListScreen: View {
  let vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]
  let selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?
  let onSelect: (PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) -> Void
  let onBack: () -> Void
  let onDeleteTapped: (PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) -> Void
  let onEditModeChange: (Bool) -> Void

  // Starts from the caller's value: the screen is rebuilt after the delete confirmation and must stay in edit mode.
  @State private var isEditMode: Bool
  @Environment(\.designTokens) private var tokens

  init(
    vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod],
    selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?,
    isEditMode: Bool = false,
    onSelect: @escaping (PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) -> Void,
    onBack: @escaping () -> Void,
    onDeleteTapped: @escaping (PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) -> Void,
    onEditModeChange: @escaping (Bool) -> Void = { _ in }
  ) {
    self.vaultedPaymentMethods = vaultedPaymentMethods
    self.selectedVaultedPaymentMethod = selectedVaultedPaymentMethod
    self.onSelect = onSelect
    self.onBack = onBack
    self.onDeleteTapped = onDeleteTapped
    self.onEditModeChange = onEditModeChange
    _isEditMode = State(initialValue: isEditMode)
  }

  var body: some View {
    VStack(spacing: 0) {
      CheckoutHeaderView(
        showBackButton: true,
        onBack: onBack,
        rightButton: isEditMode
          ? .doneButton(action: { setEditMode(false) })
          : .editButton(action: { setEditMode(true) })
      )
      makeTitle()
      makeContent()
    }
    .background(CheckoutColors.background(tokens: tokens))
  }

  // MARK: - Title

  private func makeTitle() -> some View {
    HStack {
      Text(CheckoutComponentsStrings.allSavedPaymentMethods)
        .primerTypography(.titleXLarge, tokens: tokens)
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

      Spacer()
    }
    .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
    .padding(.bottom, PrimerSpacing.large(tokens: tokens))
  }

  // MARK: - Content

  private func makeContent() -> some View {
    ScrollView {
      LazyVStack(spacing: PrimerSpacing.small(tokens: tokens)) {
        ForEach(vaultedPaymentMethods, id: \.id) { method in
          VaultedPaymentMethodCard(
            vaultedPaymentMethod: method,
            isSelected: isEditMode ? false : isMethodSelected(method),
            isEditMode: isEditMode,
            onTap: {
              onSelect(method)
            },
            onDeleteTapped: {
              onDeleteTapped(method)
            }
          )
        }
      }
      .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
      .padding(.bottom, PrimerSpacing.xlarge(tokens: tokens))
    }
  }

  private func setEditMode(_ editing: Bool) {
    isEditMode = editing
    onEditModeChange(editing)
  }

  private func isMethodSelected(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) -> Bool {
    method.id == selectedVaultedPaymentMethod?.id
  }
}
