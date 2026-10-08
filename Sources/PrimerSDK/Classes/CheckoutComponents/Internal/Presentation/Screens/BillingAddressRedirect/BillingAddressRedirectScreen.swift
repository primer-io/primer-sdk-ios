//
//  BillingAddressRedirectScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
struct BillingAddressRedirectScreen: View {

  let scope: any PrimerBillingAddressRedirectScope

  @Environment(\.designTokens) private var tokens
  @State private var billingState = PrimerBillingAddressRedirectState()

  // MARK: - Local field state for text fields

  @State private var countryCode = ""
  @State private var addressLine1 = ""
  @State private var addressLine2 = ""
  @State private var postalCode = ""
  @State private var city = ""
  @State private var state = ""
  @FocusState private var focusedField: PrimerInputElementType?

  var body: some View {
    ScrollView {
      VStack(spacing: PrimerSpacing.xxlarge(tokens: tokens)) {
        makeHeaderSection()
        makeBillingAddressForm()
          .environment(\.isInputEnabled, !isSubmitInFlight)
        makeSubmitButtonSection()
      }
      .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
      .padding(.vertical, PrimerSpacing.large(tokens: tokens))
    }
    .frame(maxWidth: .infinity)
    .navigationBarHidden(true)
    .background(CheckoutColors.background(tokens: tokens))
    .accessibilityIdentifier(AccessibilityIdentifiers.BillingAddressRedirect.screen)
    .task {
      for await newState in scope.state {
        billingState = newState
      }
    }
    .onChange(of: isSubmitInFlight) { if $0 { focusedField = nil } }
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
                .foregroundColor(CheckoutColors.iconPrimary(tokens: tokens))
              Text(CheckoutComponentsStrings.backButton)
                .primerTypography(.bodyMedium, tokens: tokens)
            }
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
          }
          .buttonStyle(PlainButtonStyle())
          .accessibility(config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.BillingAddressRedirect.backButton,
            label: CheckoutComponentsStrings.a11yBack,
            traits: [.isButton]
          ))
        }

        Spacer()

        if scope.dismissalMechanism.contains(.closeButton) {
          CheckoutHeaderButton(config: .closeButton(action: scope.cancel))
        }
      }

      Text(paymentMethodDisplayName)
        .primerTypography(.titleXLarge, tokens: tokens)
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)

      if let surcharge = billingState.surchargeAmount {
        Text(surcharge)
          .primerTypography(.bodySmall, tokens: tokens)
          .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
      }
    }
  }

  // MARK: - Billing Address Form

  private func makeBillingAddressForm() -> some View {
    // Each field container pads its own bottom, as in the card form.
    VStack(spacing: 0) {
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
      // Top-aligned, as in the card form: an error under one field must not push its neighbour down.
      HStack(alignment: .top, spacing: PrimerSpacing.medium(tokens: tokens)) {
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
    PrimerInputFieldContainer(
      label: CheckoutComponentsStrings.countryLabel,
      text: $countryCode,
      isValid: .constant(billingState.errors[.countryCode] == nil),
      errorMessage: errorBinding(for: .countryCode),
      // A menu takes no keyboard focus, so it never paints the focused border.
      isFocused: .constant(false)
    ) {
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
              .foregroundColor(CheckoutColors.inputText(tokens: tokens, isEnabled: !isSubmitInFlight))
              .primerFieldTypography(.bodyLarge, tokens: tokens)
          } else {
            Text(CheckoutComponentsStrings.countrySelectorPlaceholder)
              .foregroundColor(CheckoutColors.textPlaceholder(tokens: tokens))
              .primerFieldTypography(.bodyLarge, tokens: tokens)
          }
          Spacer(minLength: 0)
          Image(systemName: "chevron.down")
            .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
            .font(PrimerFont.bodyLarge(tokens: tokens))
        }
      }
      .accessibilityIdentifier(
        AccessibilityIdentifiers.inputField(within: AccessibilityIdentifiers.BillingAddressRedirect.countryCodeField))
    }
    .accessibility(
      config: fieldAccessibility(
        for: .countryCode,
        identifier: AccessibilityIdentifiers.BillingAddressRedirect.countryCodeField,
        label: CheckoutComponentsStrings.countryLabel
      ),
      combinesChildren: false
    )
  }

  private func makeTextField(
    label: String,
    placeholder: String,
    text: Binding<String>,
    fieldType: PrimerInputElementType,
    identifier: String,
    onUpdate: @escaping (String) -> Void
  ) -> some View {
    PrimerInputFieldContainer(
      label: label,
      text: text,
      isValid: .constant(billingState.errors[fieldType] == nil),
      errorMessage: errorBinding(for: fieldType),
      isFocused: focusBinding(for: fieldType)
    ) {
      TextField(placeholder, text: text)
        .primerFieldTypography(.bodyLarge, tokens: tokens)
        .foregroundColor(CheckoutColors.inputText(tokens: tokens, isEnabled: !isSubmitInFlight))
        .focused($focusedField, equals: fieldType)
        .autocapitalization(.words)
        .disableAutocorrection(true)
        .accessibilityIdentifier(AccessibilityIdentifiers.inputField(within: identifier))
        .tint(CheckoutColors.borderFocus(tokens: tokens))
        .onChange(of: text.wrappedValue, perform: onUpdate)
    }
    .accessibility(
      config: fieldAccessibility(for: fieldType, identifier: identifier, label: label),
      combinesChildren: false
    )
  }

  /// The container combines label, field and error into one element, so the element carries the
  /// field's identifier and its error, and the field inside keeps an `_input` identifier of its own.
  private func fieldAccessibility(
    for fieldType: PrimerInputElementType,
    identifier: String,
    label: String
  ) -> AccessibilityConfiguration {
    AccessibilityConfiguration(
      identifier: identifier,
      label: label,
      hint: accessibilityHint(for: fieldType),
      value: billingState.errors[fieldType]?.message,
      traits: []
    )
  }

  private func accessibilityHint(for fieldType: PrimerInputElementType) -> String? {
    switch fieldType {
    case .countryCode: CheckoutComponentsStrings.a11yBillingAddressCountryHint
    case .addressLine1, .addressLine2: CheckoutComponentsStrings.a11yBillingAddressHint
    case .postalCode: CheckoutComponentsStrings.a11yBillingAddressPostalCodeHint
    case .city: CheckoutComponentsStrings.a11yBillingAddressCityHint
    case .state: CheckoutComponentsStrings.a11yBillingAddressStateHint
    default: nil
    }
  }

  private func errorBinding(for fieldType: PrimerInputElementType) -> Binding<String?> {
    .constant(billingState.errors[fieldType]?.message)
  }

  /// The container only reads this, and focus is owned by `focusedField`.
  private func focusBinding(for fieldType: PrimerInputElementType) -> Binding<Bool> {
    Binding(get: { focusedField == fieldType }, set: { _ in })
  }

  // MARK: - Submit Button

  @ViewBuilder
  private func makeSubmitButtonSection() -> some View {
    if let customButton = scope.submitButton {
      AnyView(customButton(scope))
    } else {
      PrimerCheckoutButton(
        submitButtonText,
        isEnabled: billingState.isFormValid,
        isLoading: isSubmitInFlight,
        accessibilityConfiguration: AccessibilityConfiguration(
          identifier: AccessibilityIdentifiers.BillingAddressRedirect.submitButton,
          label: submitButtonText,
          traits: [.isButton]
        ),
        action: scope.submit
      )
    }
  }

  private var submitButtonText: String {
    scope.submitButtonText ?? CheckoutComponentsStrings.webRedirectButtonContinue(paymentMethodDisplayName)
  }

  /// The button keeps its brand fill while the payment is in flight; only an invalid form greys it out.
  private var isSubmitInFlight: Bool {
    [.submitting, .redirecting, .polling].contains(billingState.status)
  }

  private var paymentMethodDisplayName: String {
    billingState.paymentMethod?.name ?? scope.paymentMethodType
  }
}
