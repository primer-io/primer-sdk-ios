//
//  BillingAddressRedirectScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct BillingAddressRedirectScreen: View {

  let scope: any PrimerBillingAddressRedirectScope

  @Environment(\.designTokens) private var tokens
  @Environment(\.diContainer) private var container
  @State private var billingState = PrimerBillingAddressRedirectState()
  @State private var validationService: ValidationService?

  // MARK: - Local field state for text fields

  @State private var countryCode = ""
  @State private var addressLine1 = ""
  @State private var addressLine2 = ""
  @State private var postalCode = ""
  @State private var city = ""
  @State private var state = ""

  var body: some View {
    ScrollView {
      VStack(spacing: PrimerSpacing.xxlarge(tokens: tokens)) {
        makeHeaderSection()
        makeBillingAddressForm()
        makeSubmitButtonSection()
      }
      .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
      .padding(.vertical, PrimerSpacing.large(tokens: tokens))
    }
    .frame(maxWidth: UIScreen.main.bounds.width)
    .navigationBarHidden(true)
    .background(CheckoutColors.background(tokens: tokens))
    .accessibilityIdentifier(AccessibilityIdentifiers.BillingAddressRedirect.screen)
    .task {
      for await newState in scope.state {
        billingState = newState
      }
    }
    .onAppear { resolveValidationService() }
  }

  // MARK: - Header

  private func makeHeaderSection() -> some View {
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
          .accessibility(config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.BillingAddressRedirect.backButton,
            label: CheckoutComponentsStrings.a11yBack,
            traits: [.isButton]
          ))
        }

        Spacer()

        if scope.dismissalMechanism.contains(.closeButton) {
          Button(CheckoutComponentsStrings.cancelButton, action: scope.cancel)
            .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        }
      }

      Text(paymentMethodDisplayName)
        .font(PrimerFont.titleXLarge(tokens: tokens))
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)

      if let surcharge = billingState.surchargeAmount {
        Text(surcharge)
          .font(PrimerFont.bodySmall(tokens: tokens))
          .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
      }
    }
  }

  // MARK: - Billing Address Form

  private func makeBillingAddressForm() -> some View {
    VStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
      makeCountryField()
      makeTextField(
        label: CheckoutComponentsStrings.addressLine1Label,
        placeholder: CheckoutComponentsStrings.addressLine1Placeholder,
        text: $addressLine1,
        fieldType: .addressLine1,
        identifier: AccessibilityIdentifiers.BillingAddressRedirect.addressLine1Field,
        onUpdate: scope.updateAddressLine1
      )
      makeTextField(
        label: CheckoutComponentsStrings.addressLine2Label,
        placeholder: CheckoutComponentsStrings.addressLine2Placeholder,
        text: $addressLine2,
        fieldType: .addressLine2,
        identifier: AccessibilityIdentifiers.BillingAddressRedirect.addressLine2Field,
        onUpdate: scope.updateAddressLine2
      )
      HStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
        makeTextField(
          label: CheckoutComponentsStrings.postalCodeLabel,
          placeholder: CheckoutComponentsStrings.postalCodePlaceholder,
          text: $postalCode,
          fieldType: .postalCode,
          identifier: AccessibilityIdentifiers.BillingAddressRedirect.postalCodeField,
          onUpdate: scope.updatePostalCode
        )
        makeTextField(
          label: CheckoutComponentsStrings.cityLabel,
          placeholder: CheckoutComponentsStrings.cityPlaceholder,
          text: $city,
          fieldType: .city,
          identifier: AccessibilityIdentifiers.BillingAddressRedirect.cityField,
          onUpdate: scope.updateCity
        )
      }
      makeTextField(
        label: CheckoutComponentsStrings.stateLabel,
        placeholder: CheckoutComponentsStrings.statePlaceholder,
        text: $state,
        fieldType: .state,
        identifier: AccessibilityIdentifiers.BillingAddressRedirect.stateField,
        onUpdate: scope.updateState
      )
    }
  }

  private func makeCountryField() -> some View {
    VStack(alignment: .leading, spacing: PrimerSpacing.xsmall(tokens: tokens)) {
      Text(CheckoutComponentsStrings.countryLabel)
        .font(PrimerFont.bodySmall(tokens: tokens))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))

      Menu {
        ForEach(CountryCode.allCases, id: \.self) { country in
          Button {
            countryCode = country.rawValue
            scope.updateCountryCode(country.rawValue)
          } label: {
            Text("\(country.flag) \(country.country)")
          }
        }
      } label: {
        HStack {
          if let selected = CountryCode(rawValue: countryCode) {
            Text("\(selected.flag ?? "") \(selected.country)")
              .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
          } else {
            Text(CheckoutComponentsStrings.countrySelectorPlaceholder)
              .foregroundColor(CheckoutColors.textPlaceholder(tokens: tokens))
          }
          Spacer()
          Image(systemName: "chevron.down")
            .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        }
        .font(PrimerFont.bodyLarge(tokens: tokens))
        .padding(.vertical, PrimerSpacing.medium(tokens: tokens))
        .padding(.horizontal, PrimerSpacing.medium(tokens: tokens))
        .background(CheckoutColors.background(tokens: tokens))
        .overlay(
          RoundedRectangle(cornerRadius: PrimerRadius.small(tokens: tokens))
            .stroke(fieldBorderColor(for: .countryCode), lineWidth: PrimerBorderWidth.standard)
        )
      }
      .accessibilityIdentifier(AccessibilityIdentifiers.BillingAddressRedirect.countryCodeField)

      if let error = billingState.errors[.countryCode] {
        Text(error.message)
          .font(PrimerFont.bodySmall(tokens: tokens))
          .foregroundColor(CheckoutColors.textNegative(tokens: tokens))
      }
    }
  }

  private func makeTextField(
    label: String,
    placeholder: String,
    text: Binding<String>,
    fieldType: PrimerInputElementType,
    identifier: String,
    onUpdate: @escaping (String) -> Void
  ) -> some View {
    VStack(alignment: .leading, spacing: PrimerSpacing.xsmall(tokens: tokens)) {
      Text(label)
        .font(PrimerFont.bodySmall(tokens: tokens))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))

      TextField(placeholder, text: text)
        .font(PrimerFont.bodyLarge(tokens: tokens))
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        .padding(.vertical, PrimerSpacing.medium(tokens: tokens))
        .padding(.horizontal, PrimerSpacing.medium(tokens: tokens))
        .background(CheckoutColors.background(tokens: tokens))
        .overlay(
          RoundedRectangle(cornerRadius: PrimerRadius.small(tokens: tokens))
            .stroke(fieldBorderColor(for: fieldType), lineWidth: PrimerBorderWidth.standard)
        )
        .autocapitalization(.words)
        .disableAutocorrection(true)
        .accessibilityIdentifier(identifier)
        .onChange(of: text.wrappedValue) { newValue in
          onUpdate(newValue)
        }

      if let error = billingState.errors[fieldType] {
        Text(error.message)
          .font(PrimerFont.bodySmall(tokens: tokens))
          .foregroundColor(CheckoutColors.textNegative(tokens: tokens))
      }
    }
  }

  private func fieldBorderColor(for fieldType: PrimerInputElementType) -> Color {
    billingState.errors[fieldType] != nil
      ? CheckoutColors.textNegative(tokens: tokens)
      : CheckoutColors.borderDefault(tokens: tokens)
  }

  // MARK: - Submit Button

  @ViewBuilder
  private func makeSubmitButtonSection() -> some View {
    if let customButton = scope.submitButton {
      AnyView(customButton(scope))
    } else {
      Button(action: scope.submit) {
        makeSubmitButtonContent()
      }
      .disabled(isButtonDisabled)
    }
  }

  private func makeSubmitButtonContent() -> some View {
    let isLoading = [.submitting, .redirecting, .polling].contains(billingState.status)

    return HStack {
      if isLoading {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: CheckoutColors.white(tokens: tokens)))
          .scaleEffect(PrimerScale.small)
      } else {
        Text(submitButtonText)
      }
    }
    .font(PrimerFont.body(tokens: tokens))
    .foregroundColor(CheckoutColors.white(tokens: tokens))
    .frame(maxWidth: .infinity)
    .padding(.vertical, PrimerSpacing.large(tokens: tokens))
    .background(submitButtonBackground)
    .cornerRadius(PrimerRadius.small(tokens: tokens))
    .accessibility(config: AccessibilityConfiguration(
      identifier: AccessibilityIdentifiers.BillingAddressRedirect.submitButton,
      label: submitButtonText,
      traits: [.isButton]
    ))
  }

  private var submitButtonText: String {
    scope.submitButtonText ?? CheckoutComponentsStrings.webRedirectButtonContinue(paymentMethodDisplayName)
  }

  private var submitButtonBackground: Color {
    isButtonDisabled
      ? CheckoutColors.gray300(tokens: tokens)
      : CheckoutColors.textPrimary(tokens: tokens)
  }

  private var isButtonDisabled: Bool {
    !billingState.isFormValid || [.submitting, .redirecting, .polling].contains(billingState.status)
  }

  private var paymentMethodDisplayName: String {
    billingState.paymentMethod?.name ?? scope.paymentMethodType
  }

  private func resolveValidationService() {
    guard let container else { return }
    validationService = try? container.resolveSync(ValidationService.self)
  }
}
