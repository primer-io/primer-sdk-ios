//
//  PrimerCardFormScope.swift
//  PrimerSDK
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Scope interface for card form interactions, state management, and UI customization.
/// This protocol matches the Android Composable API exactly with all 15 update methods.
@MainActor
public protocol PrimerCardFormScope: AnyObject {
    
    /// The current state of the card form as an async stream.
    var state: AsyncStream<State> { get }
    
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
    
    // MARK: - Nested Scope
    
    /// Scope for country selection functionality.
    var selectCountry: PrimerSelectCountryScope { get }
    
    // MARK: - Customizable UI Components (18 total - exact match to Android)
    
    /// The entire card form screen.
    /// Default implementation provides standard card form layout.
    var screen: (@ViewBuilder (_ scope: PrimerCardFormScope) -> any View)? { get set }
    
    /// Submit button component.
    var submitButton: (@ViewBuilder (_ modifier: PrimerModifier, _ text: String) -> any View)? { get set }
    
    /// Card number input field.
    var cardNumberInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
    
    /// CVV/CVC input field.
    var cvvInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
    
    /// Expiry date input field.
    var expiryDateInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
    
    /// Cardholder name input field.
    var cardholderNameInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
    
    /// Postal code input field.
    var postalCodeInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
    
    /// Country code input field with selection.
    var countryCodeInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
    
    /// City input field.
    var cityInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
    
    /// State/province input field.
    var stateInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
    
    /// First address line input field.
    var addressLine1Input: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
    
    /// Second address line input field.
    var addressLine2Input: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
    
    /// Phone number input field.
    var phoneNumberInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
    
    /// First name input field.
    var firstNameInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
    
    /// Last name input field.
    var lastNameInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
    
    /// Retail outlet input field (region specific).
    var retailOutletInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
    
    /// OTP code input field.
    var otpCodeInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
    
    /// Composite component for card details section.
    var cardDetails: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
    
    /// Composite component for billing address section.
    var billingAddress: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
    
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
    
    // MARK: - State Definition
    
    /// Represents the current state of all form fields and submission status.
    struct State: Equatable {
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
            isSubmitting: Bool = false
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
        }
    }
}