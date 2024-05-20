//
//  ACHUserDetails.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 26.04.2024.
//

import Foundation

/**
 * The protocol includes methods for updating user details with new data collected during the transaction process,
  * as well as a factory method for creating a new instance of `ACHUserDetails` with all fields initialized to empty strings.
  *
  * Methods:
  *  - `update(with:)`: Updates the `ACHUserDetails` instance with new data from a given `ACHCollectableData` instance.
  *    This method should be used to reflect any changes in the user's information that came from the client session.
  *
  *  - `emptyUserDetails()`: Factory method that returns a new `ACHUserDetails` instance where all user detail fields are initialized to empty strings.
  *    Use this method to create a default state for `ACHUserDetails` with no pre-filled information.
  */
protocol ACHUserDetailsHandling {
    func update(with collectedData: ACHCollectableData)
    static func emptyUserDetails() -> ACHUserDetails
}

/**
 * Represents user details specifically for an ACH transaction.
 * This class holds and manages user data such as first name, last name, and email address.
 *
 * Properties:
 *  - `firstName`: A `String` representing the user's first name.
 *  - `lastName`: A `String` representing the user's last name.
 *  - `emailAddress`: A `String` representing the user's email address.
 *
 * Initialization:
 *  - `init(firstName:lastName:emailAddress:)`: Initializes a new user details instance with specified first name, last name, and email address.
 */
public class ACHUserDetails: Codable {
    public var firstName: String
    public var lastName: String
    public var emailAddress: String
    
    
    public init(firstName: String, lastName: String, emailAddress: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.emailAddress = emailAddress
    }
}

extension ACHUserDetails: ACHUserDetailsHandling {
    public func update(with collectedData: ACHCollectableData) {
        switch collectedData {
        case .firstName(let value):
            firstName = value
        case .lastName(let value):
            lastName = value
        case .emailAddress(let value):
            emailAddress = value
        }
    }
    
    public static func emptyUserDetails() -> ACHUserDetails {
        return ACHUserDetails(firstName: "", lastName: "", emailAddress: "")
    }
}

/**
 * Extension that conforms `ACHUserDetails` to the `Equatable` protocol, enabling comparison of instances.
 * Methods:
 *  - `==`: Determines if two instances of `ACHUserDetails` are exactly equal by comparing their properties.
 *  - `isEqual(lhs:rhs:)`: Checks for equality between two instances and identifies fields that are not equal.
 */
extension ACHUserDetails: Equatable {
    public static func == (lhs: ACHUserDetails, rhs: ACHUserDetails) -> Bool {
        return lhs.firstName == rhs.firstName &&
        lhs.lastName == rhs.lastName &&
        lhs.emailAddress == rhs.emailAddress
    }

    /// Compares two instances for equality and details any differing fields.
    public static func compare(lhs: ACHUserDetails,
                               rhs: ACHUserDetails) -> (areEqual: Bool, differingFields: [ACHUserDetailsError]) {
        var unequalFields: [ACHUserDetailsError] = []
        var areEqual = true
        if lhs.firstName != rhs.firstName {
            unequalFields.append(ACHUserDetailsError.invalidFirstName)
            areEqual = false
        }
        if lhs.lastName != rhs.lastName {
            unequalFields.append(ACHUserDetailsError.invalidLastName)
            areEqual = false
        }
        if lhs.emailAddress != rhs.emailAddress {
            unequalFields.append(ACHUserDetailsError.invalidEmailAddress)
            areEqual = false
        }
        
        return (areEqual, unequalFields)
    }
}
