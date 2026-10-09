//
//  PrimerCardFormScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable identifier_name

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Scope interface for the card payment form, providing field management and UI customization.
///
/// `PrimerCardFormScope` is the primary interface for interacting with card payment forms
/// in CheckoutComponents. It provides:
/// - State observation for form fields, validation, and co-badged card networks
/// - Methods to update individual field values
/// - UI customization at field, section, and screen levels
/// - Navigation and submission controls
///
/// ## State Observation
/// Use the `state` async stream to observe form changes:
/// ```swift
/// for await formState in cardFormScope.state {
///     if formState.isValid {
///         enableSubmitButton()
///     }
///     if let network = formState.selectedNetwork {
///         updateNetworkIcon(network)
///     }
/// }
/// ```
///
/// ## Field Updates
/// Update individual fields using the provided methods:
/// ```swift
/// cardFormScope.updateCardNumber("4242424242424242")
/// cardFormScope.updateExpiryDate("12/25")
/// cardFormScope.updateCvv("123")
/// ```
///
/// ## UI Customization
/// Customize the form by embedding `PrimerCardForm` and overriding its `@ViewBuilder` section
/// slots, composing around `CardFormDefaults`:
/// ```swift
/// PrimerCardForm(cardDetails: { session in
///     VStack {
///         CardFormDefaults.cardNumber(session)
///         CardFormDefaults.expiryDate(session)
///         CardFormDefaults.cvv(session)
///     }
/// })
/// ```
@available(iOS 15.0, *)
@MainActor
protocol PrimerCardFormScope: PrimerPaymentMethodScope
where State == PrimerCardFormState {

  /// Card form-specific UI options from the SDK settings.
  var cardFormUIOptions: PrimerCardFormUIOptions? { get }

  // MARK: - Update Methods

  func updateCardNumber(_ cardNumber: String)
  func updateCvv(_ cvv: String)
  func updateExpiryDate(_ expiryDate: String)
  func updateCardholderName(_ cardholderName: String)
  func updatePostalCode(_ postalCode: String)
  func updateCity(_ city: String)
  func updateState(_ state: String)
  func updateAddressLine1(_ addressLine1: String)
  func updateAddressLine2(_ addressLine2: String)
  func updatePhoneNumber(_ phoneNumber: String)
  func updateFirstName(_ firstName: String)
  func updateLastName(_ lastName: String)
  func updateRetailOutlet(_ retailOutlet: String)
  func updateOtpCode(_ otpCode: String)
  func updateEmail(_ email: String)
  func updateExpiryMonth(_ month: String)
  func updateExpiryYear(_ year: String)
  func updateSelectedCardNetwork(_ network: String)
  func updateCountryCode(_ countryCode: String)

  // MARK: - Structured State Support

  func updateField(_ fieldType: PrimerInputElementType, value: String)
  func getFieldValue(_ fieldType: PrimerInputElementType) -> String
  func setFieldError(_ fieldType: PrimerInputElementType, message: String, errorCode: String?)
  func clearFieldError(_ fieldType: PrimerInputElementType)
  func getFieldError(_ fieldType: PrimerInputElementType) -> String?
  func getFormConfiguration() -> CardFormConfiguration

}

// MARK: - Structured State Default Implementations

@available(iOS 15.0, *)
extension PrimerCardFormScope {

  func updateField(_ fieldType: PrimerInputElementType, value: String) {
    switch fieldType {
    case .cardNumber:
      updateCardNumber(value)
    case .cvv:
      updateCvv(value)
    case .expiryDate:
      updateExpiryDate(value)
    case .cardholderName:
      updateCardholderName(value)
    case .postalCode:
      updatePostalCode(value)
    case .countryCode:
      updateCountryCode(value)
    case .city:
      updateCity(value)
    case .state:
      updateState(value)
    case .addressLine1:
      updateAddressLine1(value)
    case .addressLine2:
      updateAddressLine2(value)
    case .phoneNumber:
      updatePhoneNumber(value)
    case .firstName:
      updateFirstName(value)
    case .lastName:
      updateLastName(value)
    case .email:
      updateEmail(value)
    case .retailer:
      updateRetailOutlet(value)
    case .otp:
      updateOtpCode(value)
    case .unknown, .all:
      break  // Not implemented for these special cases
    }
  }

  func getFieldValue(_ fieldType: PrimerInputElementType) -> String {
    ""
  }

  func setFieldError(_ fieldType: PrimerInputElementType, message: String, errorCode: String?) {}

  func clearFieldError(_ fieldType: PrimerInputElementType) {
  }

  func getFieldError(_ fieldType: PrimerInputElementType) -> String? {
    nil
  }

  func getFormConfiguration() -> CardFormConfiguration {
    CardFormConfiguration.default
  }
}

// swiftlint:enable identifier_name
