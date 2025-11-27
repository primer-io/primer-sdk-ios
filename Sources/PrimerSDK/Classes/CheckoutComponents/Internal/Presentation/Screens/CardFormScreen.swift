//
//  CardFormScreen.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length
// TODO: Refactor CardFormScreen to reduce file length (currently 814 lines, max 800)
//
//  CardFormScreen.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

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
    @State private var components: PrimerComponents = PrimerComponents()

    /// CardForm configuration with fallback to defaults
    private var cardFormConfig: PrimerComponents.CardForm {
        components.configuration(for: PrimerComponents.CardForm.self) ?? PrimerComponents.CardForm()
    }
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
            resolveComponents()
            resolveConfigurationService()
            observeState()
        }
    }

    private var titleSection: some View {
        let title = cardFormConfig.title ?? CheckoutComponentsStrings.cardPaymentTitle
        return Text(title)
            .font(PrimerFont.titleXLarge(tokens: tokens))
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    @MainActor
    @ViewBuilder
    private var dynamicFieldsSection: some View {
        // First check components configuration
        if let customScreen = cardFormConfig.screen {
            AnyView(customScreen())
        }
        // Then check legacy scope configuration
        else if let customScreen = scope.screen {
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
        // First check components configuration
        if let customContent = cardFormConfig.cardDetails.content {
            AnyView(customContent())
        }
        // Then check legacy scope configuration
        else if let customSection = (scope as? DefaultCardFormScope)?.cardInputSection {
            AnyView(customSection())
        } else {
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
    }

    @ViewBuilder
    @MainActor
    private var billingAddressSection: some View {
        if !formConfiguration.billingFields.isEmpty,
           let defaultScope = scope as? DefaultCardFormScope
        {
            // First check components configuration
            if let customContent = cardFormConfig.billingAddress.content {
                AnyView(customContent())
            }
            // Then check legacy scope configuration
            else if let customSection = defaultScope.billingAddressSection {
                AnyView(customSection())
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
    }

    @MainActor
    @ViewBuilder
    private var submitButtonSection: some View {
        // First check components configuration
        if let customContent = cardFormConfig.submitButton.content {
            AnyView(customContent())
                .onTapGesture {
                    if cardFormState.isValid, !cardFormState.isLoading {
                        submitAction()
                    }
                }
        }
        // Then check legacy scope configuration
        else if let customSection = (scope as? DefaultCardFormScope)?.submitButtonSection {
            AnyView(customSection())
        } else {
            Group {
                if let customButton = (scope as? DefaultCardFormScope)?.submitButton {
                    AnyView(customButton(submitButtonText))
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
        }
    }

    private var submitButtonContent: some View {
        let isEnabled = cardFormState.isValid && !cardFormState.isLoading
        let showLoadingIndicator = cardFormConfig.submitButton.showLoadingIndicator

        return HStack {
            if cardFormState.isLoading, showLoadingIndicator {
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
           cardFormState.selectedNetwork != nil
        {
            let totalAmount = merchantAmount + surchargeRaw
            let accessibilityAmount = totalAmount.toAccessibilityCurrencyString(currency: currency)
            return "Pay with \(accessibilityAmount)"
        }

        let accessibilityAmount = amount.toAccessibilityCurrencyString(currency: currency)
        return "Pay with \(accessibilityAmount)"
    }

    private var submitButtonText: String {
        // First check components configuration
        if let customText = cardFormConfig.submitButton.text {
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
           cardFormState.selectedNetwork != nil
        {
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

    private func resolveComponents() {
        guard let container else {
            return logger.error(message: "DIContainer not available for CardFormScreen")
        }
        do {
            components = try container.resolveSync(PrimerComponents.self)
        } catch {
            logger.error(message: "Failed to resolve PrimerComponents: \(error)")
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
                              let firstNetwork = state.availableNetworks.first
                    {
                        selectedCardNetwork = firstNetwork.network
                    } else if state.availableNetworks.count > 1 {
                        if let firstNetwork = state.availableNetworks.first,
                           selectedCardNetwork == .unknown
                        {
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
        let fieldLabel: String? = fieldType.displayName
        let defaultStyling = (scope as? DefaultCardFormScope)?.defaultFieldStyling?[String(fieldType.rawValue)]

        switch fieldType {
        case .cardNumber:
            // First check components configuration
            if let customField = cardFormConfig.cardDetails.cardNumber {
                AnyView(customField())
                    .focused($focusedField, equals: .cardNumber)
            }
            // Then check legacy scope configuration
            else if let customField = (scope as? DefaultCardFormScope)?.cardNumberField {
                AnyView(customField(fieldLabel, defaultStyling))
                    .focused($focusedField, equals: .cardNumber)
            } else {
                CardNumberInputField(
                    label: fieldLabel ?? "Card Number",
                    placeholder: CheckoutComponentsStrings.cardNumberPlaceholder,
                    scope: scope,
                    selectedNetwork: getSelectedCardNetwork(),
                    availableNetworks: cardFormState.availableNetworks.map(\.network),
                    styling: defaultStyling
                )
                .focused($focusedField, equals: .cardNumber)
                .onSubmit { moveToNextField(from: .cardNumber) }
            }

        case .expiryDate:
            // First check components configuration
            if let customField = cardFormConfig.cardDetails.expiryDate {
                AnyView(customField())
                    .focused($focusedField, equals: .expiryDate)
            }
            // Then check legacy scope configuration
            else if let customField = (scope as? DefaultCardFormScope)?.expiryDateField {
                AnyView(customField(fieldLabel, defaultStyling))
                    .focused($focusedField, equals: .expiryDate)
            } else {
                ExpiryDateInputField(
                    label: fieldLabel ?? "",
                    placeholder: CheckoutComponentsStrings.expiryDatePlaceholder,
                    scope: scope,
                    styling: defaultStyling
                )
                .focused($focusedField, equals: .expiryDate)
                .onSubmit { moveToNextField(from: .expiryDate) }
            }

        case .cvv:
            // First check components configuration
            if let customField = cardFormConfig.cardDetails.cvv {
                AnyView(customField())
                    .focused($focusedField, equals: .cvv)
            }
            // Then check legacy scope configuration
            else if let customField = (scope as? DefaultCardFormScope)?.cvvField {
                AnyView(customField(fieldLabel, defaultStyling))
                    .focused($focusedField, equals: .cvv)
            } else {
                CVVInputField(
                    label: fieldLabel ?? "",
                    placeholder: getCardNetworkForCvv() == .amex ? CheckoutComponentsStrings.cvvAmexPlaceholder : CheckoutComponentsStrings.cvvStandardPlaceholder,
                    scope: scope,
                    cardNetwork: getCardNetworkForCvv(),
                    styling: defaultStyling
                )
                .focused($focusedField, equals: .cvv)
                .onSubmit { moveToNextField(from: .cvv) }
            }

        case .cardholderName:
            // First check components configuration
            if let customField = cardFormConfig.cardDetails.cardholderName {
                AnyView(customField())
                    .focused($focusedField, equals: .cardholderName)
            }
            // Then check legacy scope configuration
            else if let customField = (scope as? DefaultCardFormScope)?.cardholderNameField {
                AnyView(customField(fieldLabel, defaultStyling))
                    .focused($focusedField, equals: .cardholderName)
            } else {
                CardholderNameInputField(
                    label: fieldLabel ?? "",
                    placeholder: CheckoutComponentsStrings.fullNamePlaceholder,
                    scope: scope,
                    styling: defaultStyling
                )
                .focused($focusedField, equals: .cardholderName)
                .onSubmit { moveToNextField(from: .cardholderName) }
            }

        case .postalCode:
            // First check components configuration
            if let customField = cardFormConfig.billingAddress.postalCode {
                AnyView(customField())
                    .focused($focusedField, equals: .postalCode)
            }
            // Then check legacy scope configuration
            else if let customField = (scope as? DefaultCardFormScope)?.postalCodeField {
                AnyView(customField(fieldLabel, defaultStyling))
                    .focused($focusedField, equals: .postalCode)
            } else {
                PostalCodeInputField(
                    label: fieldLabel ?? "",
                    placeholder: CheckoutComponentsStrings.postalCodePlaceholder,
                    scope: scope,
                    styling: defaultStyling
                )
                .focused($focusedField, equals: .postalCode)
                .onSubmit { moveToNextField(from: .postalCode) }
            }

        case .countryCode:
            // First check components configuration
            if let customField = cardFormConfig.billingAddress.countryCode {
                AnyView(customField())
                    .focused($focusedField, equals: .countryCode)
            }
            // Then check legacy scope configuration
            else if let customField = (scope as? DefaultCardFormScope)?.countryField {
                AnyView(customField(fieldLabel, defaultStyling))
                    .focused($focusedField, equals: .countryCode)
            } else if let defaultCardFormScope = scope as? DefaultCardFormScope {
                CountryInputField(
                    label: fieldLabel ?? "",
                    placeholder: CheckoutComponentsStrings.selectCountryPlaceholder,
                    scope: defaultCardFormScope,
                    styling: defaultStyling
                )
                .focused($focusedField, equals: .countryCode)
                .onSubmit { moveToNextField(from: .countryCode) }
            }

        case .city:
            // First check components configuration
            if let customField = cardFormConfig.billingAddress.city {
                AnyView(customField())
                    .focused($focusedField, equals: .city)
            }
            // Then check legacy scope configuration
            else if let customField = (scope as? DefaultCardFormScope)?.cityField {
                AnyView(customField(fieldLabel, defaultStyling))
                    .focused($focusedField, equals: .city)
            } else {
                CityInputField(
                    label: fieldLabel ?? "",
                    placeholder: CheckoutComponentsStrings.cityPlaceholder,
                    scope: scope,
                    styling: defaultStyling
                )
                .focused($focusedField, equals: .city)
                .onSubmit { moveToNextField(from: .city) }
            }

        case .state:
            // First check components configuration
            if let customField = cardFormConfig.billingAddress.state {
                AnyView(customField())
            }
            // Then check legacy scope configuration
            else if let customField = (scope as? DefaultCardFormScope)?.stateField {
                AnyView(customField(fieldLabel, defaultStyling))
            } else {
                StateInputField(
                    label: fieldLabel ?? "",
                    placeholder: CheckoutComponentsStrings.statePlaceholder,
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .addressLine1:
            // First check components configuration
            if let customField = cardFormConfig.billingAddress.addressLine1 {
                AnyView(customField())
            }
            // Then check legacy scope configuration
            else if let customField = (scope as? DefaultCardFormScope)?.addressLine1Field {
                AnyView(customField(fieldLabel, defaultStyling))
            } else {
                AddressLineInputField(
                    label: fieldLabel ?? "",
                    placeholder: CheckoutComponentsStrings.addressLine1Placeholder,
                    isRequired: true,
                    inputType: .addressLine1,
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .addressLine2:
            // First check components configuration
            if let customField = cardFormConfig.billingAddress.addressLine2 {
                AnyView(customField())
            }
            // Then check legacy scope configuration
            else if let customField = (scope as? DefaultCardFormScope)?.addressLine2Field {
                AnyView(customField(fieldLabel, defaultStyling))
            } else {
                AddressLineInputField(
                    label: fieldLabel ?? "",
                    placeholder: CheckoutComponentsStrings.addressLine2Placeholder,
                    isRequired: false,
                    inputType: .addressLine2,
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .phoneNumber:
            if let customField = (scope as? DefaultCardFormScope)?.phoneNumberField {
                AnyView(customField(fieldLabel, defaultStyling))
            } else {
                NameInputField(
                    label: fieldLabel ?? "",
                    placeholder: CheckoutComponentsStrings.phoneNumberPlaceholder,
                    inputType: .phoneNumber,
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .firstName:
            // First check components configuration
            if let customField = cardFormConfig.billingAddress.firstName {
                AnyView(customField())
            }
            // Then check legacy scope configuration
            else if let customField = (scope as? DefaultCardFormScope)?.firstNameField {
                AnyView(customField(fieldLabel, defaultStyling))
            } else {
                NameInputField(
                    label: fieldLabel ?? "",
                    placeholder: CheckoutComponentsStrings.firstNamePlaceholder,
                    inputType: .firstName,
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .lastName:
            // First check components configuration
            if let customField = cardFormConfig.billingAddress.lastName {
                AnyView(customField())
            }
            // Then check legacy scope configuration
            else if let customField = (scope as? DefaultCardFormScope)?.lastNameField {
                AnyView(customField(fieldLabel, defaultStyling))
            } else {
                NameInputField(
                    label: fieldLabel ?? "",
                    placeholder: CheckoutComponentsStrings.lastNamePlaceholder,
                    inputType: .lastName,
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .email:
            if let customField = (scope as? DefaultCardFormScope)?.emailField {
                AnyView(customField(fieldLabel, defaultStyling))
            } else {
                EmailInputField(
                    label: fieldLabel ?? "",
                    placeholder: CheckoutComponentsStrings.emailPlaceholder,
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .retailer:
            if let customField = (scope as? DefaultCardFormScope)?.retailOutletField {
                AnyView(customField(fieldLabel, defaultStyling))
            } else {
                Text(CheckoutComponentsStrings.retailOutletNotImplemented)
                    .font(PrimerFont.caption(tokens: tokens))
                    .foregroundColor(CheckoutColors.gray(tokens: tokens))
                    .padding(PrimerSpacing.large(tokens: tokens))
            }

        case .otp:
            if let customField = (scope as? DefaultCardFormScope)?.otpCodeField {
                AnyView(customField(fieldLabel, defaultStyling))
            } else {
                OTPCodeInputField(
                    label: fieldLabel ?? "",
                    placeholder: CheckoutComponentsStrings.otpCodeNumericPlaceholder,
                    scope: scope,
                    styling: defaultStyling
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
        for field in formConfiguration.cardFields {
            if cardFormState.hasError(for: field) {
                focusedField = field
                return
            }
        }

        for field in formConfiguration.billingFields {
            if cardFormState.hasError(for: field) {
                focusedField = field
                return
            }
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
                .otp,
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
                .otp,
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
