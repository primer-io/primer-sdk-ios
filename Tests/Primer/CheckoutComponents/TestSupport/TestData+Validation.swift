//
//  TestData+Validation.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
extension TestData {

    // MARK: - Error Codes

    enum ErrorCodes {
        static let invalid = "invalid"
        static let invalidCard = "invalid-card-number"
        static let invalidCVV = "invalid-cvv"
        static let invalidExpiry = "invalid-expiry"
        static let required = "required"
    }

    // MARK: - Error Messages

    enum ErrorMessages {
        static let invalidCard = "Invalid card number"
        static let invalidCardNumber = "Invalid card number"
        static let invalidCVV = "Invalid CVV"
        static let invalidExpiry = "Invalid expiry date"
        static let required = "This field is required"
        static let fieldRequired = "Field is required"
        static let fieldInvalid = "Field is invalid"
        static let retailOutletRequired = "Retail outlet is required"
        static let retailOutletInvalid = "Invalid retail outlet"
    }

    // MARK: - Error Message Keys

    enum ErrorMessageKeys {
        // Required field keys
        static let genericRequired = "form_error_required"
        static let firstNameRequired = "checkout_components_first_name_required"
        static let lastNameRequired = "checkout_components_last_name_required"
        static let emailRequired = "checkout_components_email_required"
        static let countryRequired = "checkout_components_country_required"
        static let addressLine1Required = "checkout_components_address_line_1_required"
        static let addressLine2Required = "checkout_components_address_line_2_required"
        static let cityRequired = "checkout_components_city_required"
        static let stateRequired = "checkout_components_state_required"
        static let postalCodeRequired = "checkout_components_postal_code_required"
        static let phoneNumberRequired = "checkout_components_phone_number_required"
        static let retailOutletRequired = "checkout_components_retail_outlet_required"

        // Invalid field keys
        static let genericInvalid = "form_error_invalid"
        static let cardNumberInvalid = "checkout_components_card_number_invalid"
        static let cvvInvalid = "checkout_components_cvv_invalid"
        static let expiryDateInvalid = "checkout_components_expiry_date_invalid"
        static let cardholderNameInvalid = "checkout_components_cardholder_name_invalid"
        static let firstNameInvalid = "checkout_components_first_name_invalid"
        static let lastNameInvalid = "checkout_components_last_name_invalid"
        static let emailInvalid = "checkout_components_email_invalid"
        static let countryInvalid = "checkout_components_country_invalid"
        static let addressLine1Invalid = "checkout_components_address_line_1_invalid"
        static let addressLine2Invalid = "checkout_components_address_line_2_invalid"
        static let cityInvalid = "checkout_components_city_invalid"
        static let stateInvalid = "checkout_components_state_invalid"
        static let postalCodeInvalid = "checkout_components_postal_code_invalid"
        static let phoneNumberInvalid = "checkout_components_phone_number_invalid"
        static let retailOutletInvalid = "checkout_components_retail_outlet_invalid"
    }

    // MARK: - Names

    enum Names {
        static let firstName = "John"
        static let lastName = "Doe"
        static let fullName = "John Doe"
    }

    // MARK: - Test Fixtures

    enum TestFixtures {
        static let defaultErrorId = "test-error-id"
        static let defaultCode = "TEST_ERROR"
        static let defaultMessage = "Test error message"
    }
}
