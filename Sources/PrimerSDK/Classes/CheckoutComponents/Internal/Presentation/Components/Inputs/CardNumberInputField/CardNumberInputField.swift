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
    let styling: PrimerFieldStyling?

    // MARK: - Private Properties

    @State private var validationService: ValidationService?
    @State private var cardNumber: String = ""
    @State private var isValid: Bool = false
    @State private var cardNetwork: CardNetwork = .unknown
    @State private var errorMessage: String?
    @State private var surchargeAmount: String?
    @State private var isFocused: Bool = false
    @Environment(\.diContainer) private var container
    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    init(
        label: String?,
        placeholder: String,
        scope: any PrimerCardFormScope,
        selectedNetwork: CardNetwork? = nil,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.scope = scope
        self.selectedNetwork = selectedNetwork
        self.styling = styling
    }

    private var displayNetwork: CardNetwork {
        return selectedNetwork ?? cardNetwork
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
                    if displayNetwork != .unknown {
                        CardNetworkBadge(network: displayNetwork)
                    }

                    if let surchargeAmount {
                        Text(surchargeAmount)
                            .font(PrimerFont.bodySmall(tokens: tokens))
                            .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
                            .padding(.horizontal, PrimerSpacing.xsmall(tokens: tokens))
                            .padding(.vertical, 1)
                            .background(CheckoutColors.gray200(tokens: tokens))
                            .cornerRadius(PrimerRadius.xsmall(tokens: tokens))
                    }
                }
            }
        )
        .onAppear {
            setupValidationService()
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
