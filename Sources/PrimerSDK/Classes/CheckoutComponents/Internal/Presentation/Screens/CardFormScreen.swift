//
//  CardFormScreen.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Default card form screen for CheckoutComponents
@available(iOS 15.0, *)
internal struct CardFormScreen: View {
    let scope: any PrimerCardFormScope

    @Environment(\.designTokens) private var tokens
    @State private var cardFormState: PrimerCardFormState = .init()
    @State private var selectedCardNetwork: CardNetwork = .unknown

    /// Check if billing address fields are required based on API configuration
    private var isShowingBillingAddressFieldsRequired: Bool {
        let billingAddressModuleOptions = PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?
            .first { $0.type == "BILLING_ADDRESS" }?.options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions
        return billingAddressModuleOptions != nil
    }

    /// Get billing address configuration from API configuration
    private var billingAddressConfiguration: BillingAddressConfiguration {
        guard let billingAddressModuleOptions = PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?
                .first(where: { $0.type == "BILLING_ADDRESS" })?.options as? PrimerAPIConfiguration.CheckoutModule.PostalCodeOptions else {
            return BillingAddressConfiguration.none
        }

        return BillingAddressConfiguration(
            showFirstName: billingAddressModuleOptions.firstName != false,
            showLastName: billingAddressModuleOptions.lastName != false,
            showEmail: false, // Email is not part of billing address module, left here for possible future use
            showPhoneNumber: billingAddressModuleOptions.phoneNumber != false,
            showAddressLine1: billingAddressModuleOptions.addressLine1 != false,
            showAddressLine2: billingAddressModuleOptions.addressLine2 != false,
            showCity: billingAddressModuleOptions.city != false,
            showState: billingAddressModuleOptions.state != false,
            showPostalCode: billingAddressModuleOptions.postalCode != false,
            showCountry: billingAddressModuleOptions.countryCode != false
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            customHeader
            mainContent
        }
        .navigationBarHidden(true)
    }

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
                        Text("Back")
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

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: FigmaDesignConstants.sectionSpacing) {
                titleSection
                cardDetailsSection
                if isShowingBillingAddressFieldsRequired {
                    billingAddressSection
                }
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

    private var cardDetailsSection: some View {
        VStack(spacing: FigmaDesignConstants.sectionSpacing) {
            cardInputSection
            cobadgedCardsSection
        }
    }

    @ViewBuilder
    private var cardInputSection: some View {
        // Use individual field builders from scope for flexible customization
        VStack(spacing: FigmaDesignConstants.sectionSpacing) {
            // Card Number - use ViewBuilder method
            AnyView(scope.PrimerCardNumberField(label: "Card Number", styling: nil))

            // Allowed Card Networks Display (Android parity)
            let allowedNetworks = [CardNetwork].allowedCardNetworks
            if !allowedNetworks.isEmpty {
                AllowedCardNetworksView(
                    allowedCardNetworks: allowedNetworks
                )
            }

            // Expiry Date and CVV row
            HStack(spacing: FigmaDesignConstants.horizontalInputSpacing) {
                // Expiry Date
                AnyView(scope.PrimerExpiryDateField(label: "Expiry Date", styling: nil))
                    .frame(maxWidth: .infinity)

                // CVV
                AnyView(scope.PrimerCvvField(label: "CVV", styling: nil))
                    .frame(maxWidth: .infinity)
            }

            // Cardholder Name
            AnyView(scope.PrimerCardholderNameField(label: "Cardholder Name", styling: nil))
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var cobadgedCardsSection: some View {
        if cardFormState.availableCardNetworks.count > 1 {
            if let customCobadgedCardsView = scope.cobadgedCardsView {
                customCobadgedCardsView(cardFormState.availableCardNetworks) { network in
                    scope.updateSelectedCardNetwork(network)
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
                availableNetworks: cardFormState.availableCardNetworks.compactMap { CardNetwork(rawValue: $0) },
                selectedNetwork: $selectedCardNetwork,
                onNetworkSelected: { network in
                    selectedCardNetwork = network
                    scope.updateSelectedCardNetwork(network.rawValue)
                }
            )
            .padding(.horizontal)
        }
    }

    private var billingAddressSection: some View {
        BillingAddressView(
            cardFormScope: scope,
            configuration: billingAddressConfiguration
        )
        .padding(.horizontal)
    }

    private var submitButtonSection: some View {
        Group {
            AnyView(scope.PrimerSubmitButton(text: submitButtonText))
                .onTapGesture {
                    if cardFormState.isValid && !cardFormState.isSubmitting {
                        submitAction()
                    }
                }
            /*
             // Legacy fallback logic
             Button(action: submitAction) {
             submitButtonContent
             }
             .disabled(!cardFormState.isValid || cardFormState.isSubmitting)
             */
        }
        .padding(.horizontal)
        .padding(.bottom)
    }

    private var submitButtonContent: some View {
        HStack {
            if cardFormState.isSubmitting {
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
           let selectedNetwork = cardFormState.selectedCardNetwork {

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
        cardFormState.isValid && !cardFormState.isSubmitting
            ? (tokens?.primerColorTextPrimary ?? .blue)
            : (tokens?.primerColorGray300 ?? Color(.systemGray3))
    }

    private func submitAction() {
        Task {
            await (scope as? DefaultCardFormScope)?.submit()
        }
    }

    // Removed: createBillingAddressModifier() - no longer needed with ViewBuilder approach

    private func observeState() {
        Task {
            for await state in scope.state {
                await MainActor.run {
                    self.cardFormState = state

                    // Update selected network if changed
                    if let selectedNetwork = state.selectedCardNetwork,
                       let network = CardNetwork(rawValue: selectedNetwork) {
                        self.selectedCardNetwork = network
                    } else if state.availableCardNetworks.count == 1,
                              let firstNetwork = state.availableCardNetworks.first,
                              let network = CardNetwork(rawValue: firstNetwork) {
                        // Auto-select if only one network available
                        self.selectedCardNetwork = network
                    } else if state.availableCardNetworks.count > 1 {
                        // Multiple networks available - use first as default if none selected
                        if let firstNetwork = state.availableCardNetworks.first,
                           let network = CardNetwork(rawValue: firstNetwork),
                           self.selectedCardNetwork == .unknown {
                            self.selectedCardNetwork = network
                        }
                    }
                }
            }
        }
    }
}
