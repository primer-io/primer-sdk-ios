//
//  CardFormScreen+Previews.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if DEBUG
  import SwiftUI

  @available(iOS 15.0, *)
  #Preview("All Fields - Light") {
    CardFormScreen(
      scope: MockCardFormScope(
        selectedNetwork: .visa,
        formConfiguration: CardFormConfiguration(
          cardFields: [.cardNumber, .expiryDate, .cvv, .cardholderName],
          billingFields: [
            .countryCode,
            .addressLine1,
            .addressLine2,
            .city,
            .state,
            .postalCode,
            .firstName,
            .lastName,
            .email,
            .phoneNumber,
            .otp,
          ]
        )
      )
    )
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
  }

  @available(iOS 15.0, *)
  #Preview("All Fields - Dark") {
    CardFormScreen(
      scope: MockCardFormScope(
        selectedNetwork: .masterCard,
        formConfiguration: CardFormConfiguration(
          cardFields: [.cardNumber, .expiryDate, .cvv, .cardholderName],
          billingFields: [
            .countryCode,
            .addressLine1,
            .addressLine2,
            .city,
            .state,
            .postalCode,
            .firstName,
            .lastName,
            .email,
            .phoneNumber,
            .otp,
          ]
        )
      )
    )
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
  }

  @available(iOS 15.0, *)
  #Preview("Card Fields Only - Light") {
    CardFormScreen(
      scope: MockCardFormScope(
        selectedNetwork: .amex,
        formConfiguration: CardFormConfiguration(
          cardFields: [.cardNumber, .expiryDate, .cvv, .cardholderName],
          billingFields: []
        )
      )
    )
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
  }

  @available(iOS 15.0, *)
  #Preview("Card Fields Only - Dark") {
    CardFormScreen(
      scope: MockCardFormScope(
        selectedNetwork: .discover,
        formConfiguration: CardFormConfiguration(
          cardFields: [.cardNumber, .expiryDate, .cvv, .cardholderName],
          billingFields: []
        )
      )
    )
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
  }

  @available(iOS 15.0, *)
  #Preview("Co-badged Cards - Light") {
    CardFormScreen(
      scope: MockCardFormScope(
        selectedNetwork: .visa,
        availableNetworks: [.visa, .masterCard, .discover],
        formConfiguration: CardFormConfiguration(
          cardFields: [.cardNumber, .expiryDate, .cvv],
          billingFields: []
        )
      )
    )
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
  }

  @available(iOS 15.0, *)
  #Preview("Co-badged Cards - Dark") {
    CardFormScreen(
      scope: MockCardFormScope(
        selectedNetwork: .visa,
        availableNetworks: [.visa, .masterCard, .discover],
        formConfiguration: CardFormConfiguration(
          cardFields: [.cardNumber, .expiryDate, .cvv],
          billingFields: []
        )
      )
    )
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
  }

  @available(iOS 15.0, *)
  #Preview("Loading State") {
    CardFormScreen(
      scope: MockCardFormScope(
        isLoading: true,
        isValid: true,
        formConfiguration: CardFormConfiguration(
          cardFields: [.cardNumber, .expiryDate, .cvv, .cardholderName],
          billingFields: []
        )
      )
    )
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
  }

  @available(iOS 15.0, *)
  #Preview("Valid State") {
    CardFormScreen(
      scope: MockCardFormScope(
        isLoading: false,
        isValid: true,
        formConfiguration: CardFormConfiguration(
          cardFields: [.cardNumber, .expiryDate, .cvv, .cardholderName],
          billingFields: []
        )
      )
    )
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
  }

  @available(iOS 15.0, *)
  #Preview("With Billing Address - Light") {
    CardFormScreen(
      scope: MockCardFormScope(
        selectedNetwork: .masterCard,
        formConfiguration: CardFormConfiguration(
          cardFields: [.cardNumber, .expiryDate, .cvv],
          billingFields: [.countryCode, .addressLine1, .city, .state, .postalCode]
        )
      )
    )
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
  }

  @available(iOS 15.0, *)
  #Preview("With Billing Address - Dark") {
    CardFormScreen(
      scope: MockCardFormScope(
        selectedNetwork: .jcb,
        formConfiguration: CardFormConfiguration(
          cardFields: [.cardNumber, .expiryDate, .cvv],
          billingFields: [.countryCode, .addressLine1, .city, .state, .postalCode]
        )
      )
    )
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
  }

  @available(iOS 15.0, *)
  #Preview("With Surcharge") {
    CardFormScreen(
      scope: MockCardFormScope(
        isValid: true,
        selectedNetwork: .visa,
        surchargeAmount: "+ 1.50€",
        formConfiguration: CardFormConfiguration(
          cardFields: [.cardNumber, .expiryDate, .cvv],
          billingFields: []
        )
      )
    )
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
  }
#endif
