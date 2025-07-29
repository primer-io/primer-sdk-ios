//
//  PrimerCardFormScope.swift
//  PrimerSDK
//
//  Created by Boris on 23.6.25.
//
// swiftlint:disable identifier_name

import SwiftUI
import UIKit

/// Scope interface for card form interactions, state management, and UI customization.
/// Inherits from PrimerPaymentMethodScope for unified payment method architecture.
@available(iOS 15.0, *)
@MainActor
public protocol PrimerCardFormScope: PrimerPaymentMethodScope where State == StructuredCardFormState {

    /// The current state of the card form as an async stream.
    var state: AsyncStream<StructuredCardFormState> { get }

    /// The presentation context determining navigation behavior.
    var presentationContext: PresentationContext { get }

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
    var screen: ((_ scope: any PrimerCardFormScope) -> AnyView)? { get set }

    /// Co-badged cards selection view for dual-network cards.
    /// Shown when a card supports multiple networks (e.g., Visa/Mastercard).
    var cobadgedCardsView: ((_ availableNetworks: [String], _ selectNetwork: @escaping (String) -> Void) -> AnyView)? { get set }

    /// Error message display component.
    /// Default implementation shows error text in red.
    var errorView: ((_ error: String) -> AnyView)? { get set }

    // MARK: - Field-Level Customization (Partial UI Override)

    /// Custom card number field implementation.
    /// When set, overrides the default card number field.
    var cardNumberField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)? { get set }

    /// Custom expiry date field implementation.
    /// When set, overrides the default expiry date field.
    var expiryDateField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)? { get set }

    /// Custom CVV field implementation.
    /// When set, overrides the default CVV field.
    var cvvField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)? { get set }

    /// Custom cardholder name field implementation.
    /// When set, overrides the default cardholder name field.
    var cardholderNameField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)? { get set }

    /// Custom postal code field implementation.
    /// When set, overrides the default postal code field.
    var postalCodeField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)? { get set }

    /// Custom country field implementation.
    /// When set, overrides the default country field.
    var countryField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)? { get set }

    /// Custom city field implementation.
    /// When set, overrides the default city field.
    var cityField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)? { get set }

    /// Custom state field implementation.
    /// When set, overrides the default state field.
    var stateField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)? { get set }

    /// Custom address line 1 field implementation.
    /// When set, overrides the default address line 1 field.
    var addressLine1Field: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)? { get set }

    /// Custom address line 2 field implementation.
    /// When set, overrides the default address line 2 field.
    var addressLine2Field: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)? { get set }

    /// Custom phone number field implementation.
    /// When set, overrides the default phone number field.
    var phoneNumberField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)? { get set }

    /// Custom first name field implementation.
    /// When set, overrides the default first name field.
    var firstNameField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)? { get set }

    /// Custom last name field implementation.
    /// When set, overrides the default last name field.
    var lastNameField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)? { get set }

    /// Custom email field implementation.
    /// When set, overrides the default email field.
    var emailField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)? { get set }

    /// Custom retail outlet field implementation.
    /// When set, overrides the default retail outlet field.
    var retailOutletField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)? { get set }

    /// Custom OTP code field implementation.
    /// When set, overrides the default OTP code field.
    var otpCodeField: ((_ label: String?, _ styling: PrimerFieldStyling?) -> AnyView)? { get set }

    /// Custom submit button implementation.
    /// When set, overrides the default submit button.
    var submitButton: ((_ text: String) -> AnyView)? { get set }

    // MARK: - Section-Level Customization

    /// Custom card input section (card number, expiry, CVV, cardholder name).
    /// When set, overrides the entire card input section.
    var cardInputSection: (() -> AnyView)? { get set }

    /// Custom billing address section.
    /// When set, overrides the entire billing address section.
    var billingAddressSection: (() -> AnyView)? { get set }

    /// Custom submit button section.
    /// When set, overrides the entire submit button section.
    var submitButtonSection: (() -> AnyView)? { get set }

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
    @ViewBuilder func PrimerCardNumberField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Returns a Primer expiry date input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the expiry date input field.
    @ViewBuilder func PrimerExpiryDateField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Returns a Primer CVV input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the CVV input field.
    @ViewBuilder func PrimerCvvField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Returns a Primer cardholder name input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the cardholder name input field.
    @ViewBuilder func PrimerCardholderNameField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Returns a Primer country selection field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the country selection field.
    @ViewBuilder func PrimerCountryField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Returns a Primer postal code input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the postal code input field.
    @ViewBuilder func PrimerPostalCodeField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Returns a Primer city input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the city input field.
    @ViewBuilder func PrimerCityField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Returns a Primer state/province input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the state input field.
    @ViewBuilder func PrimerStateField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Returns a Primer address line 1 input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the address line 1 input field.
    @ViewBuilder func PrimerAddressLine1Field(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Returns a Primer address line 2 input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the address line 2 input field.
    @ViewBuilder func PrimerAddressLine2Field(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Returns a Primer first name input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the first name input field.
    @ViewBuilder func PrimerFirstNameField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Returns a Primer last name input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the last name input field.
    @ViewBuilder func PrimerLastNameField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Returns a Primer email input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the email input field.
    @ViewBuilder func PrimerEmailField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Returns a Primer phone number input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the phone number input field.
    @ViewBuilder func PrimerPhoneNumberField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Returns a Primer retail outlet input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the retail outlet input field.
    @ViewBuilder func PrimerRetailOutletField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Returns a Primer OTP code input field component that can be customized with SwiftUI modifiers.
    /// - Parameters:
    ///   - label: Optional label text for the field. If not specified, a default label will be used.
    ///   - styling: Optional styling configuration for the field.
    /// - Returns: A view representing the OTP code input field.
    @ViewBuilder func PrimerOtpCodeField(label: String?, styling: PrimerFieldStyling?) -> any View

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

    /// Default implementation for start() - card form is ready on presentation
    public func start() {
        // Card form doesn't need explicit start as it's initialized when presented
        // This can be overridden by implementations if needed
    }

    /// Default implementation maps to existing onSubmit() method
    public func submit() {
        onSubmit()
    }

    /// Default implementation maps to existing onCancel() method
    public func cancel() {
        onCancel()
    }
}

// MARK: - Structured State Default Implementations

@available(iOS 15.0, *)
extension PrimerCardFormScope {

    /// Default implementation for updateField using type-safe enum
    public func updateField(_ fieldType: PrimerInputElementType, value: String) {
        // Map to individual update methods
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

    /// Default implementation for getFieldValue using current state
    /// Implementations should override this to use their actual state
    public func getFieldValue(_ fieldType: PrimerInputElementType) -> String {
        // This is a placeholder - implementations should override with their actual state
        return ""
    }

    /// Default implementation for setFieldError
    /// Implementations should override this to support structured errors
    public func setFieldError(_ fieldType: PrimerInputElementType, message: String, errorCode: String? = nil) {
        // Default implementation does nothing - implementations should override
    }

    /// Default implementation for clearFieldError
    /// Implementations should override this to support structured errors
    public func clearFieldError(_ fieldType: PrimerInputElementType) {
        // Default implementation does nothing - implementations should override
    }

    /// Default implementation for getFieldError
    /// Implementations should override this to support structured errors
    public func getFieldError(_ fieldType: PrimerInputElementType) -> String? {
        // Default implementation returns nil - implementations should override
        return nil
    }

    /// Default implementation for getFormConfiguration
    /// Implementations should override this to return their actual configuration
    public func getFormConfiguration() -> CardFormConfiguration {
        // Default basic card form configuration
        return CardFormConfiguration.default
    }
}

// swiftlint:enable identifier_name
