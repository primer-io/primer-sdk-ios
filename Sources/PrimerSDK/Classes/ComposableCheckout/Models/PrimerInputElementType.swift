//
//  PrimerInputElementType.swift
//  
//
//  Created on 17.06.2025.
//

import Foundation

/// Input element types that match Android's PrimerInputElementType exactly
internal enum ComposableInputElementType: String, CaseIterable, Hashable {
    case cardNumber = "CARD_NUMBER"
    case cvv = "CVV"
    case expiryDate = "EXPIRY_DATE"
    case cardholderName = "CARDHOLDER_NAME"
    case postalCode = "POSTAL_CODE"
    case countryCode = "COUNTRY_CODE"
    case city = "CITY"
    case state = "STATE"
    case addressLine1 = "ADDRESS_LINE_1"
    case addressLine2 = "ADDRESS_LINE_2"
    case phoneNumber = "PHONE_NUMBER"
    case firstName = "FIRST_NAME"
    case lastName = "LAST_NAME"
    case retailOutlet = "RETAIL_OUTLET"
    case otpCode = "OTP_CODE"
}

/// Input validation error that matches Android's PrimerInputValidationError exactly
internal struct ComposableInputValidationError: Equatable, Identifiable, Hashable {
    /// Unique identifier for the error
    var id: String { "\(elementType.rawValue)_\(errorMessage.hashValue)" }
    
    /// The input element type that has the error
    let elementType: ComposableInputElementType
    
    /// The error message to display
    let errorMessage: String
    
    /// Initialize validation error
    /// - Parameters:
    ///   - elementType: Input element type with error
    ///   - errorMessage: Error message to display
    init(elementType: ComposableInputElementType, errorMessage: String) {
        self.elementType = elementType
        self.errorMessage = errorMessage
    }
    
    /// Equatable implementation
    static func == (lhs: ComposableInputValidationError, rhs: ComposableInputValidationError) -> Bool {
        return lhs.elementType == rhs.elementType && lhs.errorMessage == rhs.errorMessage
    }
    
    /// Hashable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(elementType)
        hasher.combine(errorMessage)
    }
}