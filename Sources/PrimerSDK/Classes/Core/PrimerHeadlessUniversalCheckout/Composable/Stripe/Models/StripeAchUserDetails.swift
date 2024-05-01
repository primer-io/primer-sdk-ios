//
//  StripeAchUserDetails.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 26.04.2024.
//

import Foundation

/**
 * Defines errors related to user detail fields during a Stripe ACH payment session.
 * This enum encapsulates the types of errors that can occur when validating user details such as first name, last name, and email address.
 *
 * Cases:
 *  - `invalidFirstName`: Indicates an error with the user's first name.
 *  - `invalidLastName`: Indicates an error with the user's last name.
 *  - `invalidEmailAddress`: Indicates an error with the user's email address.
 *
 * Property:
 *  - `fieldValue`: Returns a string identifier for the field associated with the error.
 */
public enum StripeAchUserDetailsError: Error {
    case invalidFirstName
    case invalidLastName
    case invalidEmailAddress
    
    public var fieldValue: String {
        switch self {
        case .invalidFirstName:
            return "firstname"
        case .invalidLastName:
            return "lastname"
        case .invalidEmailAddress:
            return "email"
        }
    }
}

/**
 * Represents user details specifically for a Stripe ACH transaction.
 * This class holds and manages user data such as first name, last name, and email address.
 *
 * Properties:
 *  - `firstName`: A `String` representing the user's first name.
 *  - `lastName`: A `String` representing the user's last name.
 *  - `emailAddress`: A `String` representing the user's email address.
 *
 * Initialization and Update:
 *  - `init(firstName:lastName:emailAddress:)`: Initializes a new user details instance with specified first name, last name, and email address.
 *  - `update(with:)`: Updates the user details with new data collected during a transaction process.
 *  - `emptyUserDetails()`: Factory method to create an instance of `StripeAchUserDetails` with all fields set to empty strings.
 */
public class StripeAchUserDetails: Codable {
    var firstName: String
    var lastName: String
    var emailAddress: String
    
    
    public init(firstName: String, lastName: String, emailAddress: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.emailAddress = emailAddress
    }
    
    public func update(with collectedData: StripeAchCollectableData) {
        switch collectedData {
        case .firstName(let value):
            firstName = value
        case .lastName(let value):
            lastName = value
        case .emailAddress(let value):
            emailAddress = value
        }
    }
    
    public static func emptyUserDetails() -> StripeAchUserDetails {
        return StripeAchUserDetails(firstName: "", lastName: "", emailAddress: "")
    }
}

/**
 * Extension to make `StripeAchUserDetails` conform to `Equatable`, allowing for comparison between instances.
 * Methods:
 *  - `==`: Determines if two instances of `StripeAchUserDetails` are exactly equal by comparing their properties.
 *  - `isEqual(lhs:rhs:)`: Checks for equality between two instances and identifies fields that are not equal.
 */
extension StripeAchUserDetails: Equatable {
    public static func == (lhs: StripeAchUserDetails, rhs: StripeAchUserDetails) -> Bool {
        return lhs.firstName == rhs.firstName &&
        lhs.lastName == rhs.lastName &&
        lhs.emailAddress == rhs.emailAddress
    }
    
    /**
     * Evaluates the equality of two `StripeAchUserDetails` instances and identifies which fields, if any, are not equal.
     * This method not only checks if two instances are equal but also collects details about which fields differ.
     * - Returns: A tuple containing a boolean indicating overall equality and an array of `StripeAchUserDetailsError`
     *            representing each field that is not equal.
     */
    public static func isEqual(lhs: StripeAchUserDetails,
                               rhs: StripeAchUserDetails) -> (areEqual: Bool, differingFields: [StripeAchUserDetailsError]) {
        var unequalFields: [StripeAchUserDetailsError] = []
        var areEqual = true
        if lhs.firstName != rhs.firstName {
            unequalFields.append(StripeAchUserDetailsError.invalidFirstName)
            areEqual = false
        }
        if lhs.lastName != rhs.lastName {
            unequalFields.append(StripeAchUserDetailsError.invalidLastName)
            areEqual = false
        }
        if lhs.emailAddress != rhs.emailAddress {
            unequalFields.append(StripeAchUserDetailsError.invalidEmailAddress)
            areEqual = false
        }
        
        return (areEqual, unequalFields)
    }
}
