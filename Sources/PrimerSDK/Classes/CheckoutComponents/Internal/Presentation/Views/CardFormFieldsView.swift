//
//  CardFormFieldsView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length

import SwiftUI

/// Reusable card form fields view that renders card input fields and billing address fields.
/// This component is used by both `CardFormScreen` (full screen) and `DefaultCardFormView` (embeddable).
///
/// Features:
/// - Dynamic card fields (card number, expiry, CVV, cardholder name)
/// - Allowed card networks view
/// - Co-badged cards selector (when multiple networks detected)
/// - Dynamic billing address fields (based on configuration)
/// Which portion of the card form to render. Lets the public `CardFormDefaults` expose the card and
/// billing sections independently while sharing this single config-aware renderer.
@available(iOS 15.0, *)
enum CardFormSection: Equatable {
  case card
  case billing
  case both
  case single(PrimerInputElementType)
}

@available(iOS 15.0, *)
struct CardFormFieldsView: View {
  let scope: any CardFormFieldScopeInternal
  var section: CardFormSection = .both

  @Environment(\.designTokens) private var tokens
  @State private var cardFormState: PrimerCardFormState = .init()
  @State private var formConfiguration: CardFormConfiguration = .default
  @State private var observationTask: Task<Void, Never>?
  @FocusState private var focusedField: PrimerInputElementType?

  var body: some View {
    VStack(spacing: 0) {
      if case let .single(type) = section {
        renderField(type)
      } else {
        if section != .billing {
          cardFieldsSection
        }
        if section != .card {
          billingAddressSection
        }
      }
    }
    .onAppear {
      formConfiguration = scope.getFormConfiguration()
      observeState()
    }
    .onDisappear {
      observationTask?.cancel()
      observationTask = nil
    }
  }

  // MARK: - Card Fields Section

  @MainActor
  @ViewBuilder
  private var cardFieldsSection: some View {
    VStack(spacing: 0) {
      ForEach(0..<formConfiguration.cardFields.count, id: \.self) { index in
        let fieldType = formConfiguration.cardFields[index]

        if fieldType == .expiryDate,
          index + 1 < formConfiguration.cardFields.count,
          formConfiguration.cardFields[index + 1] == .cvv {
          HStack(alignment: .top, spacing: PrimerSpacing.medium(tokens: tokens)) {
            renderField(.expiryDate)
            renderField(.cvv)
          }
        } else if index > 0,
          formConfiguration.cardFields[index - 1] == .expiryDate,
          fieldType == .cvv {
          EmptyView()
        } else {
          renderField(fieldType)
        }
      }
    }
  }

  // MARK: - Billing Address Section

  @ViewBuilder
  @MainActor
  private var billingAddressSection: some View {
    if !formConfiguration.billingFields.isEmpty {
      VStack(alignment: .leading, spacing: PrimerSpacing.small(tokens: tokens)) {
        Text(CheckoutComponentsStrings.billingAddressTitle)
          .font(PrimerFont.headline(tokens: tokens))
          .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

        VStack(spacing: 0) {
          ForEach(0..<formConfiguration.billingFields.count, id: \.self) { index in
            let fieldType = formConfiguration.billingFields[index]

            if fieldType == .firstName,
              index + 1 < formConfiguration.billingFields.count,
              formConfiguration.billingFields[index + 1] == .lastName {
              HStack(alignment: .top, spacing: PrimerSpacing.medium(tokens: tokens)) {
                renderField(.firstName)
                renderField(.lastName)
              }
            } else if index > 0,
              formConfiguration.billingFields[index - 1] == .firstName,
              fieldType == .lastName {
              EmptyView()
            } else {
              renderField(fieldType)
            }
          }
        }
      }
    }
  }

  // MARK: - Dynamic Field Rendering

  @MainActor
  @ViewBuilder
  func renderField(_ fieldType: PrimerInputElementType) -> some View {
    switch fieldType {
    case .cardNumber:
      CardNumberInputField(
        label: CheckoutComponentsStrings.cardNumberLabel,
        placeholder: CheckoutComponentsStrings.cardNumberPlaceholder,
        scope: scope,
        selectedNetwork: getSelectedCardNetwork(),
        availableNetworks: cardFormState.availableNetworks.map(\.network)
      )
      .focused($focusedField, equals: .cardNumber)
      .onSubmit { moveToNextField(from: .cardNumber) }

    case .expiryDate:
      ExpiryDateInputField(
        label: CheckoutComponentsStrings.expiryDateLabel,
        placeholder: CheckoutComponentsStrings.expiryDatePlaceholder,
        scope: scope
      )
      .focused($focusedField, equals: .expiryDate)
      .onSubmit { moveToNextField(from: .expiryDate) }

    case .cvv:
      CVVInputField(
        label: CheckoutComponentsStrings.cvvLabel,
        placeholder: getCardNetworkForCvv() == .amex
          ? CheckoutComponentsStrings.cvvAmexPlaceholder
          : CheckoutComponentsStrings.cvvStandardPlaceholder,
        scope: scope,
        cardNetwork: getCardNetworkForCvv()
      )
      .focused($focusedField, equals: .cvv)
      .onSubmit { moveToNextField(from: .cvv) }

    case .cardholderName:
      CardholderNameInputField(
        label: CheckoutComponentsStrings.cardholderNameLabel,
        placeholder: CheckoutComponentsStrings.fullNamePlaceholder,
        scope: scope
      )
      .focused($focusedField, equals: .cardholderName)
      .onSubmit { moveToNextField(from: .cardholderName) }

    case .postalCode:
      PostalCodeInputField(
        label: CheckoutComponentsStrings.postalCodeLabel,
        placeholder: CheckoutComponentsStrings.postalCodePlaceholder,
        scope: scope
      )
      .focused($focusedField, equals: .postalCode)
      .onSubmit { moveToNextField(from: .postalCode) }

    case .countryCode:
      CountryInputField(
        label: CheckoutComponentsStrings.countryLabel,
        placeholder: CheckoutComponentsStrings.selectCountryPlaceholder,
        scope: scope
      )
      .focused($focusedField, equals: .countryCode)
      .onSubmit { moveToNextField(from: .countryCode) }

    case .city:
      CityInputField(
        label: CheckoutComponentsStrings.cityLabel,
        placeholder: CheckoutComponentsStrings.cityPlaceholder,
        scope: scope
      )
      .focused($focusedField, equals: .city)
      .onSubmit { moveToNextField(from: .city) }

    case .state:
      StateInputField(
        label: CheckoutComponentsStrings.stateLabel,
        placeholder: CheckoutComponentsStrings.statePlaceholder,
        scope: scope
      )
      .focused($focusedField, equals: .state)
      .onSubmit { moveToNextField(from: .state) }

    case .addressLine1:
      AddressLineInputField(
        label: CheckoutComponentsStrings.addressLine1Label,
        placeholder: CheckoutComponentsStrings.addressLine1Placeholder,
        isRequired: true,
        inputType: .addressLine1,
        scope: scope
      )
      .focused($focusedField, equals: .addressLine1)
      .onSubmit { moveToNextField(from: .addressLine1) }

    case .addressLine2:
      AddressLineInputField(
        label: CheckoutComponentsStrings.addressLine2Label,
        placeholder: CheckoutComponentsStrings.addressLine2Placeholder,
        isRequired: false,
        inputType: .addressLine2,
        scope: scope
      )
      .focused($focusedField, equals: .addressLine2)
      .onSubmit { moveToNextField(from: .addressLine2) }

    case .phoneNumber:
      NameInputField(
        label: CheckoutComponentsStrings.phoneNumberLabel,
        placeholder: CheckoutComponentsStrings.phoneNumberPlaceholder,
        inputType: .phoneNumber,
        scope: scope
      )
      .focused($focusedField, equals: .phoneNumber)
      .onSubmit { moveToNextField(from: .phoneNumber) }

    case .firstName:
      NameInputField(
        label: CheckoutComponentsStrings.firstNameLabel,
        placeholder: CheckoutComponentsStrings.firstNamePlaceholder,
        inputType: .firstName,
        scope: scope
      )
      .focused($focusedField, equals: .firstName)
      .onSubmit { moveToNextField(from: .firstName) }

    case .lastName:
      NameInputField(
        label: CheckoutComponentsStrings.lastNameLabel,
        placeholder: CheckoutComponentsStrings.lastNamePlaceholder,
        inputType: .lastName,
        scope: scope
      )
      .focused($focusedField, equals: .lastName)
      .onSubmit { moveToNextField(from: .lastName) }

    case .email:
      EmailInputField(
        label: CheckoutComponentsStrings.emailLabel,
        placeholder: CheckoutComponentsStrings.emailPlaceholder,
        scope: scope
      )
      .focused($focusedField, equals: .email)
      .onSubmit { moveToNextField(from: .email) }

    case .retailer:
      Text(CheckoutComponentsStrings.retailOutletNotImplemented)
        .font(PrimerFont.caption(tokens: tokens))
        .foregroundColor(CheckoutColors.gray(tokens: tokens))
        .padding(PrimerSpacing.large(tokens: tokens))

    case .otp:
      OTPCodeInputField(
        label: CheckoutComponentsStrings.otpLabel,
        placeholder: CheckoutComponentsStrings.otpCodeNumericPlaceholder,
        scope: scope
      )
      .focused($focusedField, equals: .otp)
      .onSubmit { moveToNextField(from: .otp) }

    case .unknown, .all:
      EmptyView()
    }
  }

  // MARK: - Helper Methods

  private func getSelectedCardNetwork() -> CardNetwork? {
    if let network = cardFormState.selectedNetwork {
      return network.network
    }
    return nil
  }

  private func getCardNetworkForCvv() -> CardNetwork {
    if let network = cardFormState.selectedNetwork {
      return network.network
    }
    return .unknown
  }

  // MARK: - Focus Management

  private func moveToNextField(from currentField: PrimerInputElementType) {
    let cardFields = formConfiguration.cardFields
    let billingFields = formConfiguration.billingFields

    if let currentIndex = cardFields.firstIndex(of: currentField) {
      if currentIndex + 1 < cardFields.count {
        focusedField = cardFields[currentIndex + 1]
        return
      }
      if !billingFields.isEmpty {
        focusedField = billingFields.first
        return
      }
      focusedField = nil
      return
    }

    if let currentIndex = billingFields.firstIndex(of: currentField) {
      if currentIndex + 1 < billingFields.count {
        focusedField = billingFields[currentIndex + 1]
        return
      }
      focusedField = nil
      return
    }

    focusedField = nil
  }

  // MARK: - State Observation

  private func observeState() {
    observationTask?.cancel()
    observationTask = Task { @MainActor in
      for await state in scope.state {
        cardFormState = state
      }
    }
  }
}

// swiftlint:enable file_length
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
