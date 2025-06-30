//
//  CardDetailsView.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Validation state tracking structure
private struct ValidationState: Equatable {
    let cardNumber: Bool
    let cvv: Bool
    let expiry: Bool
    let cardholderName: Bool
}

/// A composite SwiftUI view containing all card input fields
@available(iOS 15.0, *)
internal struct CardDetailsView: View {
    // MARK: - Properties

    /// The card form scope for handling updates
    let cardFormScope: PrimerCardFormScope

    /// Currently detected card network
    @State private var cardNetwork: CardNetwork = .unknown

    /// Available networks for co-badged cards
    @State private var availableNetworks: [CardNetwork] = []

    /// Validation states for each field
    @State private var isCardNumberValid = false
    @State private var isCVVValid = false
    @State private var isExpiryValid = false
    @State private var isCardholderNameValid = false

    /// Previous validation states to detect changes
    @State private var previousValidationState: ValidationState?

    @Environment(\.designTokens) private var tokens

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Card Number
            CardNumberInputField(
                label: "Card Number",
                placeholder: "1234 1234 1234 1234",
                onCardNumberChange: { number in
                    cardFormScope.updateCardNumber(number)
                },
                onCardNetworkChange: { network in
                    cardNetwork = network
                },
                onValidationChange: { isValid in
                    isCardNumberValid = isValid
                    updateValidationState()
                },
                onNetworksDetected: { networks in
                    availableNetworks = networks
                    // Notify scope about detected networks
                    if let scope = cardFormScope as? DefaultCardFormScope {
                        scope.handleDetectedNetworks(networks)
                    }
                }
            )

            // Card number and CVV in horizontal layout
            HStack(spacing: 16) {
                // Expiry Date
                ExpiryDateInputField(
                    label: "Expiry Date",
                    placeholder: "MM/YY",
                    onExpiryDateChange: { _ in
                        // Already handled by month/year callbacks
                    },
                    onValidationChange: { isValid in
                        isExpiryValid = isValid
                        updateValidationState()
                    },
                    onMonthChange: { month in
                        cardFormScope.updateExpiryMonth(month)
                    },
                    onYearChange: { year in
                        cardFormScope.updateExpiryYear(year)
                    }
                )

                // CVV
                CVVInputField(
                    label: "CVV",
                    placeholder: cardNetwork.validation?.code.name ?? "CVV",
                    cardNetwork: cardNetwork,
                    onCvvChange: { cvv in
                        cardFormScope.updateCvv(cvv)
                    },
                    onValidationChange: { isValid in
                        isCVVValid = isValid
                        updateValidationState()
                    }
                )
                .frame(maxWidth: 120)
            }

            // Cardholder Name
            CardholderNameInputField(
                label: "Cardholder Name",
                placeholder: "John Doe",
                onCardholderNameChange: { name in
                    cardFormScope.updateCardholderName(name)
                },
                onValidationChange: { isValid in
                    isCardholderNameValid = isValid
                    updateValidationState()
                }
            )
        }
    }

    /// Returns whether all card fields are valid
    var isValid: Bool {
        isCardNumberValid && isCVVValid && isExpiryValid && isCardholderNameValid
    }

    /// Updates the card form scope with the current validation state
    private func updateValidationState() {
        let currentState = ValidationState(
            cardNumber: isCardNumberValid,
            cvv: isCVVValid,
            expiry: isExpiryValid,
            cardholderName: isCardholderNameValid
        )

        // Only notify if validation state has changed
        if previousValidationState != currentState {
            previousValidationState = currentState

            // Notify the scope of the field-level validation state
            cardFormScope.updateValidationState(
                cardNumber: isCardNumberValid,
                cvv: isCVVValid,
                expiry: isExpiryValid,
                cardholderName: isCardholderNameValid
            )
        }
    }
}
