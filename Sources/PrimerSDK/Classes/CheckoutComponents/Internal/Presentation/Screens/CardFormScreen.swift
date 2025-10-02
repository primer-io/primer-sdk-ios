//
//  CardFormScreen.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Default card form screen for CheckoutComponents with dynamic field rendering
@available(iOS 15.0, *)
internal struct CardFormScreen: View, LogReporter {
    let scope: any PrimerCardFormScope

    @Environment(\.designTokens) private var tokens
    @State private var cardFormState: StructuredCardFormState = .init()
    @State private var selectedCardNetwork: CardNetwork = .unknown
    @State private var refreshTrigger = UUID()
    @State private var formConfiguration: CardFormConfiguration = .default

    var body: some View {
        VStack(spacing: 0) {
            customHeader
            mainContent
        }
        .navigationBarHidden(true)
    }

    @MainActor
    private var customHeader: some View {
        HStack {
            // Back button - only show if context allows it
            if scope.presentationContext.shouldShowBackButton {
                Button(action: {
                    scope.onBack()
                }, label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.medium))
                        Text(CheckoutComponentsStrings.backButton)
                    }
                    .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
                })
            }

            Spacer()

            Button(CheckoutComponentsStrings.cancelButton, action: {
                scope.onCancel()
            })
            .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(tokens?.primerColorBackground ?? Color(.systemBackground))
        )
    }

    @MainActor
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: FigmaDesignConstants.sectionSpacing) {
                titleSection
                dynamicFieldsSection
                submitButtonSection
            }
            .padding(.top)
        }
        .background(tokens?.primerColorBackground ?? Color(.systemBackground))
        .onAppear {
            observeState()
        }
    }

    private var titleSection: some View {
        Text(CheckoutComponentsStrings.cardPaymentTitle)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
    }

    @MainActor
    @ViewBuilder
    private var dynamicFieldsSection: some View {
        // Check for complete screen override first
        if let customScreen = scope.screen {
            customScreen(scope)
        } else {
            VStack(spacing: FigmaDesignConstants.sectionSpacing) {
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
            customSection()
                .padding(.horizontal)
        } else {
            VStack(spacing: FigmaDesignConstants.sectionSpacing) {
                // Render fields dynamically based on configuration
                ForEach(0..<formConfiguration.cardFields.count, id: \.self) { index in
                    let fieldType = formConfiguration.cardFields[index]

                    // Check if this is expiry date followed by CVV - render them horizontally
                    if fieldType == .expiryDate,
                       index + 1 < formConfiguration.cardFields.count,
                       formConfiguration.cardFields[index + 1] == .cvv {
                        HStack(spacing: FigmaDesignConstants.horizontalInputSpacing) {
                            renderField(.expiryDate)
                            renderField(.cvv)
                        }
                    } else if index > 0,
                              formConfiguration.cardFields[index - 1] == .expiryDate,
                              fieldType == .cvv {
                        // Skip CVV if it was already rendered with expiry date
                        EmptyView()
                    } else if fieldType == .cardNumber {
                        // Render card number field with allowed networks below it
                        VStack(spacing: FigmaDesignConstants.sectionSpacing) {
                            renderField(fieldType)

                            // Show allowed card networks directly below card number
                            let allowedNetworks = [CardNetwork].allowedCardNetworks
                            if !allowedNetworks.isEmpty {
                                AllowedCardNetworksView(allowedCardNetworks: allowedNetworks)
                            }
                        }
                    } else {
                        // Render other fields normally
                        renderField(fieldType)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    @MainActor
    @ViewBuilder
    private var cobadgedCardsSection: some View {
        if cardFormState.availableNetworks.count > 1 {
            if let customCobadgedCardsView = scope.cobadgedCardsView {
                customCobadgedCardsView(cardFormState.availableNetworks.map { $0.network.rawValue }) { network in
                    Task { @MainActor in
                        scope.updateSelectedCardNetwork(network)
                    }
                }
                .padding(.horizontal)
            } else {
                defaultCobadgedCardsView
            }
        }
    }

    private var defaultCobadgedCardsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Network")
                .font(.caption)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                .padding(.horizontal)

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
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    @MainActor
    private var billingAddressSection: some View {
        // Only show if configuration includes billing fields
        if !formConfiguration.billingFields.isEmpty {
            // Check for section-level override first
            if let customSection = (scope as? DefaultCardFormScope)?.billingAddressSection {
                customSection()
                    .padding(.horizontal)
                    .id(refreshTrigger)
            } else {
                VStack(alignment: .leading, spacing: FigmaDesignConstants.sectionSpacing) {
                    // Billing address section title
                    Text("Billing Address")
                        .font(.headline)
                        .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
                        .padding(.horizontal)

                    // Render billing fields dynamically
                    VStack(spacing: FigmaDesignConstants.sectionSpacing) {
                        ForEach(formConfiguration.billingFields, id: \.self) { fieldType in
                            renderField(fieldType)
                        }
                    }
                    .padding(.horizontal)
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
            customSection()
                .padding(.horizontal)
                .padding(.bottom)
        } else {
            Group {
                if let customButton = (scope as? DefaultCardFormScope)?.submitButton {
                    customButton(submitButtonText)
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
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private var submitButtonContent: some View {
        HStack {
            if cardFormState.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            } else {
                Text(submitButtonText)
            }
        }
        .font(.body)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(submitButtonBackground)
        .cornerRadius(8)
    }

    private var submitButtonText: String {
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

            // Remove common currency symbols
            let currencySymbols = ["€", "$", "£", "¥", "₹", "¢"]
            for symbol in currencySymbols {
                cleanString = cleanString.replacingOccurrences(of: symbol, with: "")
            }

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
            ? (tokens?.primerColorTextPrimary ?? .blue)
            : (tokens?.primerColorGray300 ?? Color(.systemGray3))
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
            }

            for await state in await scope.state {
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
                customField(fieldLabel, defaultStyling)
            } else {
                CardNumberInputField(
                    label: fieldLabel ?? "Card Number",
                    placeholder: "1234 1234 1234 1234",
                    scope: scope,
                    selectedNetwork: getSelectedCardNetwork(),
                    styling: defaultStyling
                )
            }

        case .expiryDate:
            if let customField = (scope as? DefaultCardFormScope)?.expiryDateField {
                customField(fieldLabel, defaultStyling)
            } else {
                ExpiryDateInputField(
                    label: fieldLabel ?? "",
                    placeholder: "MM/YY",
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .cvv:
            if let customField = (scope as? DefaultCardFormScope)?.cvvField {
                customField(fieldLabel, defaultStyling)
            } else {
                CVVInputField(
                    label: fieldLabel ?? "",
                    placeholder: getCardNetworkForCvv() == .amex ? "1234" : "123",
                    scope: scope,
                    cardNetwork: getCardNetworkForCvv(),
                    styling: defaultStyling
                )
            }

        case .cardholderName:
            if let customField = (scope as? DefaultCardFormScope)?.cardholderNameField {
                customField(fieldLabel, defaultStyling)
            } else {
                CardholderNameInputField(
                    label: fieldLabel ?? "",
                    placeholder: "Full name",
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .postalCode:
            if let customField = (scope as? DefaultCardFormScope)?.postalCodeField {
                customField(fieldLabel, defaultStyling)
            } else {
                PostalCodeInputField(
                    label: fieldLabel ?? "",
                    placeholder: "12345",
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .countryCode:
            if let customField = (scope as? DefaultCardFormScope)?.countryField {
                customField(fieldLabel, defaultStyling)
            } else {
                CountryInputField(
                    label: fieldLabel ?? "",
                    placeholder: "Select Country",
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .city:
            if let customField = (scope as? DefaultCardFormScope)?.cityField {
                customField(fieldLabel, defaultStyling)
            } else {
                CityInputField(
                    label: fieldLabel ?? "",
                    placeholder: "City",
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .state:
            if let customField = (scope as? DefaultCardFormScope)?.stateField {
                customField(fieldLabel, defaultStyling)
            } else {
                StateInputField(
                    label: fieldLabel ?? "",
                    placeholder: "State",
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .addressLine1:
            if let customField = (scope as? DefaultCardFormScope)?.addressLine1Field {
                customField(fieldLabel, defaultStyling)
            } else {
                AddressLineInputField(
                    label: fieldLabel ?? "",
                    placeholder: "123 Main St",
                    isRequired: true,
                    inputType: .addressLine1,
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .addressLine2:
            if let customField = (scope as? DefaultCardFormScope)?.addressLine2Field {
                customField(fieldLabel, defaultStyling)
            } else {
                AddressLineInputField(
                    label: fieldLabel ?? "",
                    placeholder: "Apt 4B",
                    isRequired: false,
                    inputType: .addressLine2,
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .phoneNumber:
            if let customField = (scope as? DefaultCardFormScope)?.phoneNumberField {
                customField(fieldLabel, defaultStyling)
            } else {
                NameInputField(
                    label: fieldLabel ?? "",
                    placeholder: "+1 (555) 123-4567",
                    inputType: .phoneNumber,
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .firstName:
            if let customField = (scope as? DefaultCardFormScope)?.firstNameField {
                customField(fieldLabel, defaultStyling)
            } else {
                NameInputField(
                    label: fieldLabel ?? "",
                    placeholder: "John",
                    inputType: .firstName,
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .lastName:
            if let customField = (scope as? DefaultCardFormScope)?.lastNameField {
                customField(fieldLabel, defaultStyling)
            } else {
                NameInputField(
                    label: fieldLabel ?? "",
                    placeholder: "Smith",
                    inputType: .lastName,
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .email:
            if let customField = (scope as? DefaultCardFormScope)?.emailField {
                customField(fieldLabel, defaultStyling)
            } else {
                EmailInputField(
                    label: fieldLabel ?? "",
                    placeholder: "john@example.com",
                    scope: scope,
                    styling: defaultStyling
                )
            }

        case .retailer:
            if let customField = (scope as? DefaultCardFormScope)?.retailOutletField {
                customField(fieldLabel, defaultStyling)
            } else {
                Text("Retail outlet selection not yet implemented")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
            }

        case .otp:
            if let customField = (scope as? DefaultCardFormScope)?.otpCodeField {
                customField(fieldLabel, defaultStyling)
            } else {
                OTPCodeInputField(
                    label: fieldLabel ?? "",
                    placeholder: "123456",
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
            let cardNumber = cardFormState.data[.cardNumber]
            return CardNetwork(cardNumber: cardNumber)
        }
    }
}
