//
//  ACHUserDetailsCollectableData.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

import Foundation

/**
 * Protocol type defined for validating customer's information.
 *
 * Properties:
 *  - `isValid`: A computed value that determines whether the collected data is valid.
 *  - `invalidFieldError`: A computed value that provides a specific error related to the field that is found invalid.
 */
protocol ACHUserDetailsCollectableDataValidatable {
    var isValid: Bool { get }
    var invalidFieldError: ACHUserDetailsError { get }
}

/**
 * Enumerates the types of data that can be collected during an ACH payment session.
 * It conforms to `PrimerCollectableData` for integration with the Primer SDK data collection process and is `Encodable` to facilitate serialization.
 *
 * Cases:
 *  - `firstName(_ value: String)` - Represents the customer's first name.
 *  - `lastName(_ value: String)` - Represents the customer's last name.
 *  - `emailAddress(_ value: String)` - Represents the customer's email address.
 *
 *  Extends `ACHUserDetailsCollectableDataValidatable` protocol.
 */
public enum ACHUserDetailsCollectableData: PrimerCollectableData, Encodable {
    case firstName(_ value: String)
    case lastName(_ value: String)
    case emailAddress(_ value: String)
}

extension ACHUserDetailsCollectableData: ACHUserDetailsCollectableDataValidatable {
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
            guard !value.isEmpty else {
                return false
            }

            let allowedCharacters = CharacterSet.letters.union(.whitespaces)
            return value.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
        case .lastName(let value):
            guard !value.isEmpty else {
                return false
            }

            let allowedCharacters = CharacterSet.letters.union(.whitespaces)
            return value.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
        case .emailAddress(let value):
            let emailRegEx = "^\\w+([-+.']\\w+)*@\\w+([-.]\\w+)*\\.\\w{2,}([-.]\\w+)*$"
            let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)

            return emailPred.evaluate(with: value)
        }
    }

    /**
     * Provides an error specific to the type of data that is invalid.
     * This helps in identifying which particular field did not pass validation and needs correction.
     *
     * - Returns: A `ACHUserDetailsError` corresponding to the invalid field.
     */
    public var invalidFieldError: ACHUserDetailsError {
        switch self {
        case .firstName:
            return ACHUserDetailsError.invalidFirstName
        case .lastName:
            return ACHUserDetailsError.invalidLastName
        case .emailAddress:
            return ACHUserDetailsError.invalidEmailAddress
        }
    }
}
