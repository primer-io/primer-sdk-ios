//
//  PaymentMethodsSection.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Section displaying available payment methods with loading and empty states
@available(iOS 15.0, *)
struct PaymentMethodsSection: View {
  let state: PrimerPaymentMethodSelectionState
  let scope: PrimerPaymentMethodSelectionScope

  @Environment(\.designTokens) private var tokens

  var body: some View {
    VStack(alignment: .leading, spacing: PrimerSpacing.medium(tokens: tokens)) {
      Text(CheckoutComponentsStrings.choosePaymentMethod)
        .font(PrimerFont.titleLarge(tokens: tokens))
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

      if state.isLoading {
        makeLoadingView()
      } else if state.paymentMethods.isEmpty {
        makeEmptyStateView()
      } else {
        makePaymentMethodsList()
      }

      if let error = state.error {
        Text(error)
          .font(PrimerFont.caption(tokens: tokens))
          .foregroundColor(CheckoutColors.borderError(tokens: tokens))
      }
    }
  }

  // MARK: - Loading

  private func makeLoadingView() -> some View {
    ProgressView()
      .progressViewStyle(
        CircularProgressViewStyle(tint: CheckoutColors.borderFocus(tokens: tokens))
      )
      .scaleEffect(PrimerScale.large)
      .frame(maxWidth: .infinity, minHeight: PrimerComponentHeight.emptyStateMinHeight)
  }

  // MARK: - Empty State

  @ViewBuilder
  private func makeEmptyStateView() -> some View {
    if let customEmptyState = scope.emptyStateView {
      AnyView(customEmptyState())
    } else {
      VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
        Image(systemName: "creditcard.and.123")
          .font(PrimerFont.largeIcon(tokens: tokens))
          .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        Text(CheckoutComponentsStrings.noPaymentMethodsAvailable)
          .font(PrimerFont.body(tokens: tokens))
          .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
      }
      .frame(maxWidth: .infinity)
      .padding(.top, PrimerComponentHeight.emptyStateTopPadding)
    }
  }

  // MARK: - Payment Methods List

  private func makePaymentMethodsList() -> some View {
    LazyVStack(spacing: PrimerSpacing.small(tokens: tokens)) {
      ForEach(state.paymentMethods, id: \.id) { method in
        PaymentMethodButton(
          method: method,
          customItem: scope.paymentMethodItem,
          onSelect: { scope.onPaymentMethodSelected(paymentMethod: method) }
        )
      }
    }
  }
}
