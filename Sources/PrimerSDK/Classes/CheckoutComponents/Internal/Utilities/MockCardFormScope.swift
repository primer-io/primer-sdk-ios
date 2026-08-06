//
//  MockCardFormScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable all
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

#if DEBUG
  import SwiftUI

  /// Mock implementation of PrimerCardFormScope for SwiftUI previews
  /// Provides configurable behavior and debug logging to help test different UI states
  @available(iOS 15.0, *)
  final class MockCardFormScope: CardFormFieldScopeInternal {

    // MARK: - Configuration Properties

    private let initialIsLoading: Bool
    private let initialIsValid: Bool
    private let initialSelectedNetwork: CardNetwork?
    private let initialAvailableNetworks: [CardNetwork]
    private let initialSurchargeAmount: String?
    private let configuration: CardFormConfiguration
    private let enableLogging: Bool

    // MARK: - Protocol Properties

    public var presentationContext: PresentationContext

    public var cardFormUIOptions: PrimerCardFormUIOptions?

    public var dismissalMechanism: [DismissalMechanism]

    public var state: AsyncStream<PrimerCardFormState> {
      AsyncStream { continuation in
        continuation.yield(
          PrimerCardFormState(
            data: FormData(),
            isLoading: self.initialIsLoading,
            isValid: self.initialIsValid,
            selectedNetwork: self.initialSelectedNetwork.map { PrimerCardNetwork(network: $0) },
            availableNetworks: self.initialAvailableNetworks.map { PrimerCardNetwork(network: $0) },
            surchargeAmount: self.initialSurchargeAmount
          ))
      }
    }

    var selectCountry: PrimerSelectCountryScope {
      fatalError("Not implemented for preview")
    }

    // MARK: - Initialization

    /// Creates a mock card form scope for SwiftUI previews
    /// - Parameters:
    ///   - isLoading: Initial loading state
    ///   - isValid: Initial validation state
    ///   - selectedNetwork: Initially selected card network
    ///   - availableNetworks: Available card networks for selection
    ///   - surchargeAmount: Formatted surcharge amount string (e.g., "+ 1.50€")
    ///   - presentationContext: Context for how the form is presented
    ///   - formConfiguration: Configuration defining which fields to show
    ///   - cardFormUIOptions: UI options for the card form
    ///   - dismissalMechanism: Available dismissal mechanisms
    ///   - enableLogging: Whether to print debug logs for method calls
    public init(
      isLoading: Bool = false,
      isValid: Bool = false,
      selectedNetwork: CardNetwork? = nil,
      availableNetworks: [CardNetwork] = [],
      surchargeAmount: String? = nil,
      presentationContext: PresentationContext = .fromPaymentSelection,
      formConfiguration: CardFormConfiguration = .default,
      cardFormUIOptions: PrimerCardFormUIOptions? = nil,
      dismissalMechanism: [DismissalMechanism] = [],
      enableLogging: Bool = true
    ) {
      initialIsLoading = isLoading
      initialIsValid = isValid
      initialSelectedNetwork = selectedNetwork
      initialAvailableNetworks = availableNetworks
      initialSurchargeAmount = surchargeAmount
      self.presentationContext = presentationContext
      configuration = formConfiguration
      self.cardFormUIOptions = cardFormUIOptions
      self.dismissalMechanism = dismissalMechanism
      self.enableLogging = enableLogging
    }

    // MARK: - Logging Helper

    private func log(_ message: String) {
      if enableLogging {
        print("🎭 [MockCardFormScope] \(message)")
      }
    }

    // MARK: - Lifecycle Methods

    public func start() {
      log("start() called")
    }

    public func submit() {
      log("submit() called")
    }

    public func cancel() {
      log("cancel() called")
    }

    // MARK: - Navigation Methods

    public func onBack() {
      log("onBack() called")
    }

    public func onDismiss() {
      log("onDismiss() called")
    }

    // MARK: - Update Methods

    public func updateCardNumber(_ cardNumber: String) {
      log("updateCardNumber: \(cardNumber)")
    }

    public func updateCvv(_ cvv: String) {
      log("updateCvv: \(cvv)")
    }

    public func updateExpiryDate(_ expiryDate: String) {
      log("updateExpiryDate: \(expiryDate)")
    }

    public func updateCardholderName(_ cardholderName: String) {
      log("updateCardholderName: \(cardholderName)")
    }

    public func updatePostalCode(_ postalCode: String) {
      log("updatePostalCode: \(postalCode)")
    }

    public func updateCity(_ city: String) {
      log("updateCity: \(city)")
    }

    public func updateState(_ state: String) {
      log("updateState: \(state)")
    }

    public func updateAddressLine1(_ addressLine1: String) {
      log("updateAddressLine1: \(addressLine1)")
    }

    public func updateAddressLine2(_ addressLine2: String) {
      log("updateAddressLine2: \(addressLine2)")
    }

    public func updatePhoneNumber(_ phoneNumber: String) {
      log("updatePhoneNumber: \(phoneNumber)")
    }

    public func updateFirstName(_ firstName: String) {
      log("updateFirstName: \(firstName)")
    }

    public func updateLastName(_ lastName: String) {
      log("updateLastName: \(lastName)")
    }

    public func updateRetailOutlet(_ retailOutlet: String) {
      log("updateRetailOutlet: \(retailOutlet)")
    }

    public func updateOtpCode(_ otpCode: String) {
      log("updateOtpCode: \(otpCode)")
    }

    public func updateEmail(_ email: String) {
      log("updateEmail: \(email)")
    }

    public func updateExpiryMonth(_ month: String) {
      log("updateExpiryMonth: \(month)")
    }

    public func updateExpiryYear(_ year: String) {
      log("updateExpiryYear: \(year)")
    }

    public func updateSelectedCardNetwork(_ network: String) {
      log("updateSelectedCardNetwork: \(network)")
    }

    func autoSelectDetectedNetwork(_ network: String) {
      log("autoSelectDetectedNetwork: \(network)")
    }

    public func updateCountryCode(_ countryCode: String) {
      log("updateCountryCode: \(countryCode)")
    }

    func updateValidationState(_ keyPath: WritableKeyPath<FieldValidationStates, Bool>, isValid: Bool) {
      log("updateValidationState keyPath: \(keyPath), isValid: \(isValid)")
    }

    func updateValidationStateIfNeeded(for field: PrimerInputElementType, isValid: Bool) {
      log("updateValidationStateIfNeeded field: \(field), isValid: \(isValid)")
    }

    public var currentState: PrimerCardFormState {
      PrimerCardFormState(
        data: FormData(),
        isLoading: initialIsLoading,
        isValid: initialIsValid,
        selectedNetwork: initialSelectedNetwork.map { PrimerCardNetwork(network: $0) },
        availableNetworks: initialAvailableNetworks.map { PrimerCardNetwork(network: $0) },
        surchargeAmount: initialSurchargeAmount
      )
    }

    public func performSubmit() async {
      log("performSubmit() called")
    }

    // MARK: - Structured State Support

    public func updateField(_ fieldType: PrimerInputElementType, value: String) {
      log("updateField(\(fieldType)): \(value)")
    }

    public func getFieldValue(_ fieldType: PrimerInputElementType) -> String {
      log("getFieldValue(\(fieldType))")
      return ""
    }

    public func setFieldError(
      _ fieldType: PrimerInputElementType, message: String, errorCode: String?
    ) {
      log("setFieldError(\(fieldType)): \(message) [code: \(errorCode ?? "nil")]")
    }

    public func clearFieldError(_ fieldType: PrimerInputElementType) {
      log("clearFieldError(\(fieldType))")
    }

    public func getFieldError(_ fieldType: PrimerInputElementType) -> String? {
      log("getFieldError(\(fieldType))")
      return nil
    }

    // MARK: - Form Configuration

    public func getFormConfiguration() -> CardFormConfiguration {
      log("getFormConfiguration() -> \(configuration)")
      return configuration
    }
  }

#endif  // DEBUG
// swiftlint:enable all
