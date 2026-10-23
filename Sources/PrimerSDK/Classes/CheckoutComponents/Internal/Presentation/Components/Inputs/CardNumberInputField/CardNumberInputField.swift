//
//  CardNumberInputField.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

@available(iOS 15.0, *)
struct CardNumberInputField: View, LogReporter {
  let label: String?
  let placeholder: String
  let scope: any CardFormFieldScopeInternal
  let selectedNetwork: CardNetwork?
  let availableNetworks: [CardNetwork]
  let surchargeAmount: String?

  // MARK: - Private Properties

  @State private var validationService: ValidationService?
  @State private var cardNumber: String = ""
  @State private var isValid: Bool = false
  @State private var cardNetwork: CardNetwork = .unknown
  @State private var errorMessage: String?
  @State private var isFocused: Bool = false
  @State private var localSelectedNetwork: CardNetwork = .unknown
  @State private var networkSelectorStyle: CardNetworkSelectorStyle = .dropdown
  @Environment(\.diContainer) private var container
  @Environment(\.designTokens) private var tokens

  // MARK: - Initialization

  init(
    label: String?,
    placeholder: String,
    scope: any CardFormFieldScopeInternal,
    selectedNetwork: CardNetwork? = nil,
    availableNetworks: [CardNetwork] = [],
    surchargeAmount: String? = nil
  ) {
    self.label = label
    self.placeholder = placeholder
    self.scope = scope
    self.selectedNetwork = selectedNetwork
    self.availableNetworks = availableNetworks
    self.surchargeAmount = surchargeAmount
  }

  private var displayNetwork: CardNetwork {
    selectedNetwork ?? cardNetwork
  }

  // MARK: - Body

  var body: some View {
    PrimerInputFieldContainer(
      label: label,
      text: $cardNumber,
      isValid: $isValid,
      errorMessage: $errorMessage,
      isFocused: $isFocused,
      textFieldBuilder: {
        if let validationService {
          CardNumberTextField(
            cardNumber: $cardNumber,
            isValid: $isValid,
            cardNetwork: $cardNetwork,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            scope: scope,
            placeholder: placeholder,
            validationService: validationService,
            tokens: tokens,
            accessibility: accessibilityConfig
          )
        } else {
          TextField(placeholder, text: .constant(""))
            .disabled(true)
        }
      },
      rightComponent: {
        HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
          if let surchargeAmount {
            Text(surchargeAmount)
              .primerTypography(.caption, tokens: tokens)
              .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
              .padding(.horizontal, PrimerSpacing.xsmall(tokens: tokens))
              .padding(.vertical, 2)
              .background(CheckoutColors.backgroundSecondary(tokens: tokens))
              .cornerRadius(PrimerRadius.xsmall(tokens: tokens))
              .frame(minHeight: PrimerSize.small(tokens: tokens))
          }

          if availableNetworks.count > 1 {
            if availableNetworks.contains(where: { !$0.allowsUserSelection }) {
              DualBadgeDisplay(networks: availableNetworks)
            } else {
              switch networkSelectorStyle {
              case .dropdown:
                DropdownCardNetworkSelector(
                  availableNetworks: availableNetworks,
                  selectedNetwork: $localSelectedNetwork,
                  onNetworkSelected: { network in
                    scope.updateSelectedCardNetwork(network.rawValue)
                  }
                )
              case .inline:
                InlineCardNetworkSelector(
                  availableNetworks: availableNetworks,
                  selectedNetwork: $localSelectedNetwork,
                  onNetworkSelected: { network in
                    scope.updateSelectedCardNetwork(network.rawValue)
                  }
                )
              }
            }
          } else {
            CardNetworkBadge(network: displayNetwork)
          }
        }
      }
    )
    .accessibility(
      config: accessibilityConfig,
      combinesChildren: false
    )
    .programmaticValue(.cardNumber, from: scope, text: $cardNumber, isFocused: $isFocused)
    .onAppear {
      setupValidationService()
      localSelectedNetwork = displayNetwork
    }
    .onChange(of: selectedNetwork) { newNetwork in
      if let newNetwork {
        localSelectedNetwork = newNetwork
      }
    }
  }

  // MARK: - Private Methods

  private var accessibilityConfig: AccessibilityConfiguration {
    AccessibilityConfiguration(
      identifier: AccessibilityIdentifiers.CardForm.cardNumberField,
      label: CheckoutComponentsStrings.a11yCardNumberLabel,
      hint: CheckoutComponentsStrings.a11yCardNumberHint,
      value: errorMessage,
      traits: []
    )
  }

  private func setupValidationService() {
    guard let container else {
      return logger.error(message: "DIContainer not available for CardNumberInputField")
    }
    do {
      validationService = try container.resolveSync(ValidationService.self)
    } catch {
      logger.error(message: "Failed to resolve ValidationService: \(error)")
    }

    // Load network selector style from settings
    do {
      let settings = try container.resolveSync(PrimerSettings.self)
      networkSelectorStyle = settings.paymentMethodOptions.cardPaymentOptions.networkSelectorStyle
    } catch {
      logger.debug(message: "[A11Y] Using default network selector style: dropdown")
    }
  }
}

#if DEBUG
  @available(iOS 15.0, *)
  #Preview("Light Mode") {
    CardNumberInputField(
      label: "Card Number",
      placeholder: "1234 5678 9012 3456",
      scope: MockCardFormScope()
    )
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
  }

  @available(iOS 15.0, *)
  #Preview("Dark Mode") {
    CardNumberInputField(
      label: "Card Number",
      placeholder: "1234 5678 9012 3456",
      scope: MockCardFormScope()
    )
    .padding()
    .background(Color.black)
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
  }
#endif
