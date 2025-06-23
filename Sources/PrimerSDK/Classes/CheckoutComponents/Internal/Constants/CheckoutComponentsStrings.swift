//
//  CheckoutComponentsStrings.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Centralized strings for CheckoutComponents to make localization easier
internal struct CheckoutComponentsStrings {
    
    // MARK: - Screen Titles
    
    static let cardPaymentTitle = NSLocalizedString(
        "checkout-components-card-payment-title",
        bundle: Bundle.primerResources,
        value: "Card Payment",
        comment: "Card Payment screen title"
    )
    
    static let billingAddressTitle = NSLocalizedString(
        "checkout-components-billing-address-title", 
        bundle: Bundle.primerResources,
        value: "Billing Address",
        comment: "Billing Address section title"
    )
    
    // MARK: - Buttons
    
    static let payButton = NSLocalizedString(
        "primer-card-form-pay",
        bundle: Bundle.primerResources,
        value: "Pay",
        comment: "Pay button text"
    )
    
    static let tryAgainButton = NSLocalizedString(
        "checkout-components-try-again-button",
        bundle: Bundle.primerResources,
        value: "Try Again", 
        comment: "Try Again button text"
    )
    
    // MARK: - Error Messages
    
    static let somethingWentWrong = NSLocalizedString(
        "primer-error-screen",
        bundle: Bundle.primerResources,
        value: "Something went wrong",
        comment: "Generic error message"
    )
    
    static let unexpectedError = NSLocalizedString(
        "checkout-components-unexpected-error",
        bundle: Bundle.primerResources,
        value: "An unexpected error occurred. Please try again.",
        comment: "Unexpected error message"
    )
    
    // MARK: - Form Labels
    
    static let firstNameLabel = NSLocalizedString(
        "firstNameLabel",
        bundle: Bundle.primerResources,
        value: "First Name",
        comment: "First name field label"
    )
    
    static let lastNameLabel = NSLocalizedString(
        "lastNameLabel", 
        bundle: Bundle.primerResources,
        value: "Last Name",
        comment: "Last name field label"
    )
    
    static let emailLabel = NSLocalizedString(
        "checkout-components-email-label",
        bundle: Bundle.primerResources,
        value: "Email",
        comment: "Email field label"
    )
    
    static let phoneNumberLabel = NSLocalizedString(
        "checkout-components-phone-number-label",
        bundle: Bundle.primerResources,
        value: "Phone Number",
        comment: "Phone number field label"
    )
    
    static let countryLabel = NSLocalizedString(
        "countryCodeLabel",
        bundle: Bundle.primerResources,
        value: "Country",
        comment: "Country field label"
    )
    
    // MARK: - Placeholders
    
    static let firstNamePlaceholder = NSLocalizedString(
        "firstNamePlaceholder",
        bundle: Bundle.primerResources,
        value: "John",
        comment: "First name placeholder"
    )
    
    static let lastNamePlaceholder = NSLocalizedString(
        "lastNamePlaceholder",
        bundle: Bundle.primerResources,
        value: "Doe", 
        comment: "Last name placeholder"
    )
    
    static let emailPlaceholder = NSLocalizedString(
        "checkout-components-email-placeholder",
        bundle: Bundle.primerResources,
        value: "john.doe@example.com",
        comment: "Email placeholder"
    )
    
    static let phoneNumberPlaceholder = NSLocalizedString(
        "checkout-components-phone-placeholder",
        bundle: Bundle.primerResources,
        value: "+1 (555) 123-4567",
        comment: "Phone number placeholder"
    )
    
    static let selectCountryPlaceholder = NSLocalizedString(
        "countrySelectPlaceholder",
        bundle: Bundle.primerResources,
        value: "Select Country",
        comment: "Select country placeholder"
    )
    
    static let addressLine1Placeholder = NSLocalizedString(
        "addressLine1Placeholder",
        bundle: Bundle.primerResources,
        value: "123 Main Street",
        comment: "Address line 1 placeholder"
    )
    
    static let addressLine2Placeholder = NSLocalizedString(
        "addressLine2Placeholder", 
        bundle: Bundle.primerResources,
        value: "Apartment, suite, etc.",
        comment: "Address line 2 placeholder"
    )
    
    static let cityPlaceholder = NSLocalizedString(
        "cityPlaceholder",
        bundle: Bundle.primerResources,
        value: "New York",
        comment: "City placeholder"
    )
    
    static let statePlaceholder = NSLocalizedString(
        "statePlaceholder",
        bundle: Bundle.primerResources,
        value: "NY",
        comment: "State placeholder"
    )
    
    // MARK: - Address Labels
    
    static let addressLine1Label = NSLocalizedString(
        "addressLine1Label",
        bundle: Bundle.primerResources,
        value: "Address Line 1",
        comment: "Address line 1 label"
    )
    
    static let addressLine2Label = NSLocalizedString(
        "addressLine2Label",
        bundle: Bundle.primerResources,
        value: "Address Line 2 (Optional)",
        comment: "Address line 2 label"
    )
    
    static let cityLabel = NSLocalizedString(
        "cityLabel",
        bundle: Bundle.primerResources,
        value: "City",
        comment: "City label"
    )
    
    static let stateLabel = NSLocalizedString(
        "stateLabel",
        bundle: Bundle.primerResources,
        value: "State",
        comment: "State label"
    )
    
    static let postalCodeLabel = NSLocalizedString(
        "postalCodeLabel",
        bundle: Bundle.primerResources,
        value: "Postal Code",
        comment: "Postal code label"
    )
    
    // MARK: - Country Selector
    
    static let countrySelectorPlaceholder = NSLocalizedString(
        "checkout-components-country-selector-placeholder",
        bundle: Bundle.primerResources,
        value: "Country Selector",
        comment: "Country selector placeholder"
    )
}