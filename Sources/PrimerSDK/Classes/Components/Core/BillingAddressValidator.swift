//
//  BillingAddressValidator.swift
//  
//
//  Created by Boris on 24.3.25..
//

import Foundation

/// Protocol defining a validator for billing address inputs
protocol BillingAddressValidator {
    /// Validates the billing address and returns validation errors for each field
    /// - Parameter billingAddress: Dictionary mapping input fields to their values
    /// - Returns: Dictionary mapping input fields to validation errors (nil if valid)
    func getValidatedBillingAddress(
        billingAddress: [PrimerInputElementType: String?]
    ) -> [PrimerInputElementType: ValidationError?]
}

/// Default implementation of billing address validation
class DefaultBillingAddressValidator: BillingAddressValidator {
    func getValidatedBillingAddress(
        billingAddress: [PrimerInputElementType: String?]
    ) -> [PrimerInputElementType: ValidationError?] {
        return billingAddress.mapValues { value in
            if value?.isEmpty != false {
                return ValidationError(
                    code: errorIdBy(inputType: billingAddress.keys.first ?? .all),
                    message: errorDescriptionBy(inputType: billingAddress.keys.first ?? .all)
                )
            } else {
                return nil
            }
        }
    }

    // TODO: Use string resources
    private func errorDescriptionBy(inputType: PrimerInputElementType) -> String {
        switch inputType {
        case .postalCode:
            return "Postal code is required."
        case .countryCode:
            return "Country code is required."
        case .city:
            return "City is required."
        case .state:
            return "State is required."
        case .addressLine1:
            return "Address line 1 is required."
        case .firstName:
            return "First name is required."
        case .lastName:
            return "Last name is required."
        case .addressLine2:
            return "Address line 2 is required."
        // Handle all other card-related fields
        case .cardNumber:
            return "Card number is required."
        case .expiryDate:
            return "Expiry date is required."
        case .cvv:
            return "CVV is required."
        case .cardholderName:
            return "Cardholder name is required."
        // Handle all other cases
        case .otp:
            return "OTP is required."
        case .phoneNumber:
            return "Phone number is required."
        case .retailer:
            return "Retailer is required."
        case .unknown, .all:
            return "Invalid input."
        }
    }

    private func errorIdBy(inputType: PrimerInputElementType) -> String {
        switch inputType {
        case .postalCode:
            return "invalid-postal-code"
        case .countryCode:
            return "invalid-country"
        case .city:
            return "invalid-city"
        case .state:
            return "invalid-state"
        case .addressLine1:
            return "invalid-address"
        case .firstName:
            return "invalid-first-name"
        case .lastName:
            return "invalid-last-name"
        case .addressLine2:
            return "invalid-address-line-2"
        // Handle all other card-related fields
        case .cardNumber:
            return "invalid-card-number"
        case .expiryDate:
            return "invalid-expiry-date"
        case .cvv:
            return "invalid-cvv"
        case .cardholderName:
            return "invalid-cardholder-name"
        // Handle all other cases
        case .otp:
            return "invalid-otp"
        case .phoneNumber:
            return "invalid-phone-number"
        case .retailer:
            return "invalid-retailer"
        case .unknown, .all:
            return "invalid-input"
        }
    }
}
