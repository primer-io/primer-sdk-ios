//
//  ACHUserDetailsError.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 13.05.2024.
//

import Foundation

/**
 * Protocol type defined for describing a customer field associated with the error.
 *
 * Property:
 *  - `fieldValueDescription`: Returns a string identifier for the field associated with the error.
 */
protocol ACHFieldValueDescribable {
    var fieldValueDescription: String { get }
}

/**
 * Defines errors related to user detail fields during an ACH payment session.
 * This enum encapsulates the types of errors that can occur when validating user details such as first name, last name, and email address.
 *
 * Cases:
 *  - `invalidFirstName`: Indicates an error with the user's first name.
 *  - `invalidLastName`: Indicates an error with the user's last name.
 *  - `invalidEmailAddress`: Indicates an error with the user's email address.
 *
 * Extends `ACHFieldValueDescribable` protocol.
 */
public enum ACHUserDetailsError: Error {
    case invalidFirstName
    case invalidLastName
    case invalidEmailAddress
}

extension ACHUserDetailsError: ACHFieldValueDescribable {
    public var fieldValueDescription: String {
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
