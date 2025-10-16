//
//  PrimerHeadlessUniversalCheckoutInputElement.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

@objc
public enum PrimerInputElementType: Int {
    case cardNumber
    case expiryDate
    case cvv
    case cardholderName
    case otp
    case postalCode
    case phoneNumber
    case retailer
    case unknown
    case countryCode
    case firstName
    case lastName
    case addressLine1
    case addressLine2
    case city
    case state
    case email
    case all // General case for "all fields"

    public var stringValue: String {
        switch self {
        case .cardNumber:
            return "CARD_NUMBER"
        case .expiryDate:
            return "EXPIRY_DATE"
        case .cvv:
            return "CVV"
        case .cardholderName:
            return "CARDHOLDER_NAME"
        case .otp:
            return "OTP"
        case .postalCode:
            return "POSTAL_CODE"
        case .phoneNumber:
            return "PHONE_NUMBER"
        case .retailer:
            return "RETAILER"
        case .countryCode:
            return "COUNTRY_CODE"
        case .firstName:
            return "FIRST_NAME"
        case .lastName:
            return "LAST_NAME"
        case .addressLine1:
            return "ADDRESS_LINE_1"
        case .addressLine2:
            return "ADDRESS_LINE_2"
        case .city:
            return "CITY"
        case .state:
            return "STATE"
        case .email:
            return "EMAIL"
        case .all:
            return "ALL"
        case .unknown:
            return "UNKNOWN"

        }
    }

    func validate(value: Any, detectedValueType: Any?) -> Bool {
        if [.all, .retailer].contains(self) {
            return true
        }
        if self == .unknown {
            return false
        }

        // Attempt to cast the input value to a String for the remaining cases.
        guard let text = value as? String else { return false }

        switch self {
        case .cardNumber:
            return text.isValidCardNumber
        case .expiryDate:
            return text.isValidExpiryDate
        case .cvv:
            // Validate using CardNetwork if available, otherwise check length.
            if let cardNetwork = detectedValueType as? CardNetwork, cardNetwork != .unknown {
                return text.isValidCVV(cardNetwork: cardNetwork)
            }
            return text.count >= 3 && text.count <= 5
        case .cardholderName:
            return text.isValidNonDecimalString
        case .otp:
            return text.isNumeric
        case .postalCode:
            return text.isValidPostalCode
        case .phoneNumber:
            return text.isNumeric
        case .countryCode, .addressLine1, .addressLine2, .city, .state:
            return !text.isEmpty
        case .firstName, .lastName:
            return text.isValidNonDecimalString
        case .email:
            return text.contains("@") && text.contains(".")
        default:
            return false
        }
    }

    // MARK: - Additional Methods

    func format(value: Any) -> Any {
        switch self {
        case .cardNumber:
            guard let text = value as? String, let delimiter else { return value }
            return text.withoutWhiteSpace.separate(every: 4, with: delimiter)
        case .expiryDate:
            guard let text = value as? String, let delimiter else { return value }
            return text.withoutWhiteSpace.separate(every: 2, with: delimiter)
        default:
            return value
        }
    }

    func clearFormatting(value: Any) -> Any? {
        switch self {
        case .cardNumber,
             .expiryDate:
            guard let text = value as? String else { return nil }
        case .cardNumber, .expiryDate:
            guard let text = value as? String, let delimiter else { return nil }
            let textWithoutWhiteSpace = text.withoutWhiteSpace
            return textWithoutWhiteSpace.replacingOccurrences(of: self.delimiter!, with: "")

            return textWithoutWhiteSpace.replacingOccurrences(of: delimiter, with: "")
        default:
            return value
        }
    }

    func detectType(for value: Any) -> Any? {
        switch self {
        case .cardNumber:
            guard let text = value as? String else { return nil }
            return CardNetwork(cardNumber: text)
        default:
            return value
        }
    }

    var delimiter: String? {
        switch self {
        case .cardNumber:
            return " "
        case .expiryDate:
            return "/"
        default:
            return nil
        }
    }

    var maxAllowedLength: Int? {
        switch self {
        case .cardNumber:
            return nil
        case .expiryDate:
            return 4
        case .cvv:
            return nil
        case .postalCode:
            return 10
        default:
            return nil
        }
    }

    var allowedCharacterSet: CharacterSet? {
        switch self {
        case .cardNumber, .expiryDate, .cvv, .otp, .phoneNumber:
            return CharacterSet(charactersIn: "0123456789")
        case .cardholderName, .firstName, .lastName:
            return CharacterSet.letters.union(.whitespaces)
        default:
            return nil
        }
    }

    var keyboardType: UIKeyboardType {
        switch self {
        case .cardNumber, .expiryDate, .cvv, .otp, .phoneNumber, .postalCode:
            return UIKeyboardType.numberPad
        case .cardholderName, .firstName, .lastName, .city, .state:
            return UIKeyboardType.alphabet
        case .email:
            return UIKeyboardType.emailAddress
        case .addressLine1, .addressLine2, .countryCode, .retailer, .unknown, .all:
            return UIKeyboardType.default
        }
    }
    
    // MARK: - Structured State Support
    
    /// Indicates if this field is a card-related field
    var isCardField: Bool {
        switch self {
        case .cardNumber, .expiryDate, .cvv, .cardholderName:
            return true
        default:
            return false
        }
    }
    
    /// Indicates if this field is a billing address field
    internal var isBillingField: Bool {
        switch self {
        case .firstName, .lastName, .addressLine1, .addressLine2, .city, .state, .postalCode, .countryCode, .phoneNumber, .email:
            return true
        default:
            return false
        }
    }
    
    /// Indicates if this field is required for basic card form validation
    internal var isRequired: Bool {
        switch self {
        case .cardNumber, .expiryDate, .cvv, .cardholderName:
            return true
        case .postalCode, .countryCode: // Required if billing address is enabled
            return true
        default:
            return false
        }
    }
    
    /// Field display order for UI layout
    internal var displayOrder: Int {
        switch self {
        // Card fields
        case .cardNumber: return 1
        case .expiryDate: return 2
        case .cvv: return 3
        case .cardholderName: return 4
        
        // Billing address fields (matching Drop-in order)
        case .countryCode: return 10
        case .addressLine1: return 11
        case .postalCode: return 12
        case .state: return 13
        case .city: return 14
        case .addressLine2: return 15
        case .firstName: return 16
        case .lastName: return 17
        case .email: return 18
        case .phoneNumber: return 19
        
        // Other fields
        case .otp: return 20
        case .retailer: return 21
        case .unknown, .all: return 999
        }
    }
    
    /// Human-readable field name for display
    internal var displayName: String {
        switch self {
        case .cardNumber: return "Card Number"
        case .expiryDate: return "Expiry Date"
        case .cvv: return "CVV"
        case .cardholderName: return "Cardholder Name"
        case .firstName: return "First Name"
        case .lastName: return "Last Name"
        case .addressLine1: return "Address Line 1"
        case .addressLine2: return "Address Line 2"
        case .city: return "City"
        case .state: return "State"
        case .postalCode: return "Postal Code"
        case .countryCode: return "Country"
        case .phoneNumber: return "Phone Number"
        case .email: return "Email"
        case .otp: return "OTP Code"
        case .retailer: return "Retail Outlet"
        case .unknown: return "Unknown"
        case .all: return "All Fields"
        }
    }
}
