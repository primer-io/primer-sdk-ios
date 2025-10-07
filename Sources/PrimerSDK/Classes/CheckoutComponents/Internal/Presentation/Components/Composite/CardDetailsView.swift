//
//  CardDetailsView.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// A composite SwiftUI view containing all card input fields
@available(iOS 15.0, *)
struct CardDetailsView: View {
    // MARK: - Properties

    /// The card form scope for handling updates
    let cardFormScope: any PrimerCardFormScope

    /// Currently detected card network
    @State private var cardNetwork: CardNetwork = .unknown

    @Environment(\.designTokens) private var tokens

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Card Number
            CardNumberInputField(
                label: CheckoutComponentsStrings.cardNumberLabel,
                placeholder: CheckoutComponentsStrings.cardNumberPlaceholder,
                scope: cardFormScope
            )

            // Card number and CVV in horizontal layout
            HStack(spacing: 16) {
                // Expiry Date
                ExpiryDateInputField(
                    label: CheckoutComponentsStrings.expiryDateLabel,
                    placeholder: CheckoutComponentsStrings.expiryDatePlaceholder,
                    scope: cardFormScope
                )

                // CVV
                CVVInputField(
                    label: CheckoutComponentsStrings.cvvLabel,
                    placeholder: cardNetwork.validation?.code.name ?? CheckoutComponentsStrings.cvvPlaceholder,
                    scope: cardFormScope,
                    cardNetwork: cardNetwork
                )
                .frame(maxWidth: 120)
            }

            // Cardholder Name
            CardholderNameInputField(
                label: CheckoutComponentsStrings.cardholderNameLabel,
                placeholder: CheckoutComponentsStrings.cardholderNamePlaceholder,
                scope: cardFormScope
            )
        }
    }
}
