//
//  PrimerCardFormScope.swift
//  PrimerSDK
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import UIKit

/// Scope interface for card form interactions, state management, and UI customization.
/// This protocol matches the Android Composable API exactly with all 15 update methods.
@available(iOS 15.0, *)
@MainActor
public protocol PrimerCardFormScope: AnyObject {

    /// The current state of the card form as an async stream.
    var state: AsyncStream<PrimerCardFormState> { get }

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

    // MARK: - Customizable UI Components (18 total - exact match to Android)

    /// The entire card form screen.
    /// Default implementation provides standard card form layout.
    var screen: ((_ scope: PrimerCardFormScope) -> AnyView)? { get set }

    /// Submit button component.
    var submitButton: ((_ modifier: PrimerModifier, _ text: String) -> AnyView)? { get set }

    /// Card number input field.
    var cardNumberInput: ((_ modifier: PrimerModifier) -> AnyView)? { get set }

    /// CVV/CVC input field.
    var cvvInput: ((_ modifier: PrimerModifier) -> AnyView)? { get set }

    /// Expiry date input field.
    var expiryDateInput: ((_ modifier: PrimerModifier) -> AnyView)? { get set }

    /// Cardholder name input field.
    var cardholderNameInput: ((_ modifier: PrimerModifier) -> AnyView)? { get set }

    /// Postal code input field.
    var postalCodeInput: ((_ modifier: PrimerModifier) -> AnyView)? { get set }

    /// Country code input field with selection.
    var countryCodeInput: ((_ modifier: PrimerModifier) -> AnyView)? { get set }

    /// City input field.
    var cityInput: ((_ modifier: PrimerModifier) -> AnyView)? { get set }

    /// State/province input field.
    var stateInput: ((_ modifier: PrimerModifier) -> AnyView)? { get set }

    /// First address line input field.
    var addressLine1Input: ((_ modifier: PrimerModifier) -> AnyView)? { get set }

    /// Second address line input field.
    var addressLine2Input: ((_ modifier: PrimerModifier) -> AnyView)? { get set }

    /// Phone number input field.
    var phoneNumberInput: ((_ modifier: PrimerModifier) -> AnyView)? { get set }

    /// First name input field.
    var firstNameInput: ((_ modifier: PrimerModifier) -> AnyView)? { get set }

    /// Last name input field.
    var lastNameInput: ((_ modifier: PrimerModifier) -> AnyView)? { get set }

    /// Retail outlet input field (region specific).
    var retailOutletInput: ((_ modifier: PrimerModifier) -> AnyView)? { get set }

    /// OTP code input field.
    var otpCodeInput: ((_ modifier: PrimerModifier) -> AnyView)? { get set }

    /// Composite component for card details section.
    var cardDetails: ((_ modifier: PrimerModifier) -> AnyView)? { get set }

    /// Composite component for billing address section.
    var billingAddress: ((_ modifier: PrimerModifier) -> AnyView)? { get set }

    /// Co-badged cards selection view for dual-network cards.
    /// Shown when a card supports multiple networks (e.g., Visa/Mastercard).
    var cobadgedCardsView: ((_ availableNetworks: [String], _ selectNetwork: @escaping (String) -> Void) -> AnyView)? { get set }

    /// Error message display component.
    /// Default implementation shows error text in red.
    var errorView: ((_ error: String) -> AnyView)? { get set }

    // MARK: - Future Features (Vaulting Support)

    // The following features are placeholders for future vaulting functionality.
    // They are commented out to indicate planned support but are not yet implemented.

    /// Save card toggle for vaulting (Future feature).
    /// When enabled, allows users to save their card for future payments.
    // var saveCardToggle: (@ViewBuilder (_ isOn: Binding<Bool>, _ modifier: PrimerModifier) -> any View)? { get set }

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
