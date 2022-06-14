//
//  Strings.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 10/02/22.
//  Copyright © 2022 Primer API ltd, Inc. All rights reserved.
//

import Foundation

struct Strings {
    
    enum PrimerButton {
        
        static let title = NSLocalizedString(
            "primer-button-title-default",
            bundle: Bundle.primerResources,
            comment: "The title of the primer deafult button")
        
        static let payInInstallments = NSLocalizedString(
            "primer-button-title-pay-in-installments",
            bundle: Bundle.primerResources,
            value: "Pay in installments",
            comment: "The title of the primer 'pay in installments' button")
    }
    
    enum Generic {
        
        static let somethingWentWrong = NSLocalizedString(
            "primer-error-screen",
            bundle: Bundle.primerResources,
            value: "Something went wrong, please try again.",
            comment: "A generic error message that is displayed on the error view")
        
        static let isRequiredSuffix = NSLocalizedString(
            "primer-error-is-required-suffix",
            bundle: Bundle.primerResources,
            value: "is required",
            comment: "A suffix to mark a required field or action being performed")

    }
    
}

extension Strings {
    
    enum PostalCode {
        
        static let defaultPostalCodeName = NSLocalizedString(
            "primer-card-form-postal-code-default-name",
            bundle: Bundle.primerResources,
            value: "Postal code",
            comment: "The default naming of Postal Code")
        
        static let zipCodeName = NSLocalizedString(
            "primer-card-form-postal-code-zip-code-name",
            bundle: Bundle.primerResources,
            value: "Zip code",
            comment: "The naming representation of Postal Code for e.g. USA")
    }
    
}

extension Strings {
    
    enum CardFormValidation {
        
        static let invalidCardNumber = NSLocalizedString(
            "primer-error-card-form-card-number",
            bundle: Bundle.primerResources,
            value: "Invalid card number",
            comment: "An error message displayed when the card number is not correct")
        
        static let invalidExpirationDate = NSLocalizedString(
            "primer-error-card-form-card-expiration-date",
            bundle: Bundle.primerResources,
            value: "Invalid date",
            comment: "An error message displayed when the card expiration date is not correct")
        
        static let invalidCVV = NSLocalizedString(
            "primer-error-card-form-card-cvv",
            bundle: Bundle.primerResources,
            value: "Invalid date",
            comment: "An error message displayed when the cvv code is not correct")
        
        static let invalidCardholderName = NSLocalizedString(
            "primer-error-card-form-cardholder-name",
            bundle: Bundle.primerResources,
            value: "Invalid date",
            comment: "An error message displayed when the cardholder name is not correct")
        
        static let invalidCountry = NSLocalizedString(
            "primer-error-card-form-country",
            bundle: Bundle.primerResources,
            value: "Invalid country",
            comment: "An error message displayed when the country field is not correct")
        
        static let invalidFirstName = NSLocalizedString(
            "primer-error-card-form-first-name",
            bundle: Bundle.primerResources,
            value: "Invalid first name",
            comment: "An error message displayed when the first name field is not correct")
        
        static let invalidLastName = NSLocalizedString(
            "primer-error-card-form-last-name",
            bundle: Bundle.primerResources,
            value: "Invalid last name",
            comment: "An error message displayed when the last name field is not correct")

        static let invalidCity = NSLocalizedString(
            "primer-error-card-form-city",
            bundle: Bundle.primerResources,
            value: "Invalid city",
            comment: "An error message displayed when the city field is not correct")
        
        static let invalidState = NSLocalizedString(
            "primer-error-card-form-state",
            bundle: Bundle.primerResources,
            value: "Invalid State",
            comment: "An error message displayed when the state field is not correct")
        
        // Valid for both Address Line 1 and Address Line 2 fields
        static let invalidAddress = NSLocalizedString(
            "primer-error-card-form-address",
            bundle: Bundle.primerResources,
            value: "Invalid address",
            comment: "An error message displayed when the address field is not correct")
    }
}
