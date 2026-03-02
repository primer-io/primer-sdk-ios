//
//  PaymentMethodSelectionScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Default payment method selection screen for CheckoutComponents
@available(iOS 15.0, *)
struct PaymentMethodSelectionScreen: View, LogReporter {
  let scope: PrimerPaymentMethodSelectionScope

  @Environment(\.designTokens) private var tokens
  @Environment(\.bridgeController) private var bridgeController
  @Environment(\.diContainer) private var container
  @State private var selectionState: PrimerPaymentMethodSelectionState = .init()
  @State private var configurationService: ConfigurationService?
  @State private var observationTask: Task<Void, Never>?

  var body: some View {
    VStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
      makeHeader()
      makeContent()
    }
    .environment(\.primerPaymentMethodSelectionScope, scope)
    .onAppear {
      resolveConfigurationService()
      observeState()
    }
    .onDisappear {
      observationTask?.cancel()
      observationTask = nil
    }
  }

  // MARK: - Header

  private func makeHeader() -> some View {
    HStack {
      if let formattedAmount {
        Text(CheckoutComponentsStrings.paymentAmountTitle(formattedAmount))
          .font(PrimerFont.titleXLarge(tokens: tokens))
          .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
      }

      Spacer()

      if scope.dismissalMechanism.contains(.closeButton) {
        Button(CheckoutComponentsStrings.cancelButton, action: scope.cancel)
          .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
      }
    }
    .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
    .padding(.top, PrimerSpacing.large(tokens: tokens))
  }

  // MARK: - Content

  private func makeContent() -> some View {
    ScrollView {
      VStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
        if let vaultedPaymentMethod = selectionState.selectedVaultedPaymentMethod {
          VaultSection(
            vaultedPaymentMethod: vaultedPaymentMethod,
            scope: scope,
            isLoading: selectionState.isVaultPaymentLoading,
            requiresCvvInput: selectionState.requiresCvvInput,
            cvvInput: $selectionState.cvvInput,
            isCvvValid: $selectionState.isCvvValid,
            cvvError: $selectionState.cvvError
          )
        }

        if shouldShowCollapsedView {
          makeShowOtherWaysToPayButton()
        } else {
          PaymentMethodsSection(state: selectionState, scope: scope)
        }
      }
      .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
      .padding(.bottom, PrimerSpacing.xlarge(tokens: tokens))
    }
  }

  private var shouldShowCollapsedView: Bool {
    !selectionState.isPaymentMethodsExpanded
  }

  private func makeShowOtherWaysToPayButton() -> some View {
    Button(action: { scope.showOtherWaysToPay() }) {
      Text(CheckoutComponentsStrings.showOtherWaysToPay)
        .font(PrimerFont.titleLarge(tokens: tokens))
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        .frame(maxWidth: .infinity)
        .padding(PrimerSpacing.medium(tokens: tokens))
        .background(
          RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
            .stroke(
              CheckoutColors.borderDefault(tokens: tokens), lineWidth: PrimerBorderWidth.standard)
        )
    }
    .accessibility(
      config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.PaymentSelection.showOtherWaysButton,
        label: CheckoutComponentsStrings.a11yShowOtherWaysToPay,
        traits: [.isButton]
      ))
  }

  // MARK: - Helpers

  private var formattedAmount: String? {
    guard let amount = configurationService?.amount,
      let currency = configurationService?.currency
    else {
      return nil
    }
    return amount.toCurrencyString(currency: currency)
  }

  private func resolveConfigurationService() {
    guard let container else { return }
    configurationService = try? container.resolveSync(ConfigurationService.self)
  }

  private func observeState() {
    observationTask?.cancel()
    observationTask = Task {
      for await state in await scope.state {
        await MainActor.run {
          selectionState = state
          if !state.paymentMethods.isEmpty {
            bridgeController?.invalidateContentSize()
          }
        }
      }
    }
  }
}
