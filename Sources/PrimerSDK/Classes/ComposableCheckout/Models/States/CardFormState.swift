//
//  CardFormState.swift
//  
//
//  Created on 17.06.2025.
//

import Foundation

/// State model for card form that matches Android's CardFormScope.State exactly
public struct CardFormState: Equatable, Hashable {
    /// Map of input fields to their current values (simplified)
    public let inputFields: [PrimerInputElementType: String]
    
    /// List of current field validation errors
    public let fieldErrors: [PrimerInputValidationError]
    
    /// Whether the form is currently loading/submitting
    public let isLoading: Bool
    
    /// Whether the submit button should be enabled
    public let isSubmitEnabled: Bool
    
    /// List of card-related input fields (derived)
    public var cardFields: [PrimerInputElementType] {
        [.cardNumber, .cvv, .expiryDate, .cardholderName]
    }
    
    /// List of billing address input fields (derived)
    public var billingFields: [PrimerInputElementType] {
        [.postalCode, .countryCode, .city, .state, .addressLine1, .addressLine2]
    }
    
    /// Default initial state
    public static let initial = CardFormState(
        inputFields: [:],
        fieldErrors: [],
        isLoading: false,
        isSubmitEnabled: false
    )
    
    /// Initialize card form state (simplified constructor)
    /// - Parameters:
    ///   - inputFields: Current field values
    ///   - fieldErrors: Current validation errors
    ///   - isLoading: Loading state
    ///   - isSubmitEnabled: Submit button enabled state
    public init(
        inputFields: [PrimerInputElementType: String],
        fieldErrors: [PrimerInputValidationError],
        isLoading: Bool,
        isSubmitEnabled: Bool
    ) {
        self.inputFields = inputFields
        self.fieldErrors = fieldErrors
        self.isLoading = isLoading
        self.isSubmitEnabled = isSubmitEnabled
    }
    
    /// Equatable implementation
    public static func == (lhs: CardFormState, rhs: CardFormState) -> Bool {
        return lhs.inputFields == rhs.inputFields &&
               lhs.fieldErrors == rhs.fieldErrors &&
               lhs.isLoading == rhs.isLoading &&
               lhs.isSubmitEnabled == rhs.isSubmitEnabled
    }
    
    /// Hashable implementation
    public func hash(into hasher: inout Hasher) {
        hasher.combine(inputFields)
        hasher.combine(fieldErrors)
        hasher.combine(isLoading)
        hasher.combine(isSubmitEnabled)
    }
}