//
//  InputLocalizable.swift
//
//
//  Created on 18.06.2025.
//

import Foundation

@available(iOS 15.0, *)
public enum InputLocalizable {
    // MARK: - Card Fields
    static let cardNumberLabel = "Card Number"
    static let cardNumberPlaceholder = "1234 5678 9012 3456"

    static let cvvLabel = "CVV"
    static let cvvPlaceholder = "123"

    static let expiryDateLabel = "Expiry Date"
    static let expiryDatePlaceholder = "MM/YY"

    static let cardholderNameLabel = "Cardholder Name"
    static let cardholderNamePlaceholder = "John Doe"

    // MARK: - Address Fields
    static let postalCodeLabel = "Postal Code"
    static let postalCodePlaceholder = "12345"

    static let countryCodeLabel = "Country Code"
    static let countryCodePlaceholder = "US"

    static let cityLabel = "City"
    static let cityPlaceholder = "New York"

    static let stateLabel = "State"
    static let statePlaceholder = "NY"

    static let addressLine1Label = "Address Line 1"
    static let addressLine1Placeholder = "123 Main Street"

    static let addressLine2Label = "Address Line 2"
    static let addressLine2Placeholder = "Apt 4B"

    // MARK: - Personal Information
    static let phoneNumberLabel = "Phone Number"
    static let phoneNumberPlaceholder = "+1 (555) 123-4567"

    static let firstNameLabel = "First Name"
    static let firstNamePlaceholder = "John"

    static let lastNameLabel = "Last Name"
    static let lastNamePlaceholder = "Doe"

    // MARK: - Other Fields
    static let retailOutletLabel = "Retail Outlet"
    static let retailOutletPlaceholder = "Select outlet"

    static let otpCodeLabel = "OTP Code"
    static let otpCodePlaceholder = "123456"

    // MARK: - Buttons
    static let submitButtonText = "Submit"
    static let payButtonText = "Pay"

    // MARK: - Composite Components
    static let billingAddressTitle = "Billing Address"
    static let cardDetailsTitle = "Card Details"
}
