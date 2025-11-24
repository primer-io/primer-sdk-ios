//
//  CardNumberInputField.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct CardNumberInputField: View, LogReporter {
    // MARK: - Properties

    let label: String?
    let placeholder: String
    let scope: any PrimerCardFormScope
    let selectedNetwork: CardNetwork?
    let availableNetworks: [CardNetwork]
    let styling: PrimerFieldStyling?

    // MARK: - Private Properties

    @State private var validationService: ValidationService?
    @State private var cardNumber: String = ""
    @State private var isValid: Bool = false
    @State private var cardNetwork: CardNetwork = .unknown
    @State private var errorMessage: String?
    @State private var surchargeAmount: String?
    @State private var isFocused: Bool = false
    @State private var localSelectedNetwork: CardNetwork = .unknown
    @State private var networkSelectorStyle: CardNetworkSelectorStyle = .dropdown
    @Environment(\.diContainer) private var container
    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    init(
        label: String?,
        placeholder: String,
        scope: any PrimerCardFormScope,
        selectedNetwork: CardNetwork? = nil,
        availableNetworks: [CardNetwork] = [],
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.scope = scope
        self.selectedNetwork = selectedNetwork
        self.availableNetworks = availableNetworks
        self.styling = styling
    }

    private var displayNetwork: CardNetwork {
        selectedNetwork ?? cardNetwork
    }

    // MARK: - Body

    var body: some View {
        PrimerInputFieldContainer(
            label: label,
            styling: styling,
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
                        styling: styling,
                        validationService: validationService,
                        tokens: tokens
                    )
                } else {
                    TextField(placeholder, text: .constant(""))
                        .disabled(true)
                }
            },
            rightComponent: {
                VStack(spacing: PrimerSpacing.xxsmall(tokens: tokens)) {
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
                    } else if displayNetwork != .unknown {
                        CardNetworkBadge(network: displayNetwork)
                    }

                    if let surchargeAmount {
                        Text(surchargeAmount)
                            .font(PrimerFont.caption(tokens: tokens))
                            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
                            .padding(.horizontal, PrimerSpacing.xsmall(tokens: tokens))
                            .padding(.vertical, 2)
                            .background(CheckoutColors.gray200(tokens: tokens))
                            .cornerRadius(PrimerRadius.xsmall(tokens: tokens))
                            .frame(height: PrimerSize.small(tokens: tokens))
                    }

                    if displayNetwork != .unknown {
                        CardNetworkBadge(network: displayNetwork)
                    }
                }
            }
        )
        .accessibility(config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.CardForm.cardNumberField,
            label: CheckoutComponentsStrings.a11yCardNumberLabel,
            hint: CheckoutComponentsStrings.a11yCardNumberHint,
            value: errorMessage,
            traits: []
        ))
        .onAppear {
            setupValidationService()
            localSelectedNetwork = displayNetwork
        }
        .onChange(of: selectedNetwork) { newNetwork in
            if let newNetwork = newNetwork {
                localSelectedNetwork = newNetwork
            }
        }
        .onChange(of: cardNetwork) { newNetwork in
            updateSurchargeAmount(for: newNetwork)
        }
        .onChange(of: selectedNetwork) { newNetwork in
            if let newNetwork {
                updateSurchargeAmount(for: newNetwork)
            }
        }
    }

    // MARK: - Private Methods

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

    private func updateSurchargeAmount(for network: CardNetwork) {
        guard let surcharge = network.surcharge,
              PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.merchantAmount == nil,
              let currency = AppState.current.currency
        else {
            surchargeAmount = nil
            return
        }
        surchargeAmount = "+ \(surcharge.toCurrencyString(currency: currency))"
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
