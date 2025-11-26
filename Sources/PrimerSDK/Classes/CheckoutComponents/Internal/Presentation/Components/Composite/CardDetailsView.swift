//
//  CardDetailsView.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct CardDetailsView: View {
    // MARK: - Properties

    let cardFormScope: any PrimerCardFormScope
    @State private var cardNetwork: CardNetwork = .unknown

    @Environment(\.designTokens) private var tokens

    // MARK: - Body

    var body: some View {
        VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
            // Card Number
            CardNumberInputField(
                label: CheckoutComponentsStrings.cardNumberLabel,
                placeholder: CheckoutComponentsStrings.cardNumberPlaceholder,
                scope: cardFormScope
            )

            // Card number and CVV in horizontal layout
            HStack(spacing: PrimerSpacing.large(tokens: tokens)) {
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
                .frame(maxWidth: PrimerComponentWidth.cvvFieldMax)
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
