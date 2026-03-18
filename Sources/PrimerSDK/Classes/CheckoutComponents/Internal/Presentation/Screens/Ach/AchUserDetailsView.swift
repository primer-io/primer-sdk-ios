//
//  AchUserDetailsView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct AchUserDetailsView: View, LogReporter {
  let scope: any PrimerAchScope
  let achState: PrimerAchState

  @Environment(\.designTokens) private var tokens

  var body: some View {
    VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
      Text(CheckoutComponentsStrings.achPersonalDetailsSubtitle)
        .font(PrimerFont.bodyLarge(tokens: tokens))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        .multilineTextAlignment(.center)
        .accessibilityIdentifier(AccessibilityIdentifiers.Ach.userDetailsTitle)

      VStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
        HStack(alignment: .top, spacing: PrimerSpacing.medium(tokens: tokens)) {
          firstNameField
          lastNameField
        }
        emailField
      }

      submitButton
    }
    .accessibilityIdentifier(AccessibilityIdentifiers.Ach.userDetailsContainer)
  }

  @ViewBuilder private var firstNameField: some View {
    NameInputField(
      label: CheckoutComponentsStrings.firstNameLabel,
      placeholder: CheckoutComponentsStrings.firstNamePlaceholder,
      inputType: .firstName,
      initialValue: achState.userDetails.firstName,
      onNameChange: { scope.updateFirstName($0) }
    )
    .accessibilityIdentifier(AccessibilityIdentifiers.Ach.firstNameField)
  }

  @ViewBuilder private var lastNameField: some View {
    NameInputField(
      label: CheckoutComponentsStrings.lastNameLabel,
      placeholder: CheckoutComponentsStrings.lastNamePlaceholder,
      inputType: .lastName,
      initialValue: achState.userDetails.lastName,
      onNameChange: { scope.updateLastName($0) }
    )
    .accessibilityIdentifier(AccessibilityIdentifiers.Ach.lastNameField)
  }

  @ViewBuilder private var emailField: some View {
    VStack(alignment: .leading, spacing: PrimerSpacing.xsmall(tokens: tokens)) {
      EmailInputField(
        label: CheckoutComponentsStrings.emailLabel,
        placeholder: CheckoutComponentsStrings.emailPlaceholder,
        initialValue: achState.userDetails.emailAddress,
        onEmailChange: { scope.updateEmailAddress($0) }
      )
      .accessibilityIdentifier(AccessibilityIdentifiers.Ach.emailField)

      Text(CheckoutComponentsStrings.achEmailDisclaimer)
        .font(PrimerFont.bodySmall(tokens: tokens))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        .accessibilityIdentifier(AccessibilityIdentifiers.Ach.emailDisclaimer)
    }
  }

  @ViewBuilder private var submitButton: some View {
    if let customButton = scope.submitButton {
      AnyView(customButton(scope))
    } else {
      Button(action: scope.submitUserDetails) {
        Text(CheckoutComponentsStrings.achContinueButton)
          .font(PrimerFont.body(tokens: tokens))
          .foregroundColor(CheckoutColors.white(tokens: tokens))
          .frame(maxWidth: .infinity)
          .padding(.vertical, PrimerSpacing.large(tokens: tokens))
          .background(
            achState.isSubmitEnabled
              ? CheckoutColors.textPrimary(tokens: tokens)
              : CheckoutColors.textSecondary(tokens: tokens)
          )
          .cornerRadius(PrimerRadius.small(tokens: tokens))
      }
      .disabled(!achState.isSubmitEnabled)
      .accessibilityIdentifier(AccessibilityIdentifiers.Ach.submitButton)
      .accessibilityLabel(CheckoutComponentsStrings.achContinueButton)
      .accessibilityHint(
        achState.isSubmitEnabled
          ? CheckoutComponentsStrings.a11yAchContinueHint
          : CheckoutComponentsStrings.a11ySubmitButtonDisabled
      )
    }
  }

}
