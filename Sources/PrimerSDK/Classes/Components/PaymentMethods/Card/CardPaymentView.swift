//
//  CardPaymentView.swift
//
//
//  Created by Boris on 17.3.25..
//

import SwiftUI

/// Default UI for card payments.
@available(iOS 15.0, *)
struct CardPaymentView: View {
    let scope: any CardPaymentMethodScope

    // Reference to the input fields for direct access
    @State private var cardInputField = CardNumberInputField(
        label: "Card Number",
        placeholder: "4242 4242 4242 4242",
        onCardNetworkChange: nil,
        onValidationChange: nil
    )

    @State private var cvvInputField = CVVInputField(
        label: "CVV",
        placeholder: "123",
        cardNetwork: .unknown,
        onValidationChange: nil
    )

    // Form state
    @State private var expiryMonth: String = ""
    @State private var expiryYear: String = ""
    @State private var cvv: String = ""
    @State private var cardholderName: String = ""
    @State private var isValid: Bool = false
    @State private var isSubmitting: Bool = false

    // Input validation state
    @State private var isCardNumberValid: Bool = false
    @State private var isCvvValid: Bool = false

    // Card network state
    @State private var currentCardNetwork: CardNetwork = .unknown

    @Environment(\.designTokens) private var tokens

    var body: some View {
        VStack(spacing: 16) {
            // Card number field with direct callbacks
            cardInputField
                .onCardNetworkChange { network in
                    currentCardNetwork = network
                    // Update CVV field's card network to adjust validation rules
                    cvvInputField = CVVInputField(
                        label: "CVV",
                        placeholder: network == .amex ? "1234" : "123",
                        cardNetwork: network,
                        onValidationChange: cvvInputField.onValidationChange
                    )
                    Task {
                        await scope.updateCardNetwork(network)
                    }
                }
                .onValidationChange { isValid in
                    isCardNumberValid = isValid
                    updateFormValidity()

                    // Get card number directly from the field and update the scope
                    let cardNumber = cardInputField.getCardNumber()
                    Task {
                        scope.updateCardNumber(cardNumber)
                    }
                }

            // MARK: - Expiry Date and CVV Row
            HStack(spacing: 16) {
                // Expiry month/year fields
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expiry Date")
                        .font(.caption)
                        .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                    HStack(spacing: 8) {
                        TextField("MM", text: $expiryMonth)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                            .padding()
                            .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                            .cornerRadius(8)
                            .onChange(of: expiryMonth) { newValue in
                                Task {
                                    scope.updateExpiryMonth(newValue)
                                }
                            }

                        Text("/")
                            .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)

                        TextField("YY", text: $expiryYear)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                            .padding()
                            .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                            .cornerRadius(8)
                            .onChange(of: expiryYear) { newValue in
                                Task {
                                    scope.updateExpiryYear(newValue)
                                }
                            }
                    }
                }

                // CVV field - using our new CVVInputField component
                cvvInputField
                    .onValidationChange { isValid in
                        isCvvValid = isValid
                        updateFormValidity()

                        // Get CVV directly from the field and update the scope
                        let cvvValue = cvvInputField.getCVV()
                        cvv = cvvValue // Update local state
                        Task {
                            scope.updateCvv(cvvValue)
                        }
                    }
            }

            // MARK: - Cardholder Name Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Cardholder Name")
                    .font(.caption)
                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                TextField("John Doe", text: $cardholderName)
                    .padding()
                    .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                    .cornerRadius(8)
                    .onChange(of: cardholderName) { newValue in
                        Task {
                            scope.updateCardholderName(newValue)
                        }
                    }
            }

            // MARK: - Submit Button
            Button {
                isSubmitting = true
                Task {
                    do {
                        let result = try await scope.submit()
                        print("Payment successful: \(result)")
                        // Handle successful payment here
                    } catch {
                        print("Payment failed: \(error)")
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
                    // Note: The card number is now managed by CardNumberTextField
                    // Note: The CVV is now managed by CVVInputField
                    expiryMonth = state.expiryMonth
                    expiryYear = state.expiryYear
                    cardholderName = state.cardholderName

                    // We still use the scope's isValid for the overall form state
                    // but our local validity checks will influence this too
                    isValid = state.isValid && isCardNumberValid && isCvvValid
                }
            }
        }
    }

    /// Updates the overall form validity based on field-level validation
    private func updateFormValidity() {
        // This method can be expanded with additional validation logic
        // For now it just combines the individual field validations
        isValid = isCardNumberValid && isCvvValid &&
                  !expiryMonth.isEmpty && !expiryYear.isEmpty &&
                  !cardholderName.isEmpty
    }
}

// MARK: - Helper Extension for CardPaymentMethodScope

extension CardPaymentMethodScope {
    /// Update the card network when it changes.
    func updateCardNetwork(_ network: CardNetwork) async {
        // Implement your network update logic here.
    }
}

// MARK: - Extensions for applying callback functions via view modifiers

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
