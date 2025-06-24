//
//  CardDetailsView.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

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

    @Environment(\.designTokens) private var tokens

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Card Number
            CardNumberInputField(
                label: "Card Number",
                placeholder: "1234 5678 9012 3456",
                onCardNumberChange: { number in
                    cardFormScope.updateCardNumber(number)
                },
                onCardNetworkChange: { network in
                    cardNetwork = network
                },
                onValidationChange: { isValid in
                    isCardNumberValid = isValid
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
                }
            )
        }
    }

    /// Returns whether all card fields are valid
    var isValid: Bool {
        isCardNumberValid && isCVVValid && isExpiryValid && isCardholderNameValid
    }
}
