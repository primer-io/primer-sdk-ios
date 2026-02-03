//
//  AchUserDetailsView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct AchUserDetailsView: View, LogReporter {
  let scope: any PrimerAchScope
  let achState: AchState

  @Environment(\.designTokens) private var tokens
  @State private var firstName: String = ""
  @State private var lastName: String = ""
  @State private var emailAddress: String = ""
  @FocusState private var focusedField: Field?

  private enum Field: Hashable {
    case firstName
    case lastName
    case email
  }

  var body: some View {
    VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
      Text(CheckoutComponentsStrings.achUserDetailsTitle)
        .font(PrimerFont.bodyLarge(tokens: tokens))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        .multilineTextAlignment(.center)
        .accessibilityIdentifier(AccessibilityIdentifiers.Ach.userDetailsTitle)

      VStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
        makeFirstNameField()
        makeLastNameField()
        makeEmailField()
      }

      Spacer()
        .frame(height: PrimerSpacing.large(tokens: tokens))

      makeSubmitButton()
    }
    .padding(.top, PrimerSpacing.large(tokens: tokens))
    .accessibilityIdentifier(AccessibilityIdentifiers.Ach.userDetailsContainer)
    .onAppear {
      firstName = achState.userDetails.firstName
      lastName = achState.userDetails.lastName
      emailAddress = achState.userDetails.emailAddress
    }
  }

  // MARK: - First Name Field

  @MainActor
  private func makeFirstNameField() -> some View {
    VStack(alignment: .leading, spacing: PrimerSpacing.xsmall(tokens: tokens)) {
      Text(CheckoutComponentsStrings.firstNameLabel)
        .font(PrimerFont.bodyMedium(tokens: tokens))
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

      TextField(CheckoutComponentsStrings.firstNamePlaceholder, text: $firstName)
        .textContentType(.givenName)
        .autocapitalization(.words)
        .disableAutocorrection(true)
        .font(PrimerFont.body(tokens: tokens))
        .padding(PrimerSpacing.medium(tokens: tokens))
        .background(CheckoutColors.background(tokens: tokens))
        .overlay(
          RoundedRectangle(cornerRadius: PrimerRadius.small(tokens: tokens))
            .stroke(fieldBorderColor(hasError: achState.fieldValidation?.firstNameError != nil), lineWidth: 1)
        )
        .cornerRadius(PrimerRadius.small(tokens: tokens))
        .focused($focusedField, equals: .firstName)
        .onSubmit { focusedField = .lastName }
        .onChange(of: firstName) { newValue in
          scope.updateFirstName(newValue)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Ach.firstNameField)
        .accessibilityLabel(CheckoutComponentsStrings.firstNameLabel)

      if let error = achState.fieldValidation?.firstNameError {
        Text(error)
          .font(PrimerFont.bodySmall(tokens: tokens))
          .foregroundColor(CheckoutColors.textNegative(tokens: tokens))
      }
    }
  }

  // MARK: - Last Name Field

  @MainActor
  private func makeLastNameField() -> some View {
    VStack(alignment: .leading, spacing: PrimerSpacing.xsmall(tokens: tokens)) {
      Text(CheckoutComponentsStrings.lastNameLabel)
        .font(PrimerFont.bodyMedium(tokens: tokens))
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

      TextField(CheckoutComponentsStrings.lastNamePlaceholder, text: $lastName)
        .textContentType(.familyName)
        .autocapitalization(.words)
        .disableAutocorrection(true)
        .font(PrimerFont.body(tokens: tokens))
        .padding(PrimerSpacing.medium(tokens: tokens))
        .background(CheckoutColors.background(tokens: tokens))
        .overlay(
          RoundedRectangle(cornerRadius: PrimerRadius.small(tokens: tokens))
            .stroke(fieldBorderColor(hasError: achState.fieldValidation?.lastNameError != nil), lineWidth: 1)
        )
        .cornerRadius(PrimerRadius.small(tokens: tokens))
        .focused($focusedField, equals: .lastName)
        .onSubmit { focusedField = .email }
        .onChange(of: lastName) { newValue in
          scope.updateLastName(newValue)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Ach.lastNameField)
        .accessibilityLabel(CheckoutComponentsStrings.lastNameLabel)

      if let error = achState.fieldValidation?.lastNameError {
        Text(error)
          .font(PrimerFont.bodySmall(tokens: tokens))
          .foregroundColor(CheckoutColors.textNegative(tokens: tokens))
      }
    }
  }

  // MARK: - Email Field

  @MainActor
  private func makeEmailField() -> some View {
    VStack(alignment: .leading, spacing: PrimerSpacing.xsmall(tokens: tokens)) {
      Text(CheckoutComponentsStrings.emailLabel)
        .font(PrimerFont.bodyMedium(tokens: tokens))
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

      TextField(CheckoutComponentsStrings.emailPlaceholder, text: $emailAddress)
        .textContentType(.emailAddress)
        .keyboardType(.emailAddress)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .font(PrimerFont.body(tokens: tokens))
        .padding(PrimerSpacing.medium(tokens: tokens))
        .background(CheckoutColors.background(tokens: tokens))
        .overlay(
          RoundedRectangle(cornerRadius: PrimerRadius.small(tokens: tokens))
            .stroke(fieldBorderColor(hasError: achState.fieldValidation?.emailError != nil), lineWidth: 1)
        )
        .cornerRadius(PrimerRadius.small(tokens: tokens))
        .focused($focusedField, equals: .email)
        .onSubmit {
          focusedField = nil
          if achState.isSubmitEnabled {
            scope.submitUserDetails()
          }
        }
        .onChange(of: emailAddress) { newValue in
          scope.updateEmailAddress(newValue)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Ach.emailField)
        .accessibilityLabel(CheckoutComponentsStrings.emailLabel)

      if let error = achState.fieldValidation?.emailError {
        Text(error)
          .font(PrimerFont.bodySmall(tokens: tokens))
          .foregroundColor(CheckoutColors.textNegative(tokens: tokens))
      }
    }
  }

  // MARK: - Submit Button

  @MainActor
  @ViewBuilder
  private func makeSubmitButton() -> some View {
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

  // MARK: - Helpers

  private func fieldBorderColor(hasError: Bool) -> Color {
    if hasError {
      return CheckoutColors.textNegative(tokens: tokens)
    }
    return CheckoutColors.borderDefault(tokens: tokens)
  }
}
