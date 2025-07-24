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
/// This protocol matches the Android Composable API exactly with all 15 update methods.
/// Inherits from PrimerPaymentMethodScope for unified payment method architecture.
@available(iOS 15.0, *)
@MainActor
public protocol PrimerCardFormScope: PrimerPaymentMethodScope where State == PrimerCardFormState {

    /// The current state of the card form as an async stream.
    var state: AsyncStream<PrimerCardFormState> { get }

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

    // MARK: - Update Methods (15 total - exact match to Android)

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

    // MARK: - ViewBuilder Field Functions (18 total - exact match to Android)

    /// The entire card form screen.
    /// Default implementation provides standard card form layout.
    var screen: ((_ scope: any PrimerCardFormScope) -> AnyView)? { get set }

    /// Cardholder name input field with ViewBuilder.
    @ViewBuilder func PrimerCardholderNameField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Card number input field with ViewBuilder.
    @ViewBuilder func PrimerCardNumberField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// CVV/CVC input field with ViewBuilder.
    @ViewBuilder func PrimerCvvField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Expiry date input field with ViewBuilder.
    @ViewBuilder func PrimerExpiryDateField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Postal code input field with ViewBuilder.
    @ViewBuilder func PrimerPostalCodeField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Country selection field with ViewBuilder.
    @ViewBuilder func PrimerCountryField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// City input field with ViewBuilder.
    @ViewBuilder func PrimerCityField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// State/province input field with ViewBuilder.
    @ViewBuilder func PrimerStateField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// First address line input field with ViewBuilder.
    @ViewBuilder func PrimerAddressLine1Field(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Second address line input field with ViewBuilder.
    @ViewBuilder func PrimerAddressLine2Field(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Phone number input field with ViewBuilder.
    @ViewBuilder func PrimerPhoneNumberField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// First name input field with ViewBuilder.
    @ViewBuilder func PrimerFirstNameField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Last name input field with ViewBuilder.
    @ViewBuilder func PrimerLastNameField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Email input field with ViewBuilder.
    @ViewBuilder func PrimerEmailField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Retail outlet input field with ViewBuilder.
    @ViewBuilder func PrimerRetailOutletField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// OTP code input field with ViewBuilder.
    @ViewBuilder func PrimerOtpCodeField(label: String?, styling: PrimerFieldStyling?) -> any View

    /// Submit button with ViewBuilder.
    @ViewBuilder func PrimerSubmitButton(text: String) -> any View

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

    /// Save card toggle for vaulting (Future feature).
    /// When enabled, allows users to save their card for future payments.
    // @ViewBuilder func PrimerSaveCardToggle(isOn: Binding<Bool>) -> any View

    /// Saved cards selector (Future feature).
    /// When enabled, shows previously saved cards for selection.
    // var savedCardsSelector: (@ViewBuilder (_ savedCards: [SavedCard], _ onSelect: @escaping (SavedCard) -> Void) -> any View)? { get set }

    /// Update method for save card preference (Future feature).
    // func updateSaveCard(_ save: Bool)

    /// Select a saved card (Future feature).
    // func selectSavedCard(_ cardId: String)

    // MARK: - Validation State Communication

    /// Updates the validation state based on field-level validation results.
    /// This method allows the UI components to communicate their validation state
    /// to the scope, ensuring button state synchronization.
    func updateValidationState(cardNumber: Bool, cvv: Bool, expiry: Bool, cardholderName: Bool)

}

// MARK: - State Definition

/// Represents the current state of all form fields and submission status for PrimerCardFormScope.
@available(iOS 15.0, *)
public struct PrimerCardFormState: Equatable {
    public var cardNumber: String = ""
    public var cvv: String = ""
    public var expiryDate: String = ""
    public var cardholderName: String = ""
    public var postalCode: String = ""
    public var countryCode: String = ""
    public var city: String = ""
    public var state: String = ""
    public var addressLine1: String = ""
    public var addressLine2: String = ""
    public var phoneNumber: String = ""
    public var firstName: String = ""
    public var lastName: String = ""
    public var retailOutlet: String = ""
    public var otpCode: String = ""
    public var email: String = ""
    public var isSubmitting: Bool = false
    public var isValid: Bool = false
    public var error: String?
    public var expiryMonth: String = ""
    public var expiryYear: String = ""
    public var selectedCardNetwork: String?
    public var availableCardNetworks: [String] = []
    public var surchargeAmount: String?

    public init(
        cardNumber: String = "",
        cvv: String = "",
        expiryDate: String = "",
        cardholderName: String = "",
        postalCode: String = "",
        countryCode: String = "",
        city: String = "",
        state: String = "",
        addressLine1: String = "",
        addressLine2: String = "",
        phoneNumber: String = "",
        firstName: String = "",
        lastName: String = "",
        retailOutlet: String = "",
        otpCode: String = "",
        email: String = "",
        isSubmitting: Bool = false,
        isValid: Bool = false,
        error: String? = nil,
        expiryMonth: String = "",
        expiryYear: String = "",
        selectedCardNetwork: String? = nil,
        availableCardNetworks: [String] = [],
        surchargeAmount: String? = nil
    ) {
        self.cardNumber = cardNumber
        self.cvv = cvv
        self.expiryDate = expiryDate
        self.cardholderName = cardholderName
        self.postalCode = postalCode
        self.countryCode = countryCode
        self.city = city
        self.state = state
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2
        self.phoneNumber = phoneNumber
        self.firstName = firstName
        self.lastName = lastName
        self.retailOutlet = retailOutlet
        self.otpCode = otpCode
        self.email = email
        self.isSubmitting = isSubmitting
        self.isValid = isValid
        self.error = error
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.selectedCardNetwork = selectedCardNetwork
        self.availableCardNetworks = availableCardNetworks
        self.surchargeAmount = surchargeAmount
    }
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

// swiftlint:enable identifier_name
