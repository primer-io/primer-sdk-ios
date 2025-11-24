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

    /// The presentation context determining navigation behavior.
    var presentationContext: PresentationContext { get }

    /// Card form UI options from settings.
    /// Controls pay button text (e.g., "Pay $10.00" vs "Add New Card")
    var cardFormUIOptions: PrimerCardFormUIOptions? { get }

    /// Available dismissal mechanisms (gestures, close button) from settings.
    /// Controls how users can dismiss the checkout modal.
    var dismissalMechanism: [DismissalMechanism] { get }

    // MARK: - Payment Method Lifecycle (PrimerPaymentMethodScope)

    /// Starts the card form flow and initializes the scope.
    /// Default implementation can be empty for card form since it's initialized on presentation.
    func start()

    /// Submits the payment method for processing.
    /// Maps to onSubmit() for consistent API naming.
    func submit()

    /// Cancels the payment method flow and returns to payment method selection.
    /// Maps to onCancel() for consistent API naming.
    func cancel()

    // MARK: - Navigation Methods

    /// Submits the card form for payment processing.
    func onSubmit()

    /// Navigates back to the previous screen.
    func onBack()

    /// Cancels the card form and returns to payment method selection.
    func onCancel()

    /// Navigates to country selection screen for billing address.
    func navigateToCountrySelection()

    // MARK: - Update Methods

    /// Updates the card number field.
    func updateCardNumber(_ cardNumber: String)

    /// Updates the CVV/CVC field.
    func updateCvv(_ cvv: String)

    /// Updates the expiry date field.
    func updateExpiryDate(_ expiryDate: String)

    /// Updates the cardholder name field.
    func updateCardholderName(_ cardholderName: String)

    /// Updates the postal/ZIP code field.
    func updatePostalCode(_ postalCode: String)

    /// Updates the city field.
    func updateCity(_ city: String)

    /// Updates the state/province field.
    func updateState(_ state: String)

    /// Updates the first address line field.
    func updateAddressLine1(_ addressLine1: String)

    /// Updates the second address line field.
    func updateAddressLine2(_ addressLine2: String)

    /// Updates the phone number field.
    func updatePhoneNumber(_ phoneNumber: String)

    /// Updates the first name field.
    func updateFirstName(_ firstName: String)

    /// Updates the last name field.
    func updateLastName(_ lastName: String)

    /// Updates the retail outlet field (region specific).
    func updateRetailOutlet(_ retailOutlet: String)

    /// Updates the OTP code field.
    func updateOtpCode(_ otpCode: String)

    /// Updates the email field.
    func updateEmail(_ email: String)

    /// Updates the expiry month field.
    func updateExpiryMonth(_ month: String)

    /// Updates the expiry year field.
    func updateExpiryYear(_ year: String)

    /// Updates the selected card network field (for co-badged cards).
    func updateSelectedCardNetwork(_ network: String)

    /// Updates the country code field.
    func updateCountryCode(_ countryCode: String)

    // MARK: - Nested Scope

    /// Scope for country selection functionality.
    var selectCountry: PrimerSelectCountryScope { get }

    // MARK: - Screen-Level Customization

    /// The entire card form screen.
    /// When set, overrides the default card form layout completely.
    var screen: ((_ scope: any PrimerCardFormScope) -> any View)? { get set }

    /// Co-badged cards selection view for dual-network cards.
    /// Shown when a card supports multiple networks (e.g., Visa/Mastercard).
    var cobadgedCardsView: ((_ availableNetworks: [String], _ selectNetwork: @escaping (String) -> Void) -> any View)? { get set }

    /// Error message display component.
    /// Default implementation shows error text in red.
    var errorView: ((_ error: String) -> any View)? { get set }

    // MARK: - Field-Level Customization (Partial UI Override)

    /// Custom card number field implementation.
    /// When set, overrides the default card number field.
    var cardNumberField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> any View)? { get set }

    /// Custom expiry date field implementation.
    /// When set, overrides the default expiry date field.
    var expiryDateField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> any View)? { get set }

    /// Custom CVV field implementation.
    /// When set, overrides the default CVV field.
    var cvvField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> any View)? { get set }

    /// Custom cardholder name field implementation.
    /// When set, overrides the default cardholder name field.
    var cardholderNameField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> any View)? { get set }

    /// Custom postal code field implementation.
    /// When set, overrides the default postal code field.
    var postalCodeField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> any View)? { get set }

    /// Custom country field implementation.
    /// When set, overrides the default country field.
    var countryField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> any View)? { get set }

    /// Custom city field implementation.
    /// When set, overrides the default city field.
    var cityField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> any View)? { get set }

    /// Custom state field implementation.
    /// When set, overrides the default state field.
    var stateField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> any View)? { get set }

    /// Custom address line 1 field implementation.
    /// When set, overrides the default address line 1 field.
    var addressLine1Field: ((_ label: String?, _ styling: PrimerFieldStyling?) -> any View)? { get set }

    /// Custom address line 2 field implementation.
    /// When set, overrides the default address line 2 field.
    var addressLine2Field: ((_ label: String?, _ styling: PrimerFieldStyling?) -> any View)? { get set }

    /// Custom phone number field implementation.
    /// When set, overrides the default phone number field.
    var phoneNumberField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> any View)? { get set }

    /// Custom first name field implementation.
    /// When set, overrides the default first name field.
    var firstNameField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> any View)? { get set }

    /// Custom last name field implementation.
    /// When set, overrides the default last name field.
    var lastNameField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> any View)? { get set }

    /// Custom email field implementation.
    /// When set, overrides the default email field.
    var emailField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> any View)? { get set }

    /// Custom retail outlet field implementation.
    /// When set, overrides the default retail outlet field.
    var retailOutletField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> any View)? { get set }

    /// Custom OTP code field implementation.
    /// When set, overrides the default OTP code field.
    var otpCodeField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> any View)? { get set }

    /// Custom submit button implementation.
    /// When set, overrides the default submit button.
    var submitButton: ((_ text: String) -> any View)? { get set }

    // MARK: - Section-Level Customization

    /// Custom card input section (card number, expiry, CVV, cardholder name).
    /// When set, overrides the entire card input section.
    var cardInputSection: (() -> any View)? { get set }

    /// Custom billing address section.
    /// When set, overrides the entire billing address section.
    var billingAddressSection: (() -> any View)? { get set }

    /// Custom submit button section.
    /// When set, overrides the entire submit button section.
    var submitButtonSection: (() -> any View)? { get set }

    // MARK: - Default Styling

    /// Default field styling to be used by CardFormScreen when no override is provided.
    /// Keys are field names: "cardNumber", "expiryDate", "cvv", etc.
    var defaultFieldStyling: [String: PrimerFieldStyling]? { get set }

    // MARK: - Future Features (Vaulting Support)

    // The following features are placeholders for future vaulting functionality.
    // They are commented out to indicate planned support but are not yet implemented.

    // Future features for card vaulting:
    // @ViewBuilder func PrimerSaveCardToggle(isOn: Binding<Bool>) -> any View
    // var savedCardsSelector: (@ViewBuilder (_ savedCards: [SavedCard], _ onSelect: @escaping (SavedCard) -> Void) -> any View)? { get set }
    // func updateSaveCard(_ save: Bool)
    // func selectSavedCard(_ cardId: String)

    // MARK: - ViewBuilder Methods for SDK Components

    /// Returns a Primer card number input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the card number input field.
    func PrimerCardNumberField(label: String?, styling: PrimerFieldStyling?) -> AnyView

    /// Returns a Primer expiry date input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the expiry date input field.
    func PrimerExpiryDateField(label: String?, styling: PrimerFieldStyling?) -> AnyView

    /// Returns a Primer CVV input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the CVV input field.
    func PrimerCvvField(label: String?, styling: PrimerFieldStyling?) -> AnyView

    /// Returns a Primer cardholder name input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the cardholder name input field.
    func PrimerCardholderNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView

    /// Returns a Primer country selection field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the country selection field.
    func PrimerCountryField(label: String?, styling: PrimerFieldStyling?) -> AnyView

    /// Returns a Primer postal code input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the postal code input field.
    func PrimerPostalCodeField(label: String?, styling: PrimerFieldStyling?) -> AnyView

    /// Returns a Primer city input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the city input field.
    func PrimerCityField(label: String?, styling: PrimerFieldStyling?) -> AnyView

    /// Returns a Primer state/province input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the state input field.
    func PrimerStateField(label: String?, styling: PrimerFieldStyling?) -> AnyView

    /// Returns a Primer address line 1 input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the address line 1 input field.
    func PrimerAddressLine1Field(label: String?, styling: PrimerFieldStyling?) -> AnyView

    /// Returns a Primer address line 2 input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the address line 2 input field.
    func PrimerAddressLine2Field(label: String?, styling: PrimerFieldStyling?) -> AnyView

    /// Returns a Primer first name input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the first name input field.
    func PrimerFirstNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView

    /// Returns a Primer last name input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the last name input field.
    func PrimerLastNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView

    /// Returns a Primer email input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the email input field.
    func PrimerEmailField(label: String?, styling: PrimerFieldStyling?) -> AnyView

    /// Returns a Primer phone number input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the phone number input field.
    func PrimerPhoneNumberField(label: String?, styling: PrimerFieldStyling?) -> AnyView

    /// Returns a Primer retail outlet input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the retail outlet input field.
    func PrimerRetailOutletField(label: String?, styling: PrimerFieldStyling?) -> AnyView

    /// Returns a Primer OTP code input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the OTP code input field.
    func PrimerOtpCodeField(label: String?, styling: PrimerFieldStyling?) -> AnyView

    // MARK: - Validation State Communication

    /// Updates the validation state based on field-level validation results.
    /// This method allows the UI components to communicate their validation state
    /// to the scope, ensuring button state synchronization.
    func updateValidationState(cardNumber: Bool, cvv: Bool, expiry: Bool, cardholderName: Bool)

    // MARK: - Structured State Support

    /// Updates field value using the type-safe field type enum
    func updateField(_ fieldType: PrimerInputElementType, value: String)

    /// Gets field value using the type-safe field type enum
    func getFieldValue(_ fieldType: PrimerInputElementType) -> String

    /// Sets field-specific error using structured error approach
    func setFieldError(_ fieldType: PrimerInputElementType, message: String, errorCode: String?)

    /// Clears field-specific error
    func clearFieldError(_ fieldType: PrimerInputElementType)

    /// Gets field-specific error message
    func getFieldError(_ fieldType: PrimerInputElementType) -> String?

    /// Gets the current form configuration (which fields are displayed)
    func getFormConfiguration() -> CardFormConfiguration

}

// MARK: - Default Implementation for Payment Method Lifecycle

@available(iOS 15.0, *)
extension PrimerCardFormScope {

    /// Card form is ready on presentation
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

    /// Update field using type-safe enum
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

    /// Get field value from state - override with actual implementation
    public func getFieldValue(_ fieldType: PrimerInputElementType) -> String {
        ""
    }

    /// Set field error - override to support structured errors
    public func setFieldError(_ fieldType: PrimerInputElementType, message: String, errorCode: String? = nil) {
    }

    /// Clear field error - override to support structured errors
    public func clearFieldError(_ fieldType: PrimerInputElementType) {
    }

    /// Get field error - override to support structured errors
    public func getFieldError(_ fieldType: PrimerInputElementType) -> String? {
        nil
    }

    /// Get form configuration - override with actual configuration
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
