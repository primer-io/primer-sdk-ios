//
//  PrimerInputElementType.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation
import UIKit

/// Represents all possible input field types in the checkout flow.
/// This matches the existing PrimerHeadlessUniversalCheckoutInputElement types.
internal enum PrimerInputElementType: String, CaseIterable {
    // Card fields
    case cardNumber
    case cvv
    case expiryDate
    case cardholderName
    
    // Billing address fields
    case firstName
    case lastName
    case addressLine1
    case addressLine2
    case city
    case state
    case postalCode
    case countryCode
    
    // Additional fields
    case phoneNumber
    case email
    case retailOutlet
    case otpCode
    case birthDate
}

// MARK: - Input Configuration

extension PrimerInputElementType {
    
    /// Returns the validation rule for this input type.
    var validationRule: ValidationRule? {
        switch self {
        case .cardNumber:
            return CardNumberRule()
        case .cvv:
            return CVVRule()
        case .expiryDate:
            return ExpiryDateRule()
        case .cardholderName:
            return CardholderNameRule()
        case .firstName, .lastName:
            return NameRule()
        case .addressLine1, .addressLine2:
            return AddressRule()
        case .city:
            return CityRule()
        case .state:
            return StateRule()
        case .postalCode:
            return PostalCodeRule()
        case .countryCode:
            return CountryCodeRule()
        case .phoneNumber:
            return PhoneNumberRule()
        case .email:
            return EmailRule()
        case .retailOutlet:
            return RetailOutletRule()
        case .otpCode:
            return OTPCodeRule()
        case .birthDate:
            return BirthDateRule()
        }
    }
    
    /// Returns the keyboard type for this input field.
    var keyboardType: UIKeyboardType {
        switch self {
        case .cardNumber, .cvv, .otpCode:
            return .numberPad
        case .expiryDate:
            return .numberPad
        case .phoneNumber:
            return .phonePad
        case .email:
            return .emailAddress
        case .postalCode:
            return .default // Can be alphanumeric in some countries
        default:
            return .default
        }
    }
    
    /// Returns the placeholder text for this input field.
    var placeholder: String {
        switch self {
        case .cardNumber:
            return "1234 5678 9012 3456"
        case .cvv:
            return "123"
        case .expiryDate:
            return "MM/YY"
        case .cardholderName:
            return "John Doe"
        case .firstName:
            return "First name"
        case .lastName:
            return "Last name"
        case .addressLine1:
            return "Street address"
        case .addressLine2:
            return "Apartment, suite, etc. (optional)"
        case .city:
            return "City"
        case .state:
            return "State / Province"
        case .postalCode:
            return "Postal code"
        case .countryCode:
            return "Country"
        case .phoneNumber:
            return "Phone number"
        case .email:
            return "Email address"
        case .retailOutlet:
            return "Select outlet"
        case .otpCode:
            return "Enter code"
        case .birthDate:
            return "DD/MM/YYYY"
        }
    }
    
    /// Returns the label text for this input field.
    var label: String {
        switch self {
        case .cardNumber:
            return "Card number"
        case .cvv:
            return "CVV"
        case .expiryDate:
            return "Expiry date"
        case .cardholderName:
            return "Name on card"
        case .firstName:
            return "First name"
        case .lastName:
            return "Last name"
        case .addressLine1:
            return "Address line 1"
        case .addressLine2:
            return "Address line 2"
        case .city:
            return "City"
        case .state:
            return "State"
        case .postalCode:
            return "Postal code"
        case .countryCode:
            return "Country"
        case .phoneNumber:
            return "Phone number"
        case .email:
            return "Email"
        case .retailOutlet:
            return "Retail outlet"
        case .otpCode:
            return "OTP code"
        case .birthDate:
            return "Date of birth"
        }
    }
    
    /// Returns whether this field is typically required.
    /// Note: Actual requirement may depend on backend configuration.
    var isTypicallyRequired: Bool {
        switch self {
        case .addressLine2, .phoneNumber, .email, .retailOutlet:
            return false
        default:
            return true
        }
    }
}