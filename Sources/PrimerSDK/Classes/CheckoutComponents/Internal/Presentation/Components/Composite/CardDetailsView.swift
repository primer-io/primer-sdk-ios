//
//  CardDetailsView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct CardDetailsView: View {
  let cardFormScope: any CardFormFieldScopeInternal
  @State private var cardNetwork: CardNetwork = .unknown

  @Environment(\.designTokens) private var tokens

  var body: some View {
    VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
      CardNumberInputField(
        label: CheckoutComponentsStrings.cardNumberLabel,
        placeholder: CheckoutComponentsStrings.cardNumberPlaceholder,
        scope: cardFormScope
      )

      HStack(spacing: PrimerSpacing.large(tokens: tokens)) {
        ExpiryDateInputField(
          label: CheckoutComponentsStrings.expiryDateLabel,
          placeholder: CheckoutComponentsStrings.expiryDatePlaceholder,
          scope: cardFormScope
        )

        CVVInputField(
          label: CheckoutComponentsStrings.cvvLabel,
          placeholder: cardNetwork.validation?.code.name
            ?? CheckoutComponentsStrings.cvvPlaceholder,
          scope: cardFormScope,
          cardNetwork: cardNetwork
        )
        .frame(maxWidth: PrimerComponentWidth.cvvFieldMax)
      }

      CardholderNameInputField(
        label: CheckoutComponentsStrings.cardholderNameLabel,
        placeholder: CheckoutComponentsStrings.cardholderNamePlaceholder,
        scope: cardFormScope
      )
    }
  }
}
