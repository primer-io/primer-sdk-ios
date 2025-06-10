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
            // Use CardViewModel factory methods instead of manual instantiation
            AnyView(scope.PrimerCardNumberField(modifier: (), label: "Card Number"))

            // Expiry Date and CVV Row
            HStack(spacing: 16) {
                AnyView(scope.PrimerCardExpirationField(modifier: (), label: "Expiry Date"))
                AnyView(scope.PrimerCvvField(modifier: (), label: "CVV"))
            }

            // Cardholder Name Field
            AnyView(scope.PrimerCardholderNameField(modifier: (), label: "Cardholder Name"))

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
    }
}
