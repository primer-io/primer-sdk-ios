//
//  CardFormScreen.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length
// TODO: Refactor CardFormScreen to reduce file length (currently 814 lines, max 800)

import SwiftUI

/// Default card form screen for CheckoutComponents with dynamic field rendering
@available(iOS 15.0, *)
struct CardFormScreen: View, LogReporter {
    let scope: any PrimerCardFormScope

    @Environment(\.designTokens) private var tokens
    @Environment(\.bridgeController) private var bridgeController
    @Environment(\.diContainer) private var container
    @Environment(\.sizeCategory) private var sizeCategory // Observes Dynamic Type changes
    @State private var cardFormState: StructuredCardFormState = .init()
    @State private var selectedCardNetwork: CardNetwork = .unknown
    @State private var refreshTrigger = UUID()
    @State private var formConfiguration: CardFormConfiguration = .default
    @State private var configurationService: ConfigurationService?
    @FocusState private var focusedField: PrimerInputElementType?

    var body: some View {
        ScrollView {
            VStack(spacing: PrimerSpacing.xxlarge(tokens: tokens)) {
                headerSection
                formContent
            }
            .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
            .padding(.vertical, PrimerSpacing.large(tokens: tokens))
            .frame(maxWidth: UIScreen.main.bounds.width)
        }
        .navigationBarHidden(true)
        .background(CheckoutColors.background(tokens: tokens))
        .environment(\.primerCardFormScope, scope)
    }

    @MainActor
    private var headerSection: some View {
        VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
            HStack {
                if scope.presentationContext.shouldShowBackButton {
                    Button(action: {
                        scope.onBack()
                    }, label: {
                        HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
                            Image(systemName: "chevron.left")
                                .font(PrimerFont.bodyMedium(tokens: tokens))
                            Text(CheckoutComponentsStrings.backButton)
                        }
                        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
                    })
                    .accessibility(config: AccessibilityConfiguration(
                        identifier: AccessibilityIdentifiers.Common.backButton,
                        label: CheckoutComponentsStrings.a11yBack,
                        traits: [.isButton]
                    ))
                }

                Spacer()

                if scope.dismissalMechanism.contains(.closeButton) {
                    Button(CheckoutComponentsStrings.cancelButton, action: {
                        scope.onCancel()
                    })
                    .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
                    .accessibility(config: AccessibilityConfiguration(
                        identifier: AccessibilityIdentifiers.Common.closeButton,
                        label: CheckoutComponentsStrings.a11yCancel,
                        traits: [.isButton]
                    ))
                }
            }

            titleSection
        }
    }

    @MainActor
    private var formContent: some View {
        VStack(spacing: PrimerSpacing.xlarge(tokens: tokens)) {
            dynamicFieldsSection
            submitButtonSection
        }
        .onAppear {
            resolveConfigurationService()
            observeState()
        }
    }

    private var titleSection: some View {
        let title = scope.title ?? CheckoutComponentsStrings.cardPaymentTitle
        return Text(title)
            .font(PrimerFont.titleXLarge(tokens: tokens))
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    @MainActor
    @ViewBuilder
    private var dynamicFieldsSection: some View {
        // Check scope configuration for custom screen
        if let customScreen = scope.screen {
            AnyView(customScreen(scope))
        } else {
            VStack(spacing: 0) {
                cardFieldsSection
                billingAddressSection
            }
        }
    }

    @MainActor
    @ViewBuilder
    private var cardFieldsSection: some View {
        // Check scope configuration for full section replacement
        if let customContent = scope.cardInputSection {
            AnyView(customContent())
        } else {
            VStack(spacing: 0) {
                ForEach(0 ..< formConfiguration.cardFields.count, id: \.self) { index in
                    let fieldType = formConfiguration.cardFields[index]

                    if fieldType == .expiryDate,
                       index + 1 < formConfiguration.cardFields.count,
                       formConfiguration.cardFields[index + 1] == .cvv {
                        HStack(alignment: .top, spacing: PrimerSpacing.medium(tokens: tokens)) {
                            renderField(.expiryDate)
                            renderField(.cvv)
                        }
                    } else if index > 0,
                              formConfiguration.cardFields[index - 1] == .expiryDate,
                              fieldType == .cvv {
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
    }

    @ViewBuilder
    @MainActor
    private var billingAddressSection: some View {
        if !formConfiguration.billingFields.isEmpty {
            // Check scope configuration for full section replacement
            if let customContent = scope.billingAddressSection {
                AnyView(customContent())
            } else {
                VStack(alignment: .leading, spacing: PrimerSpacing.small(tokens: tokens)) {
                    Text(CheckoutComponentsStrings.billingAddressTitle)
                        .font(PrimerFont.headline(tokens: tokens))
                        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))

                    VStack(spacing: 0) {
                        ForEach(0 ..< formConfiguration.billingFields.count, id: \.self) { index in
                            let fieldType = formConfiguration.billingFields[index]

                            if fieldType == .firstName,
                               index + 1 < formConfiguration.billingFields.count,
                               formConfiguration.billingFields[index + 1] == .lastName {
                                HStack(alignment: .top, spacing: PrimerSpacing.medium(tokens: tokens)) {
                                    renderField(.firstName)
                                    renderField(.lastName)
                                }
                            } else if index > 0,
                                      formConfiguration.billingFields[index - 1] == .firstName,
                                      fieldType == .lastName {
                                EmptyView()
                            } else {
                                renderField(fieldType)
                            }
                        }
                    }
                }
            }
        }
    }

    @MainActor
    @ViewBuilder
    private var submitButtonSection: some View {
        // Check scope configuration for full button replacement
        if let customContent = scope.submitButtonSection {
            AnyView(customContent())
                .onTapGesture {
                    if cardFormState.isValid, !cardFormState.isLoading {
                        submitAction()
                    }
                }
        } else {
            Button(action: submitAction) {
                submitButtonContent
            }
            .disabled(!cardFormState.isValid || cardFormState.isLoading)
        }
    }

    private var submitButtonContent: some View {
        let isEnabled = cardFormState.isValid && !cardFormState.isLoading

        return HStack {
            if cardFormState.isLoading, scope.showSubmitLoadingIndicator {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: CheckoutColors.white(tokens: tokens)))
                    .scaleEffect(PrimerScale.small)
            } else {
                Text(submitButtonText)
            }
        }
        .font(PrimerFont.body(tokens: tokens))
        .foregroundColor(CheckoutColors.white(tokens: tokens))
        .frame(maxWidth: .infinity)
        .padding(.vertical, PrimerSpacing.large(tokens: tokens))
        .background(submitButtonBackground)
        .cornerRadius(PrimerRadius.small(tokens: tokens))
        .accessibility(config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.Common.submitButton,
            label: cardFormState.isLoading ? CheckoutComponentsStrings.a11ySubmitButtonLoading : submitButtonAccessibilityLabel,
            hint: cardFormState.isLoading ? nil : (isEnabled ? CheckoutComponentsStrings.a11ySubmitButtonHint :
                CheckoutComponentsStrings.a11ySubmitButtonDisabled),
            traits: [.isButton]
        ))
    }

    /// Accessibility-friendly version of submit button text for VoiceOver.
    /// Uses period as decimal separator to avoid misreading "6,00€" as "600 euros".
    private var submitButtonAccessibilityLabel: String {
        if scope.cardFormUIOptions?.payButtonAddNewCard == true {
            return CheckoutComponentsStrings.addCardButton
        }

        guard PrimerInternal.shared.intent == .checkout,
              let currency = configurationService?.currency
        else {
            return CheckoutComponentsStrings.payButton
        }

        let amount = configurationService?.amount ?? 0
        let merchantAmount = configurationService?.apiConfiguration?.clientSession?.order?.merchantAmount

        if let merchantAmount = merchantAmount,
           let surchargeRaw = cardFormState.surchargeAmountRaw,
           cardFormState.selectedNetwork != nil {
            let totalAmount = merchantAmount + surchargeRaw
            let accessibilityAmount = totalAmount.toAccessibilityCurrencyString(currency: currency)
            return "Pay with \(accessibilityAmount)"
        }

        let accessibilityAmount = amount.toAccessibilityCurrencyString(currency: currency)
        return "Pay with \(accessibilityAmount)"
    }

    private var submitButtonText: String {
        // First check scope configuration
        if let customText = scope.submitButtonText {
            return customText
        }

        if scope.cardFormUIOptions?.payButtonAddNewCard == true {
            return CheckoutComponentsStrings.addCardButton
        }

        guard PrimerInternal.shared.intent == .checkout,
              let currency = configurationService?.currency
        else {
            return CheckoutComponentsStrings.payButton
        }

        let amount = configurationService?.amount ?? 0
        let merchantAmount = configurationService?.apiConfiguration?.clientSession?.order?.merchantAmount

        if let merchantAmount = merchantAmount,
           let surchargeRaw = cardFormState.surchargeAmountRaw,
           cardFormState.selectedNetwork != nil {
            let totalAmount = merchantAmount + surchargeRaw
            let formattedTotalAmount = totalAmount.toCurrencyString(currency: currency)
            return CheckoutComponentsStrings.paymentAmountTitle(formattedTotalAmount)
        }

        let formattedAmount = amount.toCurrencyString(currency: currency)
        return CheckoutComponentsStrings.paymentAmountTitle(formattedAmount)
    }

    private var submitButtonBackground: Color {
        cardFormState.isValid && !cardFormState.isLoading
            ? CheckoutColors.textPrimary(tokens: tokens)
            : CheckoutColors.gray300(tokens: tokens)
    }

    private func submitAction() {
        Task {
            await (scope as? DefaultCardFormScope)?.submit()
        }
    }

    private func resolveConfigurationService() {
        guard let container else {
            return logger.error(message: "DIContainer not available for CardFormScreen")
        }
        do {
            configurationService = try container.resolveSync(ConfigurationService.self)
        } catch {
            logger.error(message: "Failed to resolve ConfigurationService: \(error)")
        }
    }

    private func observeState() {
        Task {
            await MainActor.run {
                formConfiguration = scope.getFormConfiguration()
                bridgeController?.invalidateContentSize()
            }

            for await state in scope.state {
                let updatedFormConfig = await MainActor.run {
                    scope.getFormConfiguration()
                }

                await MainActor.run {
                    cardFormState = state
                    refreshTrigger = UUID()

                    formConfiguration = updatedFormConfig

                    if let selectedNetwork = state.selectedNetwork {
                        selectedCardNetwork = selectedNetwork.network
                    } else if state.availableNetworks.count == 1,
                              let firstNetwork = state.availableNetworks.first {
                        selectedCardNetwork = firstNetwork.network
                    } else if state.availableNetworks.count > 1 {
                        if let firstNetwork = state.availableNetworks.first,
                           selectedCardNetwork == .unknown {
                            selectedCardNetwork = firstNetwork.network
                        }
                    }
                }
            }
        }
    }

    // MARK: - Dynamic Field Rendering

    // swiftlint:disable cyclomatic_complexity function_body_length
    @MainActor
    @ViewBuilder
    private func renderField(_ fieldType: PrimerInputElementType) -> some View {
        switch fieldType {
        case .cardNumber:
            let config = scope.cardNumberConfig
            if let customComponent = config?.component {
                AnyView(customComponent())
                    .focused($focusedField, equals: .cardNumber)
            } else {
                CardNumberInputField(
                    label: config?.label ?? CheckoutComponentsStrings.cardNumberLabel,
                    placeholder: config?.placeholder ?? CheckoutComponentsStrings.cardNumberPlaceholder,
                    scope: scope,
                    selectedNetwork: getSelectedCardNetwork(),
                    availableNetworks: cardFormState.availableNetworks.map(\.network),
                    styling: config?.styling
                )
                .focused($focusedField, equals: .cardNumber)
                .onSubmit { moveToNextField(from: .cardNumber) }
            }

        case .expiryDate:
            let config = scope.expiryDateConfig
            if let customComponent = config?.component {
                AnyView(customComponent())
                    .focused($focusedField, equals: .expiryDate)
            } else {
                ExpiryDateInputField(
                    label: config?.label ?? CheckoutComponentsStrings.expiryDateLabel,
                    placeholder: config?.placeholder ?? CheckoutComponentsStrings.expiryDatePlaceholder,
                    scope: scope,
                    styling: config?.styling
                )
                .focused($focusedField, equals: .expiryDate)
                .onSubmit { moveToNextField(from: .expiryDate) }
            }

        case .cvv:
            let config = scope.cvvConfig
            let defaultPlaceholder = getCardNetworkForCvv() == .amex
                ? CheckoutComponentsStrings.cvvAmexPlaceholder
                : CheckoutComponentsStrings.cvvStandardPlaceholder
            if let customComponent = config?.component {
                AnyView(customComponent())
                    .focused($focusedField, equals: .cvv)
            } else {
                CVVInputField(
                    label: config?.label ?? CheckoutComponentsStrings.cvvLabel,
                    placeholder: config?.placeholder ?? defaultPlaceholder,
                    scope: scope,
                    cardNetwork: getCardNetworkForCvv(),
                    styling: config?.styling
                )
                .focused($focusedField, equals: .cvv)
                .onSubmit { moveToNextField(from: .cvv) }
            }

        case .cardholderName:
            let config = scope.cardholderNameConfig
            if let customComponent = config?.component {
                AnyView(customComponent())
                    .focused($focusedField, equals: .cardholderName)
            } else {
                CardholderNameInputField(
                    label: config?.label ?? CheckoutComponentsStrings.cardholderNameLabel,
                    placeholder: config?.placeholder ?? CheckoutComponentsStrings.fullNamePlaceholder,
                    scope: scope,
                    styling: config?.styling
                )
                .focused($focusedField, equals: .cardholderName)
                .onSubmit { moveToNextField(from: .cardholderName) }
            }

        case .postalCode:
            let config = scope.postalCodeConfig
            if let customComponent = config?.component {
                AnyView(customComponent())
                    .focused($focusedField, equals: .postalCode)
            } else {
                PostalCodeInputField(
                    label: config?.label ?? CheckoutComponentsStrings.postalCodeLabel,
                    placeholder: config?.placeholder ?? CheckoutComponentsStrings.postalCodePlaceholder,
                    scope: scope,
                    styling: config?.styling
                )
                .focused($focusedField, equals: .postalCode)
                .onSubmit { moveToNextField(from: .postalCode) }
            }

        case .countryCode:
            let config = scope.countryConfig
            if let customComponent = config?.component {
                AnyView(customComponent())
                    .focused($focusedField, equals: .countryCode)
            } else if let defaultCardFormScope = scope as? DefaultCardFormScope {
                CountryInputField(
                    label: config?.label ?? CheckoutComponentsStrings.countryLabel,
                    placeholder: config?.placeholder ?? CheckoutComponentsStrings.selectCountryPlaceholder,
                    scope: defaultCardFormScope,
                    styling: config?.styling
                )
                .focused($focusedField, equals: .countryCode)
                .onSubmit { moveToNextField(from: .countryCode) }
            }

        case .city:
            let config = scope.cityConfig
            if let customComponent = config?.component {
                AnyView(customComponent())
                    .focused($focusedField, equals: .city)
            } else {
                CityInputField(
                    label: config?.label ?? CheckoutComponentsStrings.cityLabel,
                    placeholder: config?.placeholder ?? CheckoutComponentsStrings.cityPlaceholder,
                    scope: scope,
                    styling: config?.styling
                )
                .focused($focusedField, equals: .city)
                .onSubmit { moveToNextField(from: .city) }
            }

        case .state:
            let config = scope.stateConfig
            if let customComponent = config?.component {
                AnyView(customComponent())
            } else {
                StateInputField(
                    label: config?.label ?? CheckoutComponentsStrings.stateLabel,
                    placeholder: config?.placeholder ?? CheckoutComponentsStrings.statePlaceholder,
                    scope: scope,
                    styling: config?.styling
                )
            }

        case .addressLine1:
            let config = scope.addressLine1Config
            if let customComponent = config?.component {
                AnyView(customComponent())
            } else {
                AddressLineInputField(
                    label: config?.label ?? CheckoutComponentsStrings.addressLine1Label,
                    placeholder: config?.placeholder ?? CheckoutComponentsStrings.addressLine1Placeholder,
                    isRequired: true,
                    inputType: .addressLine1,
                    scope: scope,
                    styling: config?.styling
                )
            }

        case .addressLine2:
            let config = scope.addressLine2Config
            if let customComponent = config?.component {
                AnyView(customComponent())
            } else {
                AddressLineInputField(
                    label: config?.label ?? CheckoutComponentsStrings.addressLine2Label,
                    placeholder: config?.placeholder ?? CheckoutComponentsStrings.addressLine2Placeholder,
                    isRequired: false,
                    inputType: .addressLine2,
                    scope: scope,
                    styling: config?.styling
                )
            }

        case .phoneNumber:
            let config = scope.phoneNumberConfig
            if let customComponent = config?.component {
                AnyView(customComponent())
            } else {
                NameInputField(
                    label: config?.label ?? CheckoutComponentsStrings.phoneNumberLabel,
                    placeholder: config?.placeholder ?? CheckoutComponentsStrings.phoneNumberPlaceholder,
                    inputType: .phoneNumber,
                    scope: scope,
                    styling: config?.styling
                )
            }

        case .firstName:
            let config = scope.firstNameConfig
            if let customComponent = config?.component {
                AnyView(customComponent())
            } else {
                NameInputField(
                    label: config?.label ?? CheckoutComponentsStrings.firstNameLabel,
                    placeholder: config?.placeholder ?? CheckoutComponentsStrings.firstNamePlaceholder,
                    inputType: .firstName,
                    scope: scope,
                    styling: config?.styling
                )
            }

        case .lastName:
            let config = scope.lastNameConfig
            if let customComponent = config?.component {
                AnyView(customComponent())
            } else {
                NameInputField(
                    label: config?.label ?? CheckoutComponentsStrings.lastNameLabel,
                    placeholder: config?.placeholder ?? CheckoutComponentsStrings.lastNamePlaceholder,
                    inputType: .lastName,
                    scope: scope,
                    styling: config?.styling
                )
            }

        case .email:
            let config = scope.emailConfig
            if let customComponent = config?.component {
                AnyView(customComponent())
            } else {
                EmailInputField(
                    label: config?.label ?? CheckoutComponentsStrings.emailLabel,
                    placeholder: config?.placeholder ?? CheckoutComponentsStrings.emailPlaceholder,
                    scope: scope,
                    styling: config?.styling
                )
            }

        case .retailer:
            let config = scope.retailOutletConfig
            if let customComponent = config?.component {
                AnyView(customComponent())
            } else {
                Text(CheckoutComponentsStrings.retailOutletNotImplemented)
                    .font(PrimerFont.caption(tokens: tokens))
                    .foregroundColor(CheckoutColors.gray(tokens: tokens))
                    .padding(PrimerSpacing.large(tokens: tokens))
            }

        case .otp:
            let config = scope.otpCodeConfig
            if let customComponent = config?.component {
                AnyView(customComponent())
            } else {
                OTPCodeInputField(
                    label: CheckoutComponentsStrings.otpLabel,
                    placeholder: config?.placeholder ?? CheckoutComponentsStrings.otpCodeNumericPlaceholder,
                    scope: scope,
                    styling: config?.styling
                )
            }

        case .unknown, .all:
            EmptyView()
        }
    }

    // swiftlint:enable cyclomatic_complexity function_body_length

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

    /// Moves keyboard focus to the next field in logical order
    /// cardNumber → expiry → cvv → cardholderName → submit
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

    /// Moves focus to the first field with a validation error.
    ///
    /// **Important**: Only call in response to explicit user actions (form submission, navigation request).
    /// DO NOT call automatically during typing as it creates an accessibility trap.
    private func moveFocusToFirstError() {
        for field in formConfiguration.cardFields where cardFormState.hasError(for: field) {
            focusedField = field
            return
        }

        for field in formConfiguration.billingFields where cardFormState.hasError(for: field) {
            focusedField = field
            return
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 15.0, *)
#Preview("All Fields - Light") {
    CardFormScreen(scope: MockCardFormScope(
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
                .otp
            ]
        )
    ))
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
}

@available(iOS 15.0, *)
#Preview("All Fields - Dark") {
    CardFormScreen(scope: MockCardFormScope(
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
                .otp
            ]
        )
    ))
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
}

@available(iOS 15.0, *)
#Preview("Card Fields Only - Light") {
    CardFormScreen(scope: MockCardFormScope(
        selectedNetwork: .amex,
        formConfiguration: CardFormConfiguration(
            cardFields: [.cardNumber, .expiryDate, .cvv, .cardholderName],
            billingFields: []
        )
    ))
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
}

@available(iOS 15.0, *)
#Preview("Card Fields Only - Dark") {
    CardFormScreen(scope: MockCardFormScope(
        selectedNetwork: .discover,
        formConfiguration: CardFormConfiguration(
            cardFields: [.cardNumber, .expiryDate, .cvv, .cardholderName],
            billingFields: []
        )
    ))
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
}

@available(iOS 15.0, *)
#Preview("Co-badged Cards - Light") {
    CardFormScreen(scope: MockCardFormScope(
        selectedNetwork: .visa,
        availableNetworks: [.visa, .masterCard, .discover],
        formConfiguration: CardFormConfiguration(
            cardFields: [.cardNumber, .expiryDate, .cvv],
            billingFields: []
        )
    ))
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
}

@available(iOS 15.0, *)
#Preview("Co-badged Cards - Dark") {
    CardFormScreen(scope: MockCardFormScope(
        selectedNetwork: .visa,
        availableNetworks: [.visa, .masterCard, .discover],
        formConfiguration: CardFormConfiguration(
            cardFields: [.cardNumber, .expiryDate, .cvv],
            billingFields: []
        )
    ))
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
}

@available(iOS 15.0, *)
#Preview("Loading State") {
    CardFormScreen(scope: MockCardFormScope(
        isLoading: true,
        isValid: true,
        formConfiguration: CardFormConfiguration(
            cardFields: [.cardNumber, .expiryDate, .cvv, .cardholderName],
            billingFields: []
        )
    ))
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
}

@available(iOS 15.0, *)
#Preview("Valid State") {
    CardFormScreen(scope: MockCardFormScope(
        isLoading: false,
        isValid: true,
        formConfiguration: CardFormConfiguration(
            cardFields: [.cardNumber, .expiryDate, .cvv, .cardholderName],
            billingFields: []
        )
    ))
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
}

@available(iOS 15.0, *)
#Preview("With Billing Address - Light") {
    CardFormScreen(scope: MockCardFormScope(
        selectedNetwork: .masterCard,
        formConfiguration: CardFormConfiguration(
            cardFields: [.cardNumber, .expiryDate, .cvv],
            billingFields: [.countryCode, .addressLine1, .city, .state, .postalCode]
        )
    ))
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
}

@available(iOS 15.0, *)
#Preview("With Billing Address - Dark") {
    CardFormScreen(scope: MockCardFormScope(
        selectedNetwork: .jcb,
        formConfiguration: CardFormConfiguration(
            cardFields: [.cardNumber, .expiryDate, .cvv],
            billingFields: [.countryCode, .addressLine1, .city, .state, .postalCode]
        )
    ))
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
}

@available(iOS 15.0, *)
#Preview("With Surcharge") {
    CardFormScreen(scope: MockCardFormScope(
        isValid: true,
        selectedNetwork: .visa,
        surchargeAmount: "+ 1.50€",
        formConfiguration: CardFormConfiguration(
            cardFields: [.cardNumber, .expiryDate, .cvv],
            billingFields: []
        )
    ))
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
}
#endif
// swiftlint:enable file_length
