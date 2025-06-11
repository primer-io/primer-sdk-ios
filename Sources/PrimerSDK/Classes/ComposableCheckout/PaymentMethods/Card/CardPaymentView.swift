//
//  CardPaymentView.swift
//
//  Created on 21.03.2025.
//

import SwiftUI

/// Default UI for card payments.
@available(iOS 15.0, *)
struct CardPaymentView: View, LogReporter {
    let scope: any CardPaymentMethodScope

    // Form state
    @State private var isValid: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var uiState: CardPaymentUiState?

    @Environment(\.designTokens) private var tokens

    var body: some View {
        VStack(spacing: 16) {
            // Card Number Field
            CardNumberInputField(
                label: "Card Number",
                placeholder: "1234 5678 9012 3456",
                onCardNumberChange: { cardNumber in
                    if let viewModel = scope as? CardViewModel {
                        viewModel.updateCardNumber(cardNumber)
                    }
                },
                onCardNetworkChange: { network in
                    if let viewModel = scope as? CardViewModel {
                        viewModel.updateCardNetwork(network)
                    }
                }
            )

            // Expiry Date and CVV Row
            HStack(spacing: 16) {
                ExpiryDateInputField(
                    label: "Expiry Date",
                    placeholder: "MM/YY",
                    onExpiryDateChange: { expiryDate in
                        if let viewModel = scope as? CardViewModel {
                            viewModel.updateExpirationValue(expiryDate)
                        }
                    }
                )

                CVVInputField(
                    label: "CVV",
                    placeholder: "123",
                    cardNetwork: uiState?.cardNetworkData.selectedNetwork ?? .unknown,
                    onCvvChange: { cvv in
                        if let viewModel = scope as? CardViewModel {
                            viewModel.updateCvv(cvv)
                        }
                    }
                )
            }

            // Cardholder Name Field
            CardholderNameInputField(
                label: "Cardholder Name",
                placeholder: "John Doe",
                onCardholderNameChange: { name in
                    if let viewModel = scope as? CardViewModel {
                        viewModel.updateCardholderName(name)
                    }
                }
            )

            // Submit Button - use the factory method from scope
            AnyView(scope.PrimerPayButton(enabled: isValid, modifier: (), text: "Pay"))
        }
        .padding(16)
        .task {
            for await state in scope.state() {
                uiState = state
                updateFormValidity()
            }
        }
    }

    /// Updates the overall form validity based on CardViewModel state
    private func updateFormValidity() {
        guard let state = uiState else {
            isValid = false
            return
        }

        // Check if all required fields have valid values and no validation errors
        let cardNumberValid = !state.cardData.cardNumber.value.isEmpty && state.cardData.cardNumber.validationError == nil
        let expiryValid = !state.cardData.expiration.value.isEmpty && state.cardData.expiration.validationError == nil
        let cvvValid = !state.cardData.cvv.value.isEmpty && state.cardData.cvv.validationError == nil
        let nameValid = !state.cardData.cardholderName.value.isEmpty && state.cardData.cardholderName.validationError == nil

        isValid = cardNumberValid && expiryValid && cvvValid && nameValid

        logger.debug(message: "💳 Form validity updated: \(isValid)")
        logger.debug(message: "💳 Field validity: cardNumber=\(cardNumberValid), expiry=\(expiryValid), cvv=\(cvvValid), name=\(nameValid)")
    }
}
