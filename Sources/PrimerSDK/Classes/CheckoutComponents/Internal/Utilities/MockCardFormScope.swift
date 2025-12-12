//
//  MockCardFormScope.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable all
#if DEBUG
import SwiftUI

/// Mock implementation of PrimerCardFormScope for SwiftUI previews
/// Provides configurable behavior and debug logging to help test different UI states
@available(iOS 15.0, *)
public class MockCardFormScope: PrimerCardFormScope {

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

    public var state: AsyncStream<StructuredCardFormState> {
        AsyncStream { continuation in
            continuation.yield(StructuredCardFormState(
                data: FormData(),
                isLoading: self.initialIsLoading,
                isValid: self.initialIsValid,
                selectedNetwork: self.initialSelectedNetwork.map { PrimerCardNetwork(network: $0) },
                availableNetworks: self.initialAvailableNetworks.map { PrimerCardNetwork(network: $0) },
                surchargeAmount: self.initialSurchargeAmount
            ))
        }
    }

    // MARK: - Screen-Level Customization

    public var title: String?
    public var screen: ((any PrimerCardFormScope) -> any View)?
    public var cobadgedCardsView: (([String], @escaping (String) -> Void) -> any View)?
    public var errorView: ((String) -> any View)?

    // MARK: - Submit Button Customization

    public var submitButtonText: String?
    public var showSubmitLoadingIndicator: Bool = true

    // MARK: - Field-Level Customization via InputFieldConfig

    public var cardNumberConfig: InputFieldConfig?
    public var expiryDateConfig: InputFieldConfig?
    public var cvvConfig: InputFieldConfig?
    public var cardholderNameConfig: InputFieldConfig?
    public var postalCodeConfig: InputFieldConfig?
    public var countryConfig: InputFieldConfig?
    public var cityConfig: InputFieldConfig?
    public var stateConfig: InputFieldConfig?
    public var addressLine1Config: InputFieldConfig?
    public var addressLine2Config: InputFieldConfig?
    public var phoneNumberConfig: InputFieldConfig?
    public var firstNameConfig: InputFieldConfig?
    public var lastNameConfig: InputFieldConfig?
    public var emailConfig: InputFieldConfig?
    public var retailOutletConfig: InputFieldConfig?
    public var otpCodeConfig: InputFieldConfig?

    // MARK: - Section-Level Customization

    public var cardInputSection: Component?
    public var billingAddressSection: Component?
    public var submitButtonSection: Component?

    public var selectCountry: PrimerSelectCountryScope {
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
        self.initialIsLoading = isLoading
        self.initialIsValid = isValid
        self.initialSelectedNetwork = selectedNetwork
        self.initialAvailableNetworks = availableNetworks
        self.initialSurchargeAmount = surchargeAmount
        self.presentationContext = presentationContext
        self.configuration = formConfiguration
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

    public func onSubmit() {
        log("onSubmit() called")
    }

    public func onBack() {
        log("onBack() called")
    }

    public func onCancel() {
        log("onCancel() called")
    }

    public func onDismiss() {
        log("onDismiss() called")
    }

    public func navigateToCountrySelection() {
        log("navigateToCountrySelection() called")
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

    public func updateCountryCode(_ countryCode: String) {
        log("updateCountryCode: \(countryCode)")
    }

    public func updateValidationState(cardNumber: Bool, cvv: Bool, expiry: Bool, cardholderName: Bool) {
        log("updateValidationState - cardNumber: \(cardNumber), cvv: \(cvv), expiry: \(expiry), cardholderName: \(cardholderName)")
    }

    // MARK: - Structured State Support

    public func updateField(_ fieldType: PrimerInputElementType, value: String) {
        log("updateField(\(fieldType)): \(value)")
    }

    public func getFieldValue(_ fieldType: PrimerInputElementType) -> String {
        log("getFieldValue(\(fieldType))")
        return ""
    }

    public func setFieldError(_ fieldType: PrimerInputElementType, message: String, errorCode: String?) {
        log("setFieldError(\(fieldType)): \(message) [code: \(errorCode ?? "nil")]")
    }

    public func clearFieldError(_ fieldType: PrimerInputElementType) {
        log("clearFieldError(\(fieldType))")
    }

    public func getFieldError(_ fieldType: PrimerInputElementType) -> String? {
        log("getFieldError(\(fieldType))")
        return nil
    }

    // MARK: - ViewBuilder Methods

    public func PrimerCardNumberField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
        AnyView(EmptyView())
    }

    public func PrimerExpiryDateField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
        AnyView(EmptyView())
    }

    public func PrimerCvvField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
        AnyView(EmptyView())
    }

    public func PrimerCardholderNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
        AnyView(EmptyView())
    }

    public func PrimerCountryField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
        AnyView(EmptyView())
    }

    public func PrimerPostalCodeField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
        AnyView(EmptyView())
    }

    public func PrimerCityField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
        AnyView(EmptyView())
    }

    public func PrimerStateField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
        AnyView(EmptyView())
    }

    public func PrimerAddressLine1Field(label: String?, styling: PrimerFieldStyling?) -> AnyView {
        AnyView(EmptyView())
    }

    public func PrimerAddressLine2Field(label: String?, styling: PrimerFieldStyling?) -> AnyView {
        AnyView(EmptyView())
    }

    public func PrimerFirstNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
        AnyView(EmptyView())
    }

    public func PrimerLastNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
        AnyView(EmptyView())
    }

    public func PrimerEmailField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
        AnyView(EmptyView())
    }

    public func PrimerPhoneNumberField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
        AnyView(EmptyView())
    }

    public func PrimerRetailOutletField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
        AnyView(EmptyView())
    }

    public func PrimerOtpCodeField(label: String?, styling: PrimerFieldStyling?) -> AnyView {
        AnyView(EmptyView())
    }

    public func DefaultCardFormView(styling: PrimerFieldStyling?) -> AnyView {
        AnyView(EmptyView())
    }

    // MARK: - Form Configuration

    public func getFormConfiguration() -> CardFormConfiguration {
        log("getFormConfiguration() -> \(configuration)")
        return configuration
    }
}

#endif // DEBUG
// swiftlint:enable all
