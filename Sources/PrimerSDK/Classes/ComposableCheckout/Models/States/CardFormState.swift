//
//  CardFormState.swift
//  
//
//  Created on 17.06.2025.
//

import Foundation

/// State model for card form that matches Android's CardFormScope.State exactly
public struct CardFormState: Equatable {
    /// List of card-related input fields
    public let cardFields: [PrimerInputElementType]
    
    /// List of billing address input fields
    public let billingFields: [PrimerInputElementType]
    
    /// List of current field validation errors
    public let fieldErrors: [PrimerInputValidationError]
    
    /// Map of input fields to their current values
    public let inputFields: [PrimerInputElementType: String]
    
    /// Whether the form is currently loading/submitting
    public let isLoading: Bool
    
    /// Whether the submit button should be enabled
    public let isSubmitEnabled: Bool
    
    /// Default initial state
    public static let initial = CardFormState(
        cardFields: [],
        billingFields: [],
        fieldErrors: [],
        inputFields: [:],
        isLoading: false,
        isSubmitEnabled: false
    )
    
    /// Initialize card form state
    /// - Parameters:
    ///   - cardFields: Card-related input fields
    ///   - billingFields: Billing address input fields
    ///   - fieldErrors: Current validation errors
    ///   - inputFields: Current field values
    ///   - isLoading: Loading state
    ///   - isSubmitEnabled: Submit button enabled state
    public init(
        cardFields: [PrimerInputElementType],
        billingFields: [PrimerInputElementType],
        fieldErrors: [PrimerInputValidationError],
        inputFields: [PrimerInputElementType: String],
        isLoading: Bool,
        isSubmitEnabled: Bool
    ) {
        self.cardFields = cardFields
        self.billingFields = billingFields
        self.fieldErrors = fieldErrors
        self.inputFields = inputFields
        self.isLoading = isLoading
        self.isSubmitEnabled = isSubmitEnabled
    }
    
    /// Equatable implementation
    public static func == (lhs: CardFormState, rhs: CardFormState) -> Bool {
        return lhs.cardFields == rhs.cardFields &&
               lhs.billingFields == rhs.billingFields &&
               lhs.fieldErrors == rhs.fieldErrors &&
               lhs.inputFields == rhs.inputFields &&
               lhs.isLoading == rhs.isLoading &&
               lhs.isSubmitEnabled == rhs.isSubmitEnabled
    }
}