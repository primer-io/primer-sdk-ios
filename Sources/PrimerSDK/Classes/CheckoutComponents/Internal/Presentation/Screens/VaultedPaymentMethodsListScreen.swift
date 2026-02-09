//
//  VaultedPaymentMethodsListScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Screen displaying all vaulted/saved payment methods with edit mode support
@available(iOS 15.0, *)
struct VaultedPaymentMethodsListScreen: View {
  let vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]
  let selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?
  let onSelect: (PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) -> Void
  let onBack: () -> Void
  let onDeleteTapped: (PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) -> Void

  @State private var isEditMode: Bool = false
  @Environment(\.designTokens) private var tokens

  var body: some View {
    VStack(spacing: 0) {
      CheckoutHeaderView(
        showBackButton: true,
        onBack: onBack,
        rightButton: isEditMode
          ? .doneButton(action: { isEditMode = false })
          : .editButton(action: { isEditMode = true })
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
        .font(PrimerFont.titleXLarge(tokens: tokens))
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

  // MARK: - Helpers

  private func isMethodSelected(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod)
    -> Bool
  {
    guard let selected = selectedVaultedPaymentMethod else { return false }
    return method.id == selected.id
  }
}
