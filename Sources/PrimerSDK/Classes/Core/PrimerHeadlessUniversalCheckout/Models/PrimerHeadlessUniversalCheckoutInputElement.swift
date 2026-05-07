//
//  PrimerHeadlessUniversalCheckoutInputElement.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

/// Identifies the type of input field in payment forms.
///
/// `PrimerInputElementType` is used to specify and identify different input fields
/// in the card form and billing address sections. Each case corresponds to a specific
/// type of user input with its own validation rules and formatting.
///
/// The enum is organized into the following categories:
/// - **Card fields**: `cardNumber`, `expiryDate`, `cvv`, `cardholderName`
/// - **Billing address fields**: `firstName`, `lastName`, `addressLine1`, `addressLine2`,
///   `city`, `state`, `postalCode`, `countryCode`, `phoneNumber`, `email`
/// - **Other fields**: `otp`, `retailer`
/// - **Special cases**: `unknown`, `all`
///
/// Example usage:
/// ```swift
/// // Update a specific field value
/// scope.updateField(.cardNumber, value: "4242424242424242")
///
/// // Check if a field has an error
/// if state.hasError(for: .cvv) {
///     print(state.errorMessage(for: .cvv))
/// }
/// ```
@objc
public enum PrimerInputElementType: Int {
    /// Credit/debit card number (e.g., "4242 4242 4242 4242").
    case cardNumber

    /// Card expiration date in MM/YY format.
    case expiryDate

    /// Card verification value (3-4 digit security code).
    case cvv

    /// Name as printed on the card.
    case cardholderName

    /// One-time password for verification flows.
    case otp

    /// Postal or ZIP code for billing address.
    case postalCode

    /// Phone number for contact or verification.
    case phoneNumber

    /// Retail outlet selection for cash payment methods.
    case retailer

    /// Unknown or unrecognized field type.
    case unknown

    /// ISO country code (e.g., "US", "GB").
    case countryCode

    /// First name for billing address.
    case firstName

    /// Last name for billing address.
    case lastName

    /// Primary street address line.
    case addressLine1

    /// Secondary address line (apartment, suite, etc.).
    case addressLine2

    /// City name for billing address.
    case city

    /// State or province for billing address.
    case state

    /// Email address for receipts and notifications.
    case email

    /// Represents all fields collectively (used for bulk operations).
    case all

    public var stringValue: String {
        switch self {
        case .cardNumber:
            "CARD_NUMBER"
        case .expiryDate:
            "EXPIRY_DATE"
        case .cvv:
            "CVV"
        case .cardholderName:
            "CARDHOLDER_NAME"
        case .otp:
            "OTP"
        case .postalCode:
            "POSTAL_CODE"
        case .phoneNumber:
            "PHONE_NUMBER"
        case .retailer:
            "RETAILER"
        case .countryCode:
            "COUNTRY_CODE"
        case .firstName:
            "FIRST_NAME"
        case .lastName:
            "LAST_NAME"
        case .addressLine1:
            "ADDRESS_LINE_1"
        case .addressLine2:
            "ADDRESS_LINE_2"
        case .city:
            "CITY"
        case .state:
            "STATE"
        case .email:
            "EMAIL"
        case .all:
            "ALL"
        case .unknown:
            "UNKNOWN"

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
        case .cardNumber, .expiryDate:
            guard let text = value as? String, let delimiter else { return nil }
            let textWithoutWhiteSpace = text.withoutWhiteSpace
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
            " "
        case .expiryDate:
            "/"
        default:
            nil
        }
    }

    var maxAllowedLength: Int? {
        switch self {
        case .cardNumber:
            nil
        case .expiryDate:
            4
        case .cvv:
            nil
        case .postalCode:
            10
        default:
            nil
        }
    }

    var allowedCharacterSet: CharacterSet? {
        switch self {
        case .cardNumber, .expiryDate, .cvv, .otp, .phoneNumber:
            CharacterSet(charactersIn: "0123456789")
        case .cardholderName, .firstName, .lastName:
            CharacterSet.letters.union(.whitespaces)
        default:
            nil
        }
    }

    var keyboardType: UIKeyboardType {
        switch self {
        case .cardNumber, .expiryDate, .cvv, .otp, .phoneNumber, .postalCode:
            UIKeyboardType.numberPad
        case .cardholderName, .firstName, .lastName, .city, .state:
            UIKeyboardType.alphabet
        case .email:
            UIKeyboardType.emailAddress
        case .addressLine1, .addressLine2, .countryCode, .retailer, .unknown, .all:
            UIKeyboardType.default
        }
    }

    // MARK: - Structured State Support

    /// Indicates if this field is a card-related field
    var isCardField: Bool {
        switch self {
        case .cardNumber, .expiryDate, .cvv, .cardholderName:
            true
        default:
            false
        }
    }

    /// Indicates if this field is a billing address field
    var isBillingField: Bool {
        switch self {
        case .firstName, .lastName, .addressLine1, .addressLine2, .city, .state, .postalCode, .countryCode, .phoneNumber, .email:
            true
        default:
            false
        }
    }

    /// Indicates if this field is required for basic card form validation
    var isRequired: Bool {
        switch self {
        case .cardNumber, .expiryDate, .cvv, .cardholderName:
            true
        case .postalCode, .countryCode: // Required if billing address is enabled
            true
        default:
            false
        }
    }

    /// Field display order for UI layout
    var displayOrder: Int {
        switch self {
        // Card fields
        case .cardNumber: 1
        case .expiryDate: 2
        case .cvv: 3
        case .cardholderName: 4

        // Billing address fields (matching Drop-in order)
        case .countryCode: 10
        case .addressLine1: 11
        case .postalCode: 12
        case .state: 13
        case .city: 14
        case .addressLine2: 15
        case .firstName: 16
        case .lastName: 17
        case .email: 18
        case .phoneNumber: 19

        // Other fields
        case .otp: 20
        case .retailer: 21
        case .unknown, .all: 999
        }
    }

    /// Human-readable field name for display
    var displayName: String {
        switch self {
        case .cardNumber: "Card Number"
        case .expiryDate: "Expiry Date"
        case .cvv: "CVV"
        case .cardholderName: "Cardholder Name"
        case .firstName: "First Name"
        case .lastName: "Last Name"
        case .addressLine1: "Address Line 1"
        case .addressLine2: "Address Line 2"
        case .city: "City"
        case .state: "State"
        case .postalCode: "Postal Code"
        case .countryCode: "Country"
        case .phoneNumber: "Phone Number"
        case .email: "Email"
        case .otp: "OTP Code"
        case .retailer: "Retail Outlet"
        case .unknown: "Unknown"
        case .all: "All Fields"
        }
    }
}
