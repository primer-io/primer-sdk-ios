//
//  BillingAddressView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct BillingAddressConfiguration {
  let showFirstName: Bool
  let showLastName: Bool
  let showEmail: Bool
  let showPhoneNumber: Bool
  let showAddressLine1: Bool
  let showAddressLine2: Bool
  let showCity: Bool
  let showState: Bool
  let showPostalCode: Bool
  let showCountry: Bool
}

@available(iOS 15.0, *)
struct BillingAddressView: View, LogReporter {
  // MARK: - Properties

  let cardFormScope: DefaultCardFormScope
  let configuration: BillingAddressConfiguration
  let styling: PrimerFieldStyling?

  @Environment(\.designTokens) private var tokens

  // MARK: - Initialization

  init(
    cardFormScope: DefaultCardFormScope,
    configuration: BillingAddressConfiguration,
    styling: PrimerFieldStyling? = nil
  ) {
    self.cardFormScope = cardFormScope
    self.configuration = configuration
    self.styling = styling
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: 0) {
      // Name fields (horizontal layout)
      if configuration.showFirstName || configuration.showLastName {
        HStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
          if configuration.showFirstName {
            defaultFirstNameField()
          }

          if configuration.showLastName {
            defaultLastNameField()
          }
        }
      }

      // Country - Show first to match Drop-in layout
      if configuration.showCountry {
        defaultCountryField()
      }

      // Address Line 1
      if configuration.showAddressLine1 {
        defaultAddressLine1Field()
      }

      // Postal Code - Show before state to match Drop-in layout
      if configuration.showPostalCode {
        defaultPostalCodeField()
      }

      // State/Region - Show after postal code to match Drop-in layout
      if configuration.showState {
        defaultStateField()
      }

      // Address Line 2 (Optional)
      if configuration.showAddressLine2 {
        defaultAddressLine2Field()
      }

      // City - After address fields
      if configuration.showCity {
        defaultCityField()
      }

      // Email - Near the end
      if configuration.showEmail {
        defaultEmailField()
      }

      // Phone Number - Last field
      if configuration.showPhoneNumber {
        defaultPhoneNumberField()
      }
    }
  }

  // MARK: - Default Field Implementations

  @ViewBuilder
  private func defaultFirstNameField() -> some View {
    NameInputField(
      label: CheckoutComponentsStrings.firstNameLabel,
      placeholder: CheckoutComponentsStrings.firstNamePlaceholder,
      inputType: .firstName,
      scope: cardFormScope,
      styling: styling
    )
  }

  @ViewBuilder
  private func defaultLastNameField() -> some View {
    NameInputField(
      label: CheckoutComponentsStrings.lastNameLabel,
      placeholder: CheckoutComponentsStrings.lastNamePlaceholder,
      inputType: .lastName,
      scope: cardFormScope,
      styling: styling
    )
  }

  @ViewBuilder
  private func defaultCountryField() -> some View {
    CountryInputField(
      label: CheckoutComponentsStrings.countryLabel,
      placeholder: CheckoutComponentsStrings.countrySelectorPlaceholder,
      scope: cardFormScope,
      styling: styling
    )
  }

  @ViewBuilder
  private func defaultAddressLine1Field() -> some View {
    AddressLineInputField(
      label: CheckoutComponentsStrings.addressLine1Label,
      placeholder: CheckoutComponentsStrings.addressLine1Placeholder,
      isRequired: true,
      inputType: .addressLine1,
      scope: cardFormScope,
      styling: styling
    )
  }

  @ViewBuilder
  private func defaultAddressLine2Field() -> some View {
    AddressLineInputField(
      label: CheckoutComponentsStrings.addressLine2Label,
      placeholder: CheckoutComponentsStrings.addressLine2Placeholder,
      isRequired: false,
      inputType: .addressLine2,
      scope: cardFormScope,
      styling: styling
    )
  }

  @ViewBuilder
  private func defaultCityField() -> some View {
    CityInputField(
      label: CheckoutComponentsStrings.cityLabel,
      placeholder: CheckoutComponentsStrings.cityPlaceholder,
      scope: cardFormScope,
      styling: styling
    )
  }

  @ViewBuilder
  private func defaultStateField() -> some View {
    StateInputField(
      label: CheckoutComponentsStrings.stateLabel,
      placeholder: CheckoutComponentsStrings.statePlaceholder,
      scope: cardFormScope,
      styling: styling
    )
  }

  @ViewBuilder
  private func defaultPostalCodeField() -> some View {
    PostalCodeInputField(
      label: CheckoutComponentsStrings.postalCodeLabel,
      placeholder: CheckoutComponentsStrings.postalCodePlaceholder,
      scope: cardFormScope,
      styling: styling
    )
  }

  @ViewBuilder
  private func defaultEmailField() -> some View {
    EmailInputField(
      label: CheckoutComponentsStrings.emailLabel,
      placeholder: CheckoutComponentsStrings.emailPlaceholder,
      scope: cardFormScope,
      styling: styling
    )
  }

  @ViewBuilder
  private func defaultPhoneNumberField() -> some View {
    // Using NameInputField with phoneNumber type for phone number input
    NameInputField(
      label: CheckoutComponentsStrings.phoneNumberLabel,
      placeholder: CheckoutComponentsStrings.phoneNumberPlaceholder,
      inputType: .phoneNumber,
      scope: cardFormScope,
      styling: styling
    )
  }
}
