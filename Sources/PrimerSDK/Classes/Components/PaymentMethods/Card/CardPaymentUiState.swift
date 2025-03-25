//
//  CardPaymentUiState.swift
//
//
//  Created by Boris on 17.3.25..
//

import Foundation

/**
 * UI state representation for card payment form.
 */
struct CardPaymentUiState: PrimerPaymentMethodUiState {
    // Card data
    var cardData: CardData

    // Card network data
    var cardNetworkData: CardNetworkData

    // Billing address data
    var billingAddress: BillingAddress

    // Processing state
    var isProcessing: Bool

    // Surcharge data
    var surcharge: String?

    /// Indicates whether the form is empty, meaning no user input has been provided.
    var isFormEmpty: Bool {
        return cardData.fields.filter { $0.isRequired }.all { $0.value.isEmpty }
    }

    /// Validation errors for the form fields.
    var validationErrors: [ValidationError] {
        return (cardData.validationErrors + billingAddress.validationErrors).compactMap { $0 }
    }

    struct CardData {
        var cardNumber: InputFieldState
        var expiration: InputFieldState
        var cvv: InputFieldState
        var cardholderName: InputFieldState

        var fields: [InputFieldState] {
            return [cardNumber, expiration, cvv, cardholderName]
        }

        var validationErrors: [ValidationError?] {
            return fields.map { $0.validationError }
        }
    }

    struct CardNetworkData {
        let networks: [PrimerCardNetwork]
        let preferredNetwork: CardNetwork?
        var selectedNetwork: CardNetwork?
    }

    struct BillingAddress {
        var country: InputFieldState
        let firstName: InputFieldState
        let lastName: InputFieldState
        let addressLine1: InputFieldState
        let addressLine2: InputFieldState
        let city: InputFieldState
        let postalCode: InputFieldState
        let state: InputFieldState

        var fields: [InputFieldState] {
            return [country, firstName, lastName, addressLine1, addressLine2, city, postalCode, state]
        }

        var validationErrors: [ValidationError?] {
            return fields.filter { $0.isVisible && $0.isRequired }.map { $0.validationError }
        }

        var visibleFields: [InputFieldState] {
            return fields.filter { $0.isVisible }
        }

        var isVisible: Bool {
            return visibleFields.isNotEmpty
        }
    }

    static var empty: CardPaymentUiState {
        return CardPaymentUiState(
            cardData: CardData(
                cardNumber: InputFieldState(),
                expiration: InputFieldState(),
                cvv: InputFieldState(),
                cardholderName: InputFieldState()
            ),
            cardNetworkData: CardNetworkData(
                networks: [],
                preferredNetwork: nil,
                selectedNetwork: nil
            ),
            billingAddress: BillingAddress(
                country: InputFieldState(isVisible: false),
                firstName: InputFieldState(isVisible: false),
                lastName: InputFieldState(isVisible: false),
                addressLine1: InputFieldState(isVisible: false),
                addressLine2: InputFieldState(isVisible: false),
                city: InputFieldState(isVisible: false),
                postalCode: InputFieldState(isVisible: false),
                state: InputFieldState(isVisible: false)
            ),
            isProcessing: false,
            surcharge: nil
        )
    }
}

extension CardPaymentUiState {
    // Helper to create a new state with updated billing address
    func copyWithBillingAddress(_ billingAddress: BillingAddress) -> CardPaymentUiState {
        return CardPaymentUiState(
            cardData: self.cardData,
            cardNetworkData: self.cardNetworkData,
            billingAddress: billingAddress,
            isProcessing: self.isProcessing,
            surcharge: self.surcharge
        )
    }
}

// Helper structure to match Android implementation
struct InputFieldState {
    let value: String
    let validationError: ValidationError?
    let isVisible: Bool
    let isRequired: Bool
    let isLast: Bool

    init(
        value: String = "",
        validationError: ValidationError? = nil,
        isVisible: Bool = true,
        isRequired: Bool = false,
        isLast: Bool = false
    ) {
        self.value = value
        self.validationError = validationError
        self.isVisible = isVisible
        self.isRequired = isRequired
        self.isLast = isLast
    }

    var imeAction: UIReturnKeyType {
        return isLast ? .done : .next
    }
}

// Helper extensions
extension Collection {
    var isNotEmpty: Bool {
        return !isEmpty
    }

    func all(_ predicate: (Element) -> Bool) -> Bool {
        return self.allSatisfy(predicate)
    }
}
