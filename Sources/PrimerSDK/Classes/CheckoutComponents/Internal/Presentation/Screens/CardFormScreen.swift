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
    @Environment(\.sizeCategory) private var sizeCategory // Observes Dynamic Type changes
    @State private var cardFormState: StructuredCardFormState = .init()
    @State private var selectedCardNetwork: CardNetwork = .unknown
    @State private var refreshTrigger = UUID()
    @State private var formConfiguration: CardFormConfiguration = .default
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
    }

    @MainActor
    private var headerSection: some View {
        VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
            // Navigation bar (Back/Cancel)
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

                // Show close button based on dismissalMechanism setting
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

            // Title
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
            observeState()
        }
    }

    private var titleSection: some View {
        let fontSize = tokens?.primerTypographyTitleXlargeSize ?? 24
        let fontWeight: Font.Weight = .semibold

        return Text(CheckoutComponentsStrings.cardPaymentTitle)
            .font(.system(size: fontSize, weight: fontWeight))
            .tracking(tokens?.primerTypographyTitleXlargeLetterSpacing ?? -0.6)
            .lineSpacing((tokens?.primerTypographyTitleXlargeLineHeight ?? 32) - fontSize)
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    @MainActor
    @ViewBuilder
    private var dynamicFieldsSection: some View {
        // Check for complete screen override first
        if let customScreen = scope.screen {
            AnyView(customScreen(scope))
        } else {
            VStack(spacing: 0) {
                // Render card fields dynamically based on configuration
                cardFieldsSection

                // Co-badged cards selection
                cobadgedCardsSection

                // Billing address fields if configured
                billingAddressSection
            }
        }
    }

    @MainActor
    @ViewBuilder
    private var cardFieldsSection: some View {
        // Check for section-level override first
        if let customSection = (scope as? DefaultCardFormScope)?.cardInputSection {
            AnyView(customSection())
        } else {
            VStack(spacing: 0) {
                // Render fields dynamically, inserting networks after card number
                ForEach(0..<formConfiguration.cardFields.count, id: \.self) { index in
                    let fieldType = formConfiguration.cardFields[index]

                    // Check if this is expiry date followed by CVV - render them horizontally
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
                        // Skip CVV if it was already rendered with expiry date
                        EmptyView()
                    } else {
                        // Render field
                        renderField(fieldType)
                    }

                    // Render networks as separate VStack child immediately after card number field
                    if fieldType == .cardNumber {
                        let allowedNetworks = [CardNetwork].allowedCardNetworks
                        // Fallback for previews: show common networks if API config is not available
                        let networksToShow = !allowedNetworks.isEmpty ? allowedNetworks : [.visa, .masterCard, .amex, .discover]
                        AllowedCardNetworksView(allowedCardNetworks: networksToShow)
                            .padding(.bottom, PrimerSpacing.medium(tokens: tokens))
                    }
                }
            }
        }
    }

    @MainActor
    @ViewBuilder
    private var cobadgedCardsSection: some View {
        if cardFormState.availableNetworks.count > 1 {
            if let customCobadgedCardsView = scope.cobadgedCardsView {
                AnyView(customCobadgedCardsView(cardFormState.availableNetworks.map { $0.network.rawValue }) { network in
                    Task { @MainActor in
                        scope.updateSelectedCardNetwork(network)
                    }
                })
            } else {
                defaultCobadgedCardsView
            }
        }
    }

    private var defaultCobadgedCardsView: some View {
        VStack(alignment: .leading, spacing: PrimerSpacing.small(tokens: tokens)) {
            Text(CheckoutComponentsStrings.selectNetworkTitle)
                .font(PrimerFont.caption(tokens: tokens))
                .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
                .accessibilityAddTraits(.isHeader)

            CardNetworkSelector(
                availableNetworks: cardFormState.availableNetworks.map { $0.network },
                selectedNetwork: $selectedCardNetwork,
                onNetworkSelected: { network in
                    selectedCardNetwork = network
                    Task { @MainActor in
                        scope.updateSelectedCardNetwork(network.rawValue)
                    }
                }
            )
        }
    }

    @ViewBuilder
    @MainActor
    private var billingAddressSection: some View {
        // Only show if configuration includes billing fields
        if !formConfiguration.billingFields.isEmpty {
            // Check for section-level override first
            if let customSection = (scope as? DefaultCardFormScope)?.billingAddressSection {
                AnyView(customSection())
                    .id(refreshTrigger)
            } else {
                VStack(alignment: .leading, spacing: PrimerSpacing.small(tokens: tokens)) {
                    // Billing address section title
                    Text(CheckoutComponentsStrings.billingAddressTitle)
                        .font(PrimerFont.headline(tokens: tokens))
                        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
                    
                    // Render billing fields dynamically
                    VStack(spacing: 0) {
                        ForEach(formConfiguration.billingFields, id: \.self) { fieldType in
                            renderField(fieldType)
                        }
                    }
                }
                .id(refreshTrigger)
            }
        }
    }

    @MainActor
    @ViewBuilder
    private var submitButtonSection: some View {
        // Check for section-level override first
        if let customSection = (scope as? DefaultCardFormScope)?.submitButtonSection {
            AnyView(customSection())
        } else {
            Group {
                if let customButton = (scope as? DefaultCardFormScope)?.submitButton {
                    AnyView(customButton(submitButtonText))
                        .onTapGesture {
                            if cardFormState.isValid && !cardFormState.isLoading {
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

        return HStack {
            if cardFormState.isLoading {
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

    /// Accessibility-friendly version of submit button text for VoiceOver
    /// Uses period as decimal separator to avoid misreading "6,00€" as "600 euros"
    private var submitButtonAccessibilityLabel: String {
        // Check if custom button text is configured (e.g., "Add New Card" for vaulting)
        if scope.cardFormUIOptions?.payButtonAddNewCard == true {
            return CheckoutComponentsStrings.addCardButton
        }

        // Only show amount in checkout intent and when currency is set
        guard PrimerInternal.shared.intent == .checkout,
              let currency = AppState.current.currency else {
            return CheckoutComponentsStrings.payButton
        }

        let baseAmount = AppState.current.amount ?? 0

        // Check if there's a surcharge from the detected card network
        if let surchargeAmountString = cardFormState.surchargeAmount,
           !surchargeAmountString.isEmpty,
           cardFormState.selectedNetwork != nil {

            // Extract surcharge amount from the formatted string (e.g., "+ 1,23€" -> 123)
            var cleanString = surchargeAmountString.replacingOccurrences(of: "+ ", with: "")

            // Remove all currency symbols
            let currencySymbols = CharacterSet(charactersIn: "$€£¥₹₽₩₪₨₦₴₵₸₺₼₾¢฿₡₢₣₤₥₧₫₭₮₯₰₱₲₳₶₷₿﷼")
            cleanString = cleanString.components(separatedBy: currencySymbols).joined()

            // Handle different decimal separators (European "," vs US ".")
            cleanString = cleanString.replacingOccurrences(of: ",", with: ".")

            if let surchargeAmount = Double(cleanString.trimmingCharacters(in: .whitespaces)) {
                // Convert to cents for calculation
                let surchargeCents = Int(surchargeAmount * Double(currency.decimalDigits == 2 ? 100 : pow(10, Double(currency.decimalDigits))))
                let totalAmount = baseAmount + surchargeCents
                // Use accessibility-friendly formatter
                let accessibilityAmount = totalAmount.toAccessibilityCurrencyString(currency: currency)
                return "Pay with \(accessibilityAmount)"
            }
        }

        // No surcharge or parsing failed, use base amount with accessibility formatter
        let accessibilityAmount = baseAmount.toAccessibilityCurrencyString(currency: currency)
        return "Pay with \(accessibilityAmount)"
    }

    private var submitButtonText: String {
        // Check if custom button text is configured (e.g., "Add New Card" for vaulting)
        if scope.cardFormUIOptions?.payButtonAddNewCard == true {
            return CheckoutComponentsStrings.addCardButton
        }

        // Only show amount in checkout intent and when currency is set
        guard PrimerInternal.shared.intent == .checkout,
              let currency = AppState.current.currency else {
            return CheckoutComponentsStrings.payButton
        }

        let baseAmount = AppState.current.amount ?? 0

        // Check if there's a surcharge from the detected card network
        if let surchargeAmountString = cardFormState.surchargeAmount,
           !surchargeAmountString.isEmpty,
           cardFormState.selectedNetwork != nil {

            // Extract surcharge amount from the formatted string (e.g., "+ 1,23€" -> 123)
            // The surcharge is already calculated by DefaultCardFormScope.updateSurchargeAmount
            var cleanString = surchargeAmountString.replacingOccurrences(of: "+ ", with: "")

            // Remove all currency symbols using CharacterSet
            // Includes common currency symbols plus additional Unicode currency characters
            let currencySymbols = CharacterSet(charactersIn: "$€£¥₹₽₩₪₨₦₴₵₸₺₼₾¢฿₡₢₣₤₥₧₫₭₮₯₰₱₲₳₶₷₿﷼")
            cleanString = cleanString.components(separatedBy: currencySymbols).joined()

            // Handle different decimal separators (European "," vs US ".")
            cleanString = cleanString.replacingOccurrences(of: ",", with: ".")

            if let surchargeAmount = Double(cleanString.trimmingCharacters(in: .whitespaces)) {
                // Convert to cents for calculation (surcharge is in major currency units, need minor units)
                let surchargeCents = Int(surchargeAmount * Double(currency.decimalDigits == 2 ? 100 : pow(10, Double(currency.decimalDigits))))
                let totalAmount = baseAmount + surchargeCents
                let formattedTotalAmount = totalAmount.toCurrencyString(currency: currency)
                return CheckoutComponentsStrings.paymentAmountTitle(formattedTotalAmount)
            }
        }

        // No surcharge or parsing failed, use base amount
        let formattedBaseAmount = baseAmount.toCurrencyString(currency: currency)
        return CheckoutComponentsStrings.paymentAmountTitle(formattedBaseAmount)
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

    private func observeState() {
        Task {
            // Get initial form configuration
            await MainActor.run {
                formConfiguration = scope.getFormConfiguration()
                bridgeController?.invalidateContentSize()
            }

            for await state in scope.state {
                // Get form configuration outside of MainActor.run
                let updatedFormConfig = await MainActor.run {
                    scope.getFormConfiguration()
                }

                await MainActor.run {
                    self.cardFormState = state
                    self.refreshTrigger = UUID()

                    // Update form configuration in case it changed
                    self.formConfiguration = updatedFormConfig

                    // Update selected network if changed
                    if let selectedNetwork = state.selectedNetwork {
                        self.selectedCardNetwork = selectedNetwork.network
                    } else if state.availableNetworks.count == 1,
                              let firstNetwork = state.availableNetworks.first {
                        self.selectedCardNetwork = firstNetwork.network
                    } else if state.availableNetworks.count > 1 {
                        if let firstNetwork = state.availableNetworks.first,
                           self.selectedCardNetwork == .unknown {
                            self.selectedCardNetwork = firstNetwork.network
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
            if let customField = (scope as? DefaultCardFormScope)?.cardNumberField {
                AnyView(customField(fieldLabel, defaultStyling))
                    .focused($focusedField, equals: .cardNumber)
            } else {
                CardNumberInputField(
                    label: fieldLabel ?? "Card Number",
                    placeholder: CheckoutComponentsStrings.cardNumberPlaceholder,
                    scope: scope,
                    selectedNetwork: getSelectedCardNetwork(),
                    styling: defaultStyling
                )
                .focused($focusedField, equals: .cardNumber)
                .onSubmit { moveToNextField(from: .cardNumber) }
            }

        case .expiryDate:
            if let customField = (scope as? DefaultCardFormScope)?.expiryDateField {
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
            if let customField = (scope as? DefaultCardFormScope)?.cvvField {
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
            if let customField = (scope as? DefaultCardFormScope)?.cardholderNameField {
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
            if let customField = (scope as? DefaultCardFormScope)?.postalCodeField {
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
            if let customField = (scope as? DefaultCardFormScope)?.countryField {
                AnyView(customField(fieldLabel, defaultStyling))
                    .focused($focusedField, equals: .countryCode)
            } else {
                CountryInputField(
                    label: fieldLabel ?? "",
                    placeholder: CheckoutComponentsStrings.selectCountryPlaceholder,
                    scope: scope,
                    styling: defaultStyling
                )
                .focused($focusedField, equals: .countryCode)
                .onSubmit { moveToNextField(from: .countryCode) }
            }

        case .city:
            if let customField = (scope as? DefaultCardFormScope)?.cityField {
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
            if let customField = (scope as? DefaultCardFormScope)?.stateField {
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
            if let customField = (scope as? DefaultCardFormScope)?.addressLine1Field {
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
            if let customField = (scope as? DefaultCardFormScope)?.addressLine2Field {
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
            if let customField = (scope as? DefaultCardFormScope)?.firstNameField {
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
            if let customField = (scope as? DefaultCardFormScope)?.lastNameField {
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
            // Get card number from structured data
            let cardNumber: String? = nil
            return CardNetwork(cardNumber: cardNumber ?? "")
        }
    }

    // MARK: - Focus Management

    /// Moves keyboard focus to the next field in logical order
    /// cardNumber → expiry → cvv → cardholderName → submit
    private func moveToNextField(from currentField: PrimerInputElementType) {
        // Get the logical field order from form configuration
        let cardFields = formConfiguration.cardFields
        let billingFields = formConfiguration.billingFields

        // Find current field index in card fields
        if let currentIndex = cardFields.firstIndex(of: currentField) {
            // Move to next card field if available
            if currentIndex + 1 < cardFields.count {
                focusedField = cardFields[currentIndex + 1]
                return
            }
            // If last card field, move to first billing field if available
            if !billingFields.isEmpty {
                focusedField = billingFields.first
                return
            }
            // Otherwise, clear focus (moves to submit button)
            focusedField = nil
            return
        }

        // Find current field index in billing fields
        if let currentIndex = billingFields.firstIndex(of: currentField) {
            // Move to next billing field if available
            if currentIndex + 1 < billingFields.count {
                focusedField = billingFields[currentIndex + 1]
                return
            }
            // If last field, clear focus (moves to submit button)
            focusedField = nil
            return
        }

        // Default: clear focus
        focusedField = nil
    }

    /// Moves focus to the first field with a validation error.
    ///
    /// **Important**: This should only be called in response to explicit user actions,
    /// such as attempting to submit the form or requesting error navigation.
    /// DO NOT call this automatically when errors appear during typing, as it creates
    /// an accessibility trap preventing VoiceOver users from navigating freely.
    ///
    /// Valid use cases:
    /// - User manually requests "jump to error" functionality
    /// - After form submission is attempted (if we add validation-before-submit)
    /// - Explicit accessibility navigation actions
    ///
    /// Invalid use cases:
    /// - Automatic call when error count increases during typing (ACCESSIBILITY TRAP)
    /// - Any automatic call during text input changes
    private func moveFocusToFirstError() {
        // Check for errors in card fields first
        for field in formConfiguration.cardFields {
            if cardFormState.hasError(for: field) {
                focusedField = field
                return
            }
        }

        // Then check billing fields
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
struct CardFormScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // All Fields - Comprehensive view of every field type
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
            .previewDisplayName("All Fields - Light")

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
            .previewDisplayName("All Fields - Dark")

            // Card Fields Only - Minimal configuration
            CardFormScreen(scope: MockCardFormScope(
                selectedNetwork: .amex,
                formConfiguration: CardFormConfiguration(
                    cardFields: [.cardNumber, .expiryDate, .cvv, .cardholderName],
                    billingFields: []
                )
            ))
            .environment(\.designTokens, MockDesignTokens.light)
            .environment(\.diContainer, MockDIContainer())
            .previewDisplayName("Card Fields Only - Light")

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
            .previewDisplayName("Card Fields Only - Dark")

            // Co-badged Cards - Multiple networks
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
            .previewDisplayName("Co-badged Cards - Light")

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
            .previewDisplayName("Co-badged Cards - Dark")

            // Loading State
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
            .previewDisplayName("Loading State")

            // Valid State - Ready to submit
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
            .previewDisplayName("Valid State")

            // With Billing Address
            CardFormScreen(scope: MockCardFormScope(
                selectedNetwork: .masterCard,
                formConfiguration: CardFormConfiguration(
                    cardFields: [.cardNumber, .expiryDate, .cvv],
                    billingFields: [.countryCode, .addressLine1, .city, .state, .postalCode]
                )
            ))
            .environment(\.designTokens, MockDesignTokens.light)
            .environment(\.diContainer, MockDIContainer())
            .previewDisplayName("With Billing Address - Light")

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
            .previewDisplayName("With Billing Address - Dark")

            // With Surcharge Amount
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
            .previewDisplayName("With Surcharge")
        }
    }
}
#endif
