//
//  PrimerCardFormScope.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

//
//  PrimerCardFormScope.swift
//  PrimerSDK
//
//  Created by Boris on 23.6.25.
//
// swiftlint:disable identifier_name

import SwiftUI

/// Scope interface for card form interactions, state management, and UI customization.
/// Inherits from PrimerPaymentMethodScope for unified payment method architecture.
@available(iOS 15.0, *)
@MainActor
public protocol PrimerCardFormScope: PrimerPaymentMethodScope where State == StructuredCardFormState {

    /// The current state of the card form as an async stream.
    var state: AsyncStream<StructuredCardFormState> { get }

    var presentationContext: PresentationContext { get }

    /// Controls pay button text (e.g., "Pay $10.00" vs "Add New Card")
    var cardFormUIOptions: PrimerCardFormUIOptions? { get }

    /// Controls how users can dismiss the checkout modal.
    var dismissalMechanism: [DismissalMechanism] { get }

    // MARK: - Payment Method Lifecycle (PrimerPaymentMethodScope)

    /// Default implementation can be empty for card form since it's initialized on presentation.
    func start()

    /// Maps to onSubmit() for consistent API naming.
    func submit()

    /// Maps to onCancel() for consistent API naming.
    func cancel()

    // MARK: - Navigation Methods

    func onSubmit()
    func onBack()
    func onCancel()
    func navigateToCountrySelection()

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
    /// Region-specific field.
    func updateRetailOutlet(_ retailOutlet: String)
    func updateOtpCode(_ otpCode: String)
    func updateEmail(_ email: String)
    func updateExpiryMonth(_ month: String)
    func updateExpiryYear(_ year: String)
    /// For co-badged cards with multiple networks.
    func updateSelectedCardNetwork(_ network: String)
    func updateCountryCode(_ countryCode: String)

    // MARK: - Nested Scope

    var selectCountry: PrimerSelectCountryScope { get }

    // MARK: - Screen-Level Customization

    /// When set, overrides the default card form layout completely.
    /// The closure receives the scope for full access to form state, validation, and submit actions.
    var screen: ((_ scope: any PrimerCardFormScope) -> any View)? { get set }

    /// Co-badged cards selection view for dual-network cards.
    /// Shown when a card supports multiple networks (e.g., Visa/Mastercard).
    var cobadgedCardsView: ((_ availableNetworks: [String], _ selectNetwork: @escaping (String) -> Void) -> any View)? { get set }

    /// Default implementation shows error text in red.
    var errorView: ((_ error: String) -> any View)? { get set }

    // MARK: - Future Features (Vaulting Support)

    // The following features are placeholders for future vaulting functionality.
    // They are commented out to indicate planned support but are not yet implemented.

    // Future features for card vaulting:
    // @ViewBuilder func PrimerSaveCardToggle(isOn: Binding<Bool>) -> any View
    // var savedCardsSelector: (@ViewBuilder (_ savedCards: [SavedCard], _ onSelect: @escaping (SavedCard) -> Void) -> any View)? { get set }
    // func updateSaveCard(_ save: Bool)
    // func selectSavedCard(_ cardId: String)

    // MARK: - ViewBuilder Methods for SDK Components
    // These methods return SDK input field components customizable with SwiftUI modifiers.
    // Parameters: label (optional, uses default if nil), styling (optional PrimerFieldStyling).

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

    /// Allows UI components to communicate their validation state to the scope.
    func updateValidationState(cardNumber: Bool, cvv: Bool, expiry: Bool, cardholderName: Bool)

    // MARK: - Structured State Support

    func updateField(_ fieldType: PrimerInputElementType, value: String)
    func getFieldValue(_ fieldType: PrimerInputElementType) -> String
    func setFieldError(_ fieldType: PrimerInputElementType, message: String, errorCode: String?)
    func clearFieldError(_ fieldType: PrimerInputElementType)

    func getFieldError(_ fieldType: PrimerInputElementType) -> String?
    func getFormConfiguration() -> CardFormConfiguration

    // MARK: - Default Card Form View

    /// Returns the default card input form view with all card fields (card number, expiry, CVV, cardholder name).
    /// This can be embedded in custom layouts while retaining the SDK's default field arrangement.
    /// The view does not include navigation buttons or submit button - only the input fields.
    /// - Parameter styling: Optional styling to apply to all fields. If nil, default styling is used.
    /// - Returns: A view containing the default card form fields.
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
            break // Not implemented for these special cases
        }
    }

    public func getFieldValue(_ fieldType: PrimerInputElementType) -> String {
        ""
    }

    public func setFieldError(_ fieldType: PrimerInputElementType, message: String, errorCode: String? = nil) {
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

    /// Safely updates validation state if the scope is a DefaultCardFormScope.
    /// This helper method eliminates the need for repeated conditional casting throughout input field coordinators.
    /// - Parameters:
    ///   - field: The input element type to update
    ///   - isValid: The validation state to set
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
            break // These fields don't have validation state updates
        }
    }
}

// swiftlint:enable identifier_name
