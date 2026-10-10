//
//  CardFormScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// The SDK's default modal card screen: header + the shared `CardFormFieldsView` (the single,
/// config-aware field renderer, also used by the public `CardFormDefaults`) + the submit button.
@available(iOS 15.0, *)
struct CardFormScreen: View, LogReporter {
  let scope: any CardFormFieldScopeInternal

  @Environment(\.designTokens) private var tokens
  @Environment(\.diContainer) private var container
  @State private var cardFormState: PrimerCardFormState = .init()
  @State private var lastAnnouncedError: String?
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
                .font(PrimerFont.titleLarge(tokens: tokens))
                .foregroundColor(CheckoutColors.iconPrimary(tokens: tokens))
              Text(CheckoutComponentsStrings.backButton)
                .primerTypography(.titleLarge, tokens: tokens)
            }
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
          }
          .buttonStyle(PlainButtonStyle())
          .accessibility(
            config: AccessibilityConfiguration(
              identifier: AccessibilityIdentifiers.Common.backButton,
              label: CheckoutComponentsStrings.a11yBack,
              traits: [.isButton]
            ))
        }

        Spacer()

        if scope.dismissalMechanism.contains(.closeButton) {
          CheckoutHeaderButton(config: .closeButton(action: scope.cancel))
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
    .onAppear(perform: observeState)
    .onDisappear {
      observationTask?.cancel()
      observationTask = nil
    }
  }

  private var titleSection: some View {
    Text(CheckoutComponentsStrings.cardPaymentTitle)
      .primerTypography(.titleXLarge, tokens: tokens)
      .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityAddTraits(.isHeader)
  }

  // Plain "Pay" like Android, RN, Web and Figma.
  private var payTitle: String {
    scope.cardFormUIOptions?.payButtonAddNewCard == true
      ? CheckoutComponentsStrings.addCardButton : CheckoutComponentsStrings.payButton
  }

  @MainActor
  private var submitButtonSection: some View {
    let isEnabled = cardFormState.isValid && !cardFormState.isLoading

    return PrimerCheckoutButton(
      payTitle,
      isEnabled: isEnabled,
      isLoading: cardFormState.isLoading,
      accessibilityConfiguration: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.CardForm.submitButton,
        label: cardFormState.isLoading ? CheckoutComponentsStrings.a11ySubmitButtonLoading : payTitle,
        hint: cardFormState.isLoading
          ? nil
          : (isEnabled
            ? CheckoutComponentsStrings.a11ySubmitButtonHint
            : CheckoutComponentsStrings.a11ySubmitButtonDisabled),
        traits: [.isButton]
      ),
      action: submitAction
    )
  }

  private func submitAction() {
    Task {
      await scope.performSubmit()
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
