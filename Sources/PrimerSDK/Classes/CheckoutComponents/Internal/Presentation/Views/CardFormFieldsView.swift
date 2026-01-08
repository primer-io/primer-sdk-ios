//
//  CardFormFieldsView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length

import SwiftUI

/// Reusable card form fields view that renders card input fields and billing address fields.
/// This component is used by both `CardFormScreen` (full screen) and `DefaultCardFormView` (embeddable).
///
/// Features:
/// - Dynamic card fields (card number, expiry, CVV, cardholder name)
/// - Allowed card networks view
/// - Co-badged cards selector (when multiple networks detected)
/// - Dynamic billing address fields (based on configuration)
@available(iOS 15.0, *)
struct CardFormFieldsView: View {
    let scope: any PrimerCardFormScope
    let styling: PrimerFieldStyling?

    @Environment(\.designTokens) private var tokens
    @State private var cardFormState: StructuredCardFormState = .init()
    @State private var selectedCardNetwork: CardNetwork = .unknown
    @State private var formConfiguration: CardFormConfiguration = .default
    @FocusState private var focusedField: PrimerInputElementType?

    var body: some View {
        VStack(spacing: 0) {
            cardFieldsSection
            billingAddressSection
        }
        .onAppear {
            formConfiguration = scope.getFormConfiguration()
            observeState()
        }
    }

    // MARK: - Card Fields Section

    @MainActor
    @ViewBuilder
    private var cardFieldsSection: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< formConfiguration.cardFields.count, id: \.self) { index in
                let fieldType = formConfiguration.cardFields[index]

                if fieldType == .expiryDate,
                   index + 1 < formConfiguration.cardFields.count,
                   formConfiguration.cardFields[index + 1] == .cvv
                {
                    HStack(alignment: .top, spacing: PrimerSpacing.medium(tokens: tokens)) {
                        renderField(.expiryDate)
                        renderField(.cvv)
                    }
                } else if index > 0,
                          formConfiguration.cardFields[index - 1] == .expiryDate,
                          fieldType == .cvv
                {
                    EmptyView()
                } else {
                    renderField(fieldType)
                }

                if fieldType == .cardNumber {
                    let allowedNetworks = [CardNetwork].allowedCardNetworks
                    let networksToShow = !allowedNetworks.isEmpty ? allowedNetworks : [.visa, .masterCard, .amex, .discover]
                    AllowedCardNetworksView(allowedCardNetworks: networksToShow)
                        .padding(.bottom, PrimerSpacing.medium(tokens: tokens))
                }
            }
        }
    }

    // MARK: - Billing Address Section

    @ViewBuilder
    @MainActor
    private var billingAddressSection: some View {
        if !formConfiguration.billingFields.isEmpty {
            VStack(alignment: .leading, spacing: PrimerSpacing.small(tokens: tokens)) {
                Text(CheckoutComponentsStrings.billingAddressTitle)
                    .font(PrimerFont.headline(tokens: tokens))
                    .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

                VStack(spacing: 0) {
                    ForEach(0 ..< formConfiguration.billingFields.count, id: \.self) { index in
                        let fieldType = formConfiguration.billingFields[index]

                        if fieldType == .firstName,
                           index + 1 < formConfiguration.billingFields.count,
                           formConfiguration.billingFields[index + 1] == .lastName
                        {
                            HStack(alignment: .top, spacing: PrimerSpacing.medium(tokens: tokens)) {
                                renderField(.firstName)
                                renderField(.lastName)
                            }
                        } else if index > 0,
                                  formConfiguration.billingFields[index - 1] == .firstName,
                                  fieldType == .lastName
                        {
                            EmptyView()
                        } else {
                            renderField(fieldType)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Dynamic Field Rendering

    @MainActor
    @ViewBuilder
    private func renderField(_ fieldType: PrimerInputElementType) -> some View {
        let fieldLabel: String? = fieldType.displayName

        switch fieldType {
        case .cardNumber:
            CardNumberInputField(
                label: fieldLabel ?? "Card Number",
                placeholder: CheckoutComponentsStrings.cardNumberPlaceholder,
                scope: scope,
                selectedNetwork: getSelectedCardNetwork(),
                availableNetworks: cardFormState.availableNetworks.map(\.network),
                styling: styling
            )
            .focused($focusedField, equals: .cardNumber)
            .onSubmit { moveToNextField(from: .cardNumber) }

        case .expiryDate:
            ExpiryDateInputField(
                label: fieldLabel ?? "",
                placeholder: CheckoutComponentsStrings.expiryDatePlaceholder,
                scope: scope,
                styling: styling
            )
            .focused($focusedField, equals: .expiryDate)
            .onSubmit { moveToNextField(from: .expiryDate) }

        case .cvv:
            CVVInputField(
                label: fieldLabel ?? "",
                placeholder: getCardNetworkForCvv() == .amex ? CheckoutComponentsStrings.cvvAmexPlaceholder : CheckoutComponentsStrings.cvvStandardPlaceholder,
                scope: scope,
                cardNetwork: getCardNetworkForCvv(),
                styling: styling
            )
            .focused($focusedField, equals: .cvv)
            .onSubmit { moveToNextField(from: .cvv) }

        case .cardholderName:
            CardholderNameInputField(
                label: fieldLabel ?? "",
                placeholder: CheckoutComponentsStrings.fullNamePlaceholder,
                scope: scope,
                styling: styling
            )
            .focused($focusedField, equals: .cardholderName)
            .onSubmit { moveToNextField(from: .cardholderName) }

        case .postalCode:
            PostalCodeInputField(
                label: fieldLabel ?? "",
                placeholder: CheckoutComponentsStrings.postalCodePlaceholder,
                scope: scope,
                styling: styling
            )
            .focused($focusedField, equals: .postalCode)
            .onSubmit { moveToNextField(from: .postalCode) }

        case .countryCode:
            if let defaultCardFormScope = scope as? DefaultCardFormScope {
                CountryInputField(
                    label: fieldLabel ?? "",
                    placeholder: CheckoutComponentsStrings.selectCountryPlaceholder,
                    scope: defaultCardFormScope,
                    styling: styling
                )
                .focused($focusedField, equals: .countryCode)
                .onSubmit { moveToNextField(from: .countryCode) }
            }

        case .city:
            CityInputField(
                label: fieldLabel ?? "",
                placeholder: CheckoutComponentsStrings.cityPlaceholder,
                scope: scope,
                styling: styling
            )
            .focused($focusedField, equals: .city)
            .onSubmit { moveToNextField(from: .city) }

        case .state:
            StateInputField(
                label: fieldLabel ?? "",
                placeholder: CheckoutComponentsStrings.statePlaceholder,
                scope: scope,
                styling: styling
            )

        case .addressLine1:
            AddressLineInputField(
                label: fieldLabel ?? "",
                placeholder: CheckoutComponentsStrings.addressLine1Placeholder,
                isRequired: true,
                inputType: .addressLine1,
                scope: scope,
                styling: styling
            )

        case .addressLine2:
            AddressLineInputField(
                label: fieldLabel ?? "",
                placeholder: CheckoutComponentsStrings.addressLine2Placeholder,
                isRequired: false,
                inputType: .addressLine2,
                scope: scope,
                styling: styling
            )

        case .phoneNumber:
            NameInputField(
                label: fieldLabel ?? "",
                placeholder: CheckoutComponentsStrings.phoneNumberPlaceholder,
                inputType: .phoneNumber,
                scope: scope,
                styling: styling
            )

        case .firstName:
            NameInputField(
                label: fieldLabel ?? "",
                placeholder: CheckoutComponentsStrings.firstNamePlaceholder,
                inputType: .firstName,
                scope: scope,
                styling: styling
            )

        case .lastName:
            NameInputField(
                label: fieldLabel ?? "",
                placeholder: CheckoutComponentsStrings.lastNamePlaceholder,
                inputType: .lastName,
                scope: scope,
                styling: styling
            )

        case .email:
            EmailInputField(
                label: fieldLabel ?? "",
                placeholder: CheckoutComponentsStrings.emailPlaceholder,
                scope: scope,
                styling: styling
            )

        case .retailer:
            Text(CheckoutComponentsStrings.retailOutletNotImplemented)
                .font(PrimerFont.caption(tokens: tokens))
                .foregroundColor(CheckoutColors.gray(tokens: tokens))
                .padding(PrimerSpacing.large(tokens: tokens))

        case .otp:
            OTPCodeInputField(
                label: fieldLabel ?? "",
                placeholder: CheckoutComponentsStrings.otpCodeNumericPlaceholder,
                scope: scope,
                styling: styling
            )

        case .unknown, .all:
            EmptyView()
        }
    }

    // MARK: - Helper Methods

    private func getSelectedCardNetwork() -> CardNetwork? {
        if let network = cardFormState.selectedNetwork {
            return network.network
        }
        return nil
    }

    private func getCardNetworkForCvv() -> CardNetwork {
        if let network = cardFormState.selectedNetwork {
            return network.network
        } else {
            let cardNumber: String? = nil
            return CardNetwork(cardNumber: cardNumber ?? "")
        }
    }

    // MARK: - Focus Management

    private func moveToNextField(from currentField: PrimerInputElementType) {
        let cardFields = formConfiguration.cardFields
        let billingFields = formConfiguration.billingFields

        if let currentIndex = cardFields.firstIndex(of: currentField) {
            if currentIndex + 1 < cardFields.count {
                focusedField = cardFields[currentIndex + 1]
                return
            }
            if !billingFields.isEmpty {
                focusedField = billingFields.first
                return
            }
            focusedField = nil
            return
        }

        if let currentIndex = billingFields.firstIndex(of: currentField) {
            if currentIndex + 1 < billingFields.count {
                focusedField = billingFields[currentIndex + 1]
                return
            }
            focusedField = nil
            return
        }

        focusedField = nil
    }

    // MARK: - State Observation

    private func observeState() {
        Task {
            await MainActor.run {
                formConfiguration = scope.getFormConfiguration()
            }

            for await state in scope.state {
                let updatedFormConfig = await MainActor.run {
                    scope.getFormConfiguration()
                }

                await MainActor.run {
                    cardFormState = state
                    formConfiguration = updatedFormConfig

                    if let selectedNetwork = state.selectedNetwork {
                        selectedCardNetwork = selectedNetwork.network
                    } else if state.availableNetworks.count == 1,
                              let firstNetwork = state.availableNetworks.first
                    {
                        selectedCardNetwork = firstNetwork.network
                    } else if state.availableNetworks.count > 1,
                              let firstNetwork = state.availableNetworks.first,
                              selectedCardNetwork == .unknown
                    {
                        selectedCardNetwork = firstNetwork.network
                    }
                }
            }
        }
    }
}

// swiftlint:enable file_length
// swiftlint:enable cyclomatic_complexity
// swiftlint:enable function_body_length
