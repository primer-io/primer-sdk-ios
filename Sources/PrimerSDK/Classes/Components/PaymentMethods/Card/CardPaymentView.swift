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

    // Reference to the input fields for direct access
    @State private var cardInputField = CardNumberInputField(
        label: "Card Number",
        placeholder: "4242 4242 4242 4242",
        onCardNetworkChange: nil,
        onValidationChange: nil
    )

    @State private var expiryDateInputField = ExpiryDateInputField(
        label: "Expiry Date",
        placeholder: "MM/YY",
        onValidationChange: nil,
        onMonthChange: nil,
        onYearChange: nil
    )

    @State private var cvvInputField = CVVInputField(
        label: "CVV",
        placeholder: "123",
        cardNetwork: .unknown,
        onValidationChange: nil
    )

    @State private var cardholderNameInputField = CardholderNameInputField(
        label: "Cardholder Name",
        placeholder: "John Doe",
        onValidationChange: nil
    )

    // Form state
    @State private var isValid: Bool = false
    @State private var isSubmitting: Bool = false

    // Input validation state
    @State private var isCardNumberValid: Bool = false
    @State private var isExpiryDateValid: Bool = false
    @State private var isCvvValid: Bool = false
    @State private var isCardholderNameValid: Bool = false

    // Card network state
    @State private var currentCardNetwork: CardNetwork = .unknown

    @Environment(\.designTokens) private var tokens

    var body: some View {
        VStack(spacing: 16) {
            // Card number field with direct callbacks
            cardInputField
                .onCardNetworkChange { network in
                    currentCardNetwork = network
                    cvvInputField = CVVInputField(
                        label: "CVV",
                        placeholder: network == .amex ? "1234" : "123",
                        cardNetwork: network,
                        onValidationChange: cvvInputField.onValidationChange
                    )

                    scope.updateCardNetwork(network)
                }
                .onValidationChange { isValid in
                    isCardNumberValid = isValid
                    updateFormValidity()

                    // Get the value and update synchronously
                    let cardNumber = cardInputField.getCardNumber()
                    scope.updateCardNumber(cardNumber)
                }
            // MARK: - Expiry Date and CVV Row
            HStack(spacing: 16) {
                // Expiry date field using our new component
                expiryDateInputField
                    .onValidationChange { isValid in
                        isExpiryDateValid = isValid
                        updateFormValidity()
                    }
                    .onMonthChange { month in
                        scope.updateExpiryMonth(month)
                    }
                    .onYearChange { year in
                        scope.updateExpiryYear(year)
                    }

                // CVV field using our CVVInputField component
                cvvInputField
                    .onValidationChange { isValid in
                        isCvvValid = isValid
                        updateFormValidity()

                        // Get CVV directly from the field and update the scope
                        let cvvValue = cvvInputField.getCVV()

                        scope.updateCvv(cvvValue)
                    }
            }

            // MARK: - Cardholder Name Field using our CardholderNameInputField component
            cardholderNameInputField
                .onValidationChange { isValid in
                    isCardholderNameValid = isValid
                    updateFormValidity()

                    // Get cardholder name directly from the field and update the scope
                    let name = cardholderNameInputField.getCardholderName()

                    scope.updateCardholderName(name)
                }

            // MARK: - Submit Button
            Button {
                // Get the latest values directly from the fields
                let cardNumber = cardInputField.getCardNumber()
                let expiryDate = expiryDateInputField.getExpiryDate()
                let cvv = cvvInputField.getCVV()
                let name = cardholderNameInputField.getCardholderName()

                // Force update all fields in the model
                scope.updateCardNumber(cardNumber)

                let parts = expiryDate.components(separatedBy: "/")
                if parts.count == 2 {
                    scope.updateExpiryMonth(parts[0])
                    scope.updateExpiryYear(parts[1])
                }

                scope.updateCvv(cvv)
                scope.updateCardholderName(name)

                // Now submit after ensuring all fields are updated
                isSubmitting = true
                Task {
                    do {
                        let result = try await scope.submit()
                        logger.debug(message: "Payment successful: \(result)")
                        // Handle successful payment here
                    } catch {
                        logger.debug(message: "Payment failed: \(error)")
                        // Handle payment failure here
                    }
                    isSubmitting = false
                }
            } label: {
                Text(isSubmitting ? "Processing..." : "Pay")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValid ? (tokens?.primerColorBrand ?? .blue) : (tokens?.primerColorGray400 ?? .gray))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!isValid || isSubmitting)
        }
        .padding(16)
        // Update UI state from the scope asynchronously
        .task {
            for await state in scope.state() {
                if let state = state {
                    // The fields are now managed by their respective components
                    // We just need to update the overall form validity
                    updateFormValidity()
                }
            }
        }
    }

    /// Updates the overall form validity based on field-level validation
    private func updateFormValidity() {
        // First get all the current values
        let cardNumberValue = cardInputField.getCardNumber()
        let expiryDateValue = expiryDateInputField.getExpiryDate()
        let cvvValue = cvvInputField.getCVV()
        let nameValue = cardholderNameInputField.getCardholderName()

        // Log them to verify they're correct
        logger.debug(message: "💳 Card form validation - Current values:")
        logger.debug(message: "Card number: \(cardNumberValue.isEmpty ? "[empty]" : "[filled]")")
        logger.debug(message: "Expiry date: \(expiryDateValue)")
        logger.debug(message: "CVV: \(cvvValue.isEmpty ? "[empty]" : "[filled]")")
        logger.debug(message: "Name: \(nameValue)")

        // Check if any required field is empty
        let hasEmptyRequiredField = cardNumberValue.isEmpty ||
            expiryDateValue.isEmpty ||
            cvvValue.isEmpty ||
            nameValue.isEmpty

        // Combine the individual field validations
        isValid = isCardNumberValid &&
            isExpiryDateValid &&
            isCvvValid &&
            isCardholderNameValid &&
            !hasEmptyRequiredField

        logger.debug(message: "Form validity: \(isValid)")
    }

    /// Debug function to print values before submission
    private func debugPrintFormValues() {
        logger.debug(message: "📋 CARD FORM SUBMISSION - FORM VALUES:")
        logger.debug(message: "Card Number: \(cardInputField.getCardNumber().isEmpty ? "[empty]" : "[filled]")")
        logger.debug(message: "Expiry Date: \(expiryDateInputField.getExpiryDate())")
        logger.debug(message: "CVV: \(cvvInputField.getCVV().isEmpty ? "[empty]" : "[filled]")")
        logger.debug(message: "Cardholder Name: \(cardholderNameInputField.getCardholderName())")
        logger.debug(message: "Form Valid State: \(isValid)")
    }
}

@available(iOS 15.0, *)
extension CardNumberInputField {
    func onCardNetworkChange(_ handler: @escaping (CardNetwork) -> Void) -> Self {
        var view = self
        view.onCardNetworkChange = handler
        return view
    }

    func onValidationChange(_ handler: @escaping (Bool) -> Void) -> Self {
        var view = self
        view.onValidationChange = handler
        return view
    }
}

@available(iOS 15.0, *)
extension CVVInputField {
    func onValidationChange(_ handler: @escaping (Bool) -> Void) -> Self {
        var view = self
        view.onValidationChange = handler
        return view
    }
}
