//
//  StripeAchUserDetails.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 26.04.2024.
//

import Foundation

public enum StripeAchUserDetailsError: Error {
    case invalidFirstName
    case invalidLastName
    case invalidEmailAddress
    
    case validationErrors([StripeAchUserDetailsError])
    
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

public struct StripeAchUserDetails: Codable {
    var firstName: String
    var lastName: String
    var emailAddress: String
    
    // Validate the entire user details
    public static func validate(userDetails: StripeAchUserDetails) throws {
        var errors: [StripeAchUserDetailsError] = []
        
        if let error = validateFirstName(userDetails.firstName) {
            errors.append(error)
        }
        
        if let error = validateLastName(userDetails.lastName) {
            errors.append(error)
        }
        
        if let error = validateEmailAddress(userDetails.emailAddress) {
            errors.append(error)
        }
        
        if !errors.isEmpty {
            throw StripeAchUserDetailsError.validationErrors(errors)
        }
    }
    
    // Validate first name
    private static func validateFirstName(_ firstName: String) -> StripeAchUserDetailsError? {
        return firstName.isEmpty ? StripeAchUserDetailsError.invalidFirstName : nil
    }
    
    // Validate last name
    private static func validateLastName(_ lastName: String) -> StripeAchUserDetailsError? {
        return lastName.isEmpty ? StripeAchUserDetailsError.invalidLastName : nil
    }
    
    // Validate email address using a regular expression
    private static func validateEmailAddress(_ email: String) -> StripeAchUserDetailsError? {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        
        return emailPred.evaluate(with: email) ? nil : StripeAchUserDetailsError.invalidEmailAddress
    }
}
