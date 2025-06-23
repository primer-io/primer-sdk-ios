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
    @State private var cardFormState: PrimerCardFormScope.State = .init()
    @State private var showBillingAddress = false
    @State private var selectedCardNetwork: CardNetwork = .unknown
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                Text("Card Payment")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Card details section
                VStack(spacing: 16) {
                    // Card number input
                    if let customCardNumberInput = scope.cardNumberInput {
                        customCardNumberInput(PrimerModifier())
                    } else {
                        CardDetailsView(cardFormScope: scope)
                            .padding(.horizontal)
                    }
                    
                    // Co-badged cards selector
                    if cardFormState.availableCardNetworks.count > 1 {
                        if let customCobadgedCardsView = scope.cobadgedCardsView {
                            customCobadgedCardsView(
                                cardFormState.availableCardNetworks
                            ) { network in
                                scope.updateSelectedCardNetwork(network)
                            }
                        } else {
                            CardNetworkSelector(
                                availableNetworks: cardFormState.availableCardNetworks.compactMap { CardNetwork(rawValue: $0) },
                                selectedNetwork: $selectedCardNetwork,
                                onNetworkSelected: { network in
                                    scope.updateSelectedCardNetwork(network.rawValue)
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Billing address toggle
                Button(action: {
                    withAnimation {
                        showBillingAddress.toggle()
                    }
                }) {
                    HStack {
                        Text("Billing Address")
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
                .padding(.horizontal)
                
                // Billing address fields
                if showBillingAddress {
                    BillingAddressView(
                        cardFormScope: scope,
                        configuration: .full
                    )
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Error message
                if let error = cardFormState.error {
                    if let customErrorView = scope.errorView {
                        customErrorView(error)
                    } else {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(tokens?.primerColorError ?? .red)
                            .padding(.horizontal)
                    }
                }
                
                // Submit button
                Button(action: {
                    Task {
                        await (scope as? DefaultCardFormScope)?.submit()
                    }
                }) {
                    HStack {
                        if cardFormState.isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Pay")
                        }
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        cardFormState.isValid && !cardFormState.isSubmitting
                            ? (tokens?.primerColorPrimary ?? .blue)
                            : (tokens?.primerColorGray300 ?? Color(.systemGray3))
                    )
                    .cornerRadius(8)
                }
                .disabled(!cardFormState.isValid || cardFormState.isSubmitting)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding(.top)
        }
        .background(tokens?.primerColorBackground ?? Color(.systemBackground))
        .onAppear {
            observeState()
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