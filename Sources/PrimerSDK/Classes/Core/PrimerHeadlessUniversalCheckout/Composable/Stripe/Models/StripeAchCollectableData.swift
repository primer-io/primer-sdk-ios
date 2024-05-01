//
//  StripeAchCollectableData.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

import Foundation

/**
 * Enumerates the types of data that can be collected during a Stripe ACH payment session.
 * It conforms to `PrimerCollectableData` for integration with the Primer SDK data collection process and is `Encodable` to facilitate serialization.
 *
 * Cases:
 *  - `firstName(_ value: String)` - Represents the customer's first name.
 *  - `lastName(_ value: String)` - Represents the customer's last name.
 *  - `emailAddress(_ value: String)` - Represents the customer's email address.
 *
 * Properties:
 *  - `isValid`: A computed value that determines whether the collected data is valid.
 *  - `invalidFieldError`: A computed value that provides a specific error related to the field that is found invalid.
 */
public enum StripeAchCollectableData: PrimerCollectableData, Encodable {
    case firstName(_ value: String)
    case lastName(_ value: String)
    case emailAddress(_ value: String)

    /**
     * Validates the data based on the type.
     * For `firstName` and `lastName`, checks if the string is not empty.
     * For `emailAddress`, validates using a regular expression to ensure it is in a correct email format.
     *
     * - Returns: A Boolean value indicating whether the data is valid.
     */
    public var isValid: Bool {
        switch self {
        case .firstName(let value):
            return !value.isEmpty
        case .lastName(let value):
            return !value.isEmpty
        case .emailAddress(let value):
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            
            return emailPred.evaluate(with: value)
        }
    }

    /**
     * Provides an error specific to the type of data that is invalid.
     * This helps in identifying which particular field did not pass validation and needs correction.
     *
     * - Returns: A `StripeAchUserDetailsError` corresponding to the invalid field.
     */
    public var invalidFieldError: StripeAchUserDetailsError {
        switch self {
        case .firstName:
            return StripeAchUserDetailsError.invalidFirstName
        case .lastName:
            return StripeAchUserDetailsError.invalidLastName
        case .emailAddress:
            return StripeAchUserDetailsError.invalidEmailAddress
        }
    }
}
