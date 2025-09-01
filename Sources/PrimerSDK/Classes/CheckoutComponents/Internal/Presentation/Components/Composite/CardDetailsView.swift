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
    let cardFormScope: any PrimerCardFormScope

    /// Currently detected card network
    @State private var cardNetwork: CardNetwork = .unknown

    @Environment(\.designTokens) private var tokens

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Card Number
            CardNumberInputField(
                label: "Card Number",
                placeholder: "1234 1234 1234 1234",
                scope: cardFormScope
            )

            // Card number and CVV in horizontal layout
            HStack(spacing: 16) {
                // Expiry Date
                ExpiryDateInputField(
                    label: "Expiry Date",
                    placeholder: "MM/YY",
                    scope: cardFormScope
                )

                // CVV
                CVVInputField(
                    label: "CVV",
                    placeholder: cardNetwork.validation?.code.name ?? "CVV",
                    scope: cardFormScope,
                    cardNetwork: cardNetwork
                )
                .frame(maxWidth: 120)
            }

            // Cardholder Name
            CardholderNameInputField(
                label: "Cardholder Name",
                placeholder: "John Doe",
                scope: cardFormScope
            )
        }
    }
}
