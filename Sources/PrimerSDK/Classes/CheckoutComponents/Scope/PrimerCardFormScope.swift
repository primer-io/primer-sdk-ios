//
//  PrimerCardFormScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable identifier_name

import SwiftUI

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
/// Customize the form at multiple levels:
/// ```swift
/// // Field-level customization
/// cardFormScope.cardNumberConfig = InputFieldConfig(label: "Card Number")
///
/// // Section-level customization
/// cardFormScope.cardInputSection = { AnyView(MyCustomCardSection()) }
///
/// // Full screen replacement
/// cardFormScope.screen = { scope in AnyView(MyCustomCardForm(scope: scope)) }
/// ```
@available(iOS 15.0, *)
@MainActor
public protocol PrimerCardFormScope: PrimerPaymentMethodScope
where State == PrimerCardFormState {

  /// Async stream of the current card form state including field values, validation, and networks.
  var state: AsyncStream<PrimerCardFormState> { get }

  /// The presentation context indicating how the form was navigated to.
  var presentationContext: PresentationContext { get }

  /// Card form-specific UI options from the SDK settings.
  var cardFormUIOptions: PrimerCardFormUIOptions? { get }

  /// Controls how users can dismiss the card form.
  var dismissalMechanism: [DismissalMechanism] { get }

  // MARK: - Payment Method Lifecycle

  /// Initializes the card form and begins field observation.
  func start()

  /// Submits the card form for tokenization and payment processing.
  func submit()

  /// Cancels the card form and returns to the previous screen.
  func cancel()

  // MARK: - Navigation Methods

  /// Called when the user taps the submit/pay button.
  func onSubmit()

  /// Called when the user taps the back button.
  func onBack()

  /// Called when the user cancels the card form.
  func onCancel()

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

  // MARK: - Nested Scope

  var selectCountry: PrimerSelectCountryScope { get }

  // MARK: - Screen-Level Customization

  var title: String? { get set }
  var screen: CardFormScreenComponent? { get set }
  var cobadgedCardsView:
    ((_ availableNetworks: [String], _ selectNetwork: @escaping (String) -> Void) -> any View)?
  { get set }
  var errorView: ErrorComponent? { get set }

  // MARK: - Submit Button Customization

  var submitButtonText: String? { get set }
  var showSubmitLoadingIndicator: Bool { get set }

  // MARK: - Field-Level Customization via InputFieldConfig

  var cardNumberConfig: InputFieldConfig? { get set }
  var expiryDateConfig: InputFieldConfig? { get set }
  var cvvConfig: InputFieldConfig? { get set }
  var cardholderNameConfig: InputFieldConfig? { get set }
  var postalCodeConfig: InputFieldConfig? { get set }
  var countryConfig: InputFieldConfig? { get set }
  var cityConfig: InputFieldConfig? { get set }
  var stateConfig: InputFieldConfig? { get set }
  var addressLine1Config: InputFieldConfig? { get set }
  var addressLine2Config: InputFieldConfig? { get set }
  var phoneNumberConfig: InputFieldConfig? { get set }
  var firstNameConfig: InputFieldConfig? { get set }
  var lastNameConfig: InputFieldConfig? { get set }
  var emailConfig: InputFieldConfig? { get set }
  var retailOutletConfig: InputFieldConfig? { get set }
  var otpCodeConfig: InputFieldConfig? { get set }

  // MARK: - Section-Level Customization

  var cardInputSection: Component? { get set }
  var billingAddressSection: Component? { get set }
  var submitButtonSection: Component? { get set }

  // MARK: - ViewBuilder Methods for SDK Components

  func PrimerCardNumberField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerExpiryDateField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerCvvField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerCardholderNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerCountryField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerPostalCodeField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerCityField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerStateField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerAddressLine1Field(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerAddressLine2Field(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerFirstNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerLastNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerEmailField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerPhoneNumberField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerRetailOutletField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerOtpCodeField(label: String?, styling: PrimerFieldStyling?) -> AnyView

  // MARK: - Validation State Communication

  func updateValidationState(cardNumber: Bool, cvv: Bool, expiry: Bool, cardholderName: Bool)

  // MARK: - Structured State Support

  func updateField(_ fieldType: PrimerInputElementType, value: String)
  func getFieldValue(_ fieldType: PrimerInputElementType) -> String
  func setFieldError(_ fieldType: PrimerInputElementType, message: String, errorCode: String?)
  func clearFieldError(_ fieldType: PrimerInputElementType)
  func getFieldError(_ fieldType: PrimerInputElementType) -> String?
  func getFormConfiguration() -> CardFormConfiguration

  // MARK: - Default Card Form View

  func DefaultCardFormView(styling: PrimerFieldStyling?) -> AnyView

}

// MARK: - Default Implementation for Payment Method Lifecycle

@available(iOS 15.0, *)
extension PrimerCardFormScope {

  public func start() {
    // Override if initialization logic needed
  }

  public func submit() {
    onSubmit()
  }

  public func cancel() {
    onCancel()
  }
}

// MARK: - Structured State Default Implementations

@available(iOS 15.0, *)
extension PrimerCardFormScope {

  public func updateField(_ fieldType: PrimerInputElementType, value: String) {
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

  public func getFieldValue(_ fieldType: PrimerInputElementType) -> String {
    ""
  }

  public func setFieldError(
    _ fieldType: PrimerInputElementType, message: String, errorCode: String? = nil
  ) {
  }

  public func clearFieldError(_ fieldType: PrimerInputElementType) {
  }

  public func getFieldError(_ fieldType: PrimerInputElementType) -> String? {
    nil
  }

  public func getFormConfiguration() -> CardFormConfiguration {
    CardFormConfiguration.default
  }
}

// MARK: - Validation State Update Helper

@available(iOS 15.0, *)
extension PrimerCardFormScope {

  func updateValidationStateIfNeeded(for field: PrimerInputElementType, isValid: Bool) {
    guard let defaultScope = self as? DefaultCardFormScope else { return }

    switch field {
    case .cardNumber:
      defaultScope.updateCardNumberValidationState(isValid)
    case .cvv:
      defaultScope.updateCvvValidationState(isValid)
    case .expiryDate:
      defaultScope.updateExpiryValidationState(isValid)
    case .cardholderName:
      defaultScope.updateCardholderNameValidationState(isValid)
    case .email:
      defaultScope.updateEmailValidationState(isValid)
    case .firstName:
      defaultScope.updateFirstNameValidationState(isValid)
    case .lastName:
      defaultScope.updateLastNameValidationState(isValid)
    case .addressLine1:
      defaultScope.updateAddressLine1ValidationState(isValid)
    case .addressLine2:
      defaultScope.updateAddressLine2ValidationState(isValid)
    case .city:
      defaultScope.updateCityValidationState(isValid)
    case .state:
      defaultScope.updateStateValidationState(isValid)
    case .postalCode:
      defaultScope.updatePostalCodeValidationState(isValid)
    case .countryCode:
      defaultScope.updateCountryCodeValidationState(isValid)
    case .phoneNumber:
      defaultScope.updatePhoneNumberValidationState(isValid)
    case .retailer, .otp, .unknown, .all:
      break  // These fields don't have validation state updates
    }
  }
}

// swiftlint:enable identifier_name
