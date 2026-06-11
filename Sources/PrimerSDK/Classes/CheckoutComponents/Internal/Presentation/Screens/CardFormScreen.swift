//
//  CardFormScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// The SDK's default modal card screen: header + the shared `CardFormFieldsView` (the single,
/// config-aware field renderer, also used by the public `CardFormDefaults`) + the amount-aware
/// submit button.
@available(iOS 15.0, *)
struct CardFormScreen: View, LogReporter {
  let scope: any CardFormFieldScopeInternal

  @Environment(\.designTokens) private var tokens
  @Environment(\.diContainer) private var container
  @State private var cardFormState: PrimerCardFormState = .init()
  @State private var lastAnnouncedError: String?
  @State private var configurationService: ConfigurationService?
  @State private var observationTask: Task<Void, Never>?

  var body: some View {
    ScrollView {
      VStack(spacing: PrimerSpacing.xxlarge(tokens: tokens)) {
        headerSection
        formContent
      }
      .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
      .padding(.vertical, PrimerSpacing.large(tokens: tokens))
      .frame(maxWidth: .infinity)
    }
    .navigationBarHidden(true)
    .background(CheckoutColors.background(tokens: tokens))
    .environment(\.primerCardFormScope, scope)
  }

  @MainActor
  private var headerSection: some View {
    VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
      HStack {
        if scope.presentationContext.shouldShowBackButton {
          Button(action: scope.onBack) {
            HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
              Image(systemName: RTLIcon.backChevron)
                .font(PrimerFont.bodyMedium(tokens: tokens))
              Text(CheckoutComponentsStrings.backButton)
            }
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
          }
          .accessibility(
            config: AccessibilityConfiguration(
              identifier: AccessibilityIdentifiers.Common.backButton,
              label: CheckoutComponentsStrings.a11yBack,
              traits: [.isButton]
            ))
        }

        Spacer()

        if scope.dismissalMechanism.contains(.closeButton) {
          Button(CheckoutComponentsStrings.cancelButton, action: scope.cancel)
            .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
            .accessibility(
              config: AccessibilityConfiguration(
                identifier: AccessibilityIdentifiers.Common.closeButton,
                label: CheckoutComponentsStrings.a11yCancel,
                traits: [.isButton]
              ))
        }
      }

      titleSection
    }
  }

  @MainActor
  private var formContent: some View {
    VStack(spacing: PrimerSpacing.xlarge(tokens: tokens)) {
      CardFormFieldsView(scope: scope)
      submitButtonSection
    }
    .onAppear {
      resolveConfigurationService()
      observeState()
    }
    .onDisappear {
      observationTask?.cancel()
      observationTask = nil
    }
  }

  private var titleSection: some View {
    Text(CheckoutComponentsStrings.cardPaymentTitle)
      .font(PrimerFont.titleXLarge(tokens: tokens))
      .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityAddTraits(.isHeader)
  }

  @MainActor
  private var submitButtonSection: some View {
    Button(action: submitAction) {
      submitButtonContent
    }
    .disabled(!cardFormState.isValid || cardFormState.isLoading)
  }

  private var submitButtonContent: some View {
    let isEnabled = cardFormState.isValid && !cardFormState.isLoading

    return HStack {
      if cardFormState.isLoading {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: CheckoutColors.white(tokens: tokens)))
          .scaleEffect(PrimerScale.small)
      } else {
        Text(payTitle(accessible: false))
      }
    }
    .font(PrimerFont.body(tokens: tokens))
    .foregroundColor(CheckoutColors.white(tokens: tokens))
    .frame(maxWidth: .infinity)
    .padding(.vertical, PrimerSpacing.large(tokens: tokens))
    .background(submitButtonBackground)
    .cornerRadius(PrimerRadius.small(tokens: tokens))
    .accessibility(
      config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.Common.submitButton,
        label: cardFormState.isLoading
          ? CheckoutComponentsStrings.a11ySubmitButtonLoading : payTitle(accessible: true),
        hint: cardFormState.isLoading
          ? nil
          : (isEnabled
            ? CheckoutComponentsStrings.a11ySubmitButtonHint
            : CheckoutComponentsStrings.a11ySubmitButtonDisabled),
        traits: [.isButton]
      ))
  }

  /// Computes the submit-button title, formatting the amount with the accessibility-friendly
  /// currency formatter when `accessible` is true and the visible formatter otherwise.
  private func payTitle(accessible: Bool) -> String {
    if scope.cardFormUIOptions?.payButtonAddNewCard == true {
      return CheckoutComponentsStrings.addCardButton
    }

    guard PrimerInternal.shared.intent == .checkout,
      let currency = configurationService?.currency
    else {
      return CheckoutComponentsStrings.payButton
    }

    let amount = configurationService?.amount ?? 0
    let merchantAmount = configurationService?.apiConfiguration?.clientSession?.order?
      .merchantAmount

    let rawAmount: Int = if let merchantAmount,
      let surchargeRaw = cardFormState.surchargeAmountRaw,
      cardFormState.selectedNetwork != nil {
      merchantAmount + surchargeRaw
    } else {
      amount
    }

    let formatted = accessible
      ? rawAmount.toAccessibilityCurrencyString(currency: currency)
      : rawAmount.toCurrencyString(currency: currency)
    return CheckoutComponentsStrings.paymentAmountTitle(formatted)
  }

  private var submitButtonBackground: Color {
    cardFormState.isValid && !cardFormState.isLoading
      ? CheckoutColors.textPrimary(tokens: tokens)
      : CheckoutColors.gray300(tokens: tokens)
  }

  private func submitAction() {
    Task {
      await scope.performSubmit()
    }
  }

  private func resolveConfigurationService() {
    guard let container else {
      return logger.error(message: "DIContainer not available for CardFormScreen")
    }
    do {
      configurationService = try container.resolveSync(ConfigurationService.self)
    } catch {
      logger.error(message: "Failed to resolve ConfigurationService: \(error)")
    }
  }

  private func observeState() {
    observationTask?.cancel()
    observationTask = Task {
      for await state in scope.state {
        await MainActor.run {
          let firstErrorMessage = state.fieldErrors.first?.message
          if let firstErrorMessage, firstErrorMessage != lastAnnouncedError {
            if let announcementService = try? container?.resolveSync(AccessibilityAnnouncementService.self) {
              announcementService.announceError(firstErrorMessage)
            }
          }
          lastAnnouncedError = firstErrorMessage
          cardFormState = state
        }
      }
    }
  }
}
