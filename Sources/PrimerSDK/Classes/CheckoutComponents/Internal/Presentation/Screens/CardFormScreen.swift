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
    let scope: PrimerCardFormScope

    @Environment(\.designTokens) private var tokens
    @State private var cardFormState: PrimerCardFormState = .init()
    @State private var showBillingAddress = false
    @State private var selectedCardNetwork: CardNetwork = .unknown

    var body: some View {
        mainContent
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                titleSection
                cardDetailsSection
                billingAddressToggle
                billingAddressSection
                errorSection
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
        HStack {
            Button(action: {
                scope.onBack()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("Back")
                        .font(.body)
                }
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
            }
            
            Spacer()
            
            Text(CheckoutComponentsStrings.cardPaymentTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
            
            Spacer()
            
            // Hidden spacer to center the title
            Button("") { }
                .opacity(0)
                .disabled(true)
        }
        .padding(.horizontal)
    }

    private var cardDetailsSection: some View {
        VStack(spacing: 16) {
            cardInputSection
            cobadgedCardsSection
        }
    }

    @ViewBuilder
    private var cardInputSection: some View {
        if let customCardNumberInput = scope.cardNumberInput {
            customCardNumberInput(PrimerModifier())
        } else {
            CardDetailsView(cardFormScope: scope)
                .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var cobadgedCardsSection: some View {
        if cardFormState.availableCardNetworks.count > 1 {
            if let customCobadgedCardsView = scope.cobadgedCardsView {
                customCobadgedCardsView(cardFormState.availableCardNetworks) { network in
                    scope.updateSelectedCardNetwork(network)
                }
            } else {
                defaultCobadgedCardsView
            }
        }
    }

    private var defaultCobadgedCardsView: some View {
        CardNetworkSelector(
            availableNetworks: cardFormState.availableCardNetworks.compactMap { CardNetwork(rawValue: $0) },
            selectedNetwork: $selectedCardNetwork,
            onNetworkSelected: { network in
                scope.updateSelectedCardNetwork(network.rawValue)
            }
        )
        .padding(.horizontal)
    }

    private var billingAddressToggle: some View {
        Button(action: {
            withAnimation {
                showBillingAddress.toggle()
            }
        }) {
            billingAddressToggleContent
        }
        .padding(.horizontal)
    }

    private var billingAddressToggleContent: some View {
        HStack {
            Text(CheckoutComponentsStrings.billingAddressTitle)
                .font(.body)
                .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)

            Spacer()

            Image(systemName: showBillingAddress ? "chevron.up" : "chevron.down")
                .font(.caption)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
        }
        .padding()
        .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
        .cornerRadius(8)
    }

    @ViewBuilder
    private var billingAddressSection: some View {
        if showBillingAddress {
            BillingAddressView(
                cardFormScope: scope,
                configuration: .full
            )
            .padding(.horizontal)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let error = cardFormState.error {
            if let customErrorView = scope.errorView {
                customErrorView(error)
            } else {
                Text(error)
                    .font(.caption)
                    .foregroundColor(tokens?.primerColorBorderOutlinedError ?? .red)
                    .padding(.horizontal)
            }
        }
    }

    private var submitButtonSection: some View {
        Button(action: submitAction) {
            submitButtonContent
        }
        .disabled(!cardFormState.isValid || cardFormState.isSubmitting)
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
                Text(CheckoutComponentsStrings.payButton)
            }
        }
        .font(.body)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(submitButtonBackground)
        .cornerRadius(8)
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

    private func observeState() {
        Task {
            for await state in scope.state {
                await MainActor.run {
                    self.cardFormState = state

                    // Update selected network if changed
                    if let selectedNetwork = state.selectedCardNetwork,
                       let network = CardNetwork(rawValue: selectedNetwork) {
                        self.selectedCardNetwork = network
                    }
                }
            }
        }
    }
}
