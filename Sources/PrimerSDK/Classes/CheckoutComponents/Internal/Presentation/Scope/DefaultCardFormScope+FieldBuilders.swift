//
//  DefaultCardFormScope+FieldBuilders.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable identifier_name

import SwiftUI

// MARK: - ViewBuilder Method Implementations

@available(iOS 15.0, *)
extension DefaultCardFormScope {

  public func PrimerCardNumberField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    CardNumberInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.cardNumberPlaceholder,
      scope: self,
      selectedNetwork: structuredState.selectedNetwork?.network,
      styling: styling
    ).asAny()
  }

  public func PrimerExpiryDateField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    ExpiryDateInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.expiryDateAlternativePlaceholder,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerCvvField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    CVVInputField(
      label: label,
      placeholder: getCardNetworkForCvv() == .amex
        ? CheckoutComponentsStrings.cvvAmexPlaceholder
        : CheckoutComponentsStrings.cvvStandardPlaceholder,
      scope: self,
      cardNetwork: structuredState.selectedNetwork?.network ?? getCardNetworkForCvv(),
      styling: styling
    ).asAny()
  }

  public func PrimerCardholderNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    CardholderNameInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.fullNamePlaceholder,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerCountryField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    CountryInputFieldWrapper(
      scope: self,
      label: label,
      placeholder: CheckoutComponentsStrings.selectCountryPlaceholder,
      styling: styling,
      onValidationChange: nil,
      onOpenCountrySelector: nil
    ).asAny()
  }

  public func PrimerPostalCodeField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    PostalCodeInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.postalCodePlaceholder,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerCityField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    CityInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.cityPlaceholder,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerStateField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    StateInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.statePlaceholder,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerAddressLine1Field(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    AddressLineInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.addressLine1Placeholder,
      isRequired: true,
      inputType: .addressLine1,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerAddressLine2Field(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    AddressLineInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.addressLine2Placeholder,
      isRequired: false,
      inputType: .addressLine2,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerFirstNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    NameInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.firstNamePlaceholder,
      inputType: .firstName,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerLastNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    NameInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.lastNamePlaceholder,
      inputType: .lastName,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerEmailField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    EmailInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.emailPlaceholder,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerPhoneNumberField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    NameInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.phoneNumberPlaceholder,
      inputType: .phoneNumber,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerRetailOutletField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    NameInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.retailOutletPlaceholder,
      inputType: .retailer,
      scope: self,
      styling: styling
    ).asAny()
  }

  public func PrimerOtpCodeField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
    OTPCodeInputField(
      label: label,
      placeholder: CheckoutComponentsStrings.otpCodePlaceholder,
      scope: self,
      styling: styling
    ).asAny()
  }

  /// Returns a complete card form view with all card and billing address fields.
  /// This provides an embeddable card form for custom payment selection screens.
  /// - Parameter styling: Optional styling configuration for fields. Default: nil (uses SDK default styling)
  /// - Returns: A view containing all card form fields based on current configuration.
  public func DefaultCardFormView(styling: PrimerFieldStyling?) -> AnyView {
    CardFormFieldsView(scope: self, styling: styling).asAny()
  }
}

extension View {
  fileprivate func asAny() -> AnyView { AnyView(self) }
}

// swiftlint:enable identifier_name
