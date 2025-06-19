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
    public let inputFields: [ComposableInputElementType: String]

    /// List of current field validation errors
    public let fieldErrors: [ComposableInputValidationError]

    /// Whether the form is currently loading/submitting
    public let isLoading: Bool

    /// Whether the submit button should be enabled
    public let isSubmitEnabled: Bool

    /// Detected card network from card number
    public let cardNetwork: CardNetwork?

    /// List of card-related input fields (dynamic from backend)
    public let cardFields: [ComposableInputElementType]

    /// List of billing address input fields (dynamic from backend)
    public let billingFields: [ComposableInputElementType]

    /// Default initial state
    public static let initial = CardFormState(
        inputFields: [:],
        fieldErrors: [],
        isLoading: false,
        isSubmitEnabled: false,
        cardNetwork: nil,
        cardFields: [.cardNumber, .cvv, .expiryDate],
        billingFields: []
    )

    /// Initialize card form state
    /// - Parameters:
    ///   - inputFields: Current field values
    ///   - fieldErrors: Current validation errors
    ///   - isLoading: Loading state
    ///   - isSubmitEnabled: Submit button enabled state
    ///   - cardNetwork: Detected card network
    ///   - cardFields: Required card fields from backend
    ///   - billingFields: Required billing fields from backend
    public init(
        inputFields: [ComposableInputElementType: String],
        fieldErrors: [ComposableInputValidationError],
        isLoading: Bool,
        isSubmitEnabled: Bool,
        cardNetwork: CardNetwork? = nil,
        cardFields: [ComposableInputElementType],
        billingFields: [ComposableInputElementType]
    ) {
        self.inputFields = inputFields
        self.fieldErrors = fieldErrors
        self.isLoading = isLoading
        self.isSubmitEnabled = isSubmitEnabled
        self.cardNetwork = cardNetwork
        self.cardFields = cardFields
        self.billingFields = billingFields
    }

    /// Equatable implementation
    public static func == (lhs: CardFormState, rhs: CardFormState) -> Bool {
        return lhs.inputFields == rhs.inputFields &&
            lhs.fieldErrors == rhs.fieldErrors &&
            lhs.isLoading == rhs.isLoading &&
            lhs.isSubmitEnabled == rhs.isSubmitEnabled &&
            lhs.cardNetwork == rhs.cardNetwork &&
            lhs.cardFields == rhs.cardFields &&
            lhs.billingFields == rhs.billingFields
    }

    /// Hashable implementation
    public func hash(into hasher: inout Hasher) {
        hasher.combine(inputFields)
        hasher.combine(fieldErrors)
        hasher.combine(isLoading)
        hasher.combine(isSubmitEnabled)
        hasher.combine(cardNetwork)
        hasher.combine(cardFields)
        hasher.combine(billingFields)
    }
}
