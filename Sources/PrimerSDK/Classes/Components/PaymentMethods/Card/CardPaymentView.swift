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

    // Reference to the input field for direct access - initialize with a proper reference
    @State private var cardInputField = CardNumberInputField(
        label: "Card Number",
        placeholder: "4242 4242 4242 4242",
        onCardNetworkChange: nil,
        onValidationChange: nil
    )

    // Form state
    @State private var expiryMonth: String = ""
    @State private var expiryYear: String = ""
    @State private var cvv: String = ""
    @State private var cardholderName: String = ""
    @State private var isValid: Bool = false
    @State private var isSubmitting: Bool = false

    // Card network state
    @State private var currentCardNetwork: CardNetwork = .unknown

    @Environment(\.designTokens) private var tokens

    var body: some View {
        VStack(spacing: 16) {
            // Card number field with direct callbacks
            cardInputField
                .onCardNetworkChange { network in
                    currentCardNetwork = network
                    Task {
                        await scope.updateCardNetwork(network)
                    }
                }
                .onValidationChange { isCardNumberValid in
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

                // CVV field
                VStack(alignment: .leading, spacing: 4) {
                    Text("CVV")
                        .font(.caption)
                        .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                    TextField("123", text: $cvv)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: cvv) { newValue in
                            Task {
                                scope.updateCvv(newValue)
                            }
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
                    expiryMonth = state.expiryMonth
                    expiryYear = state.expiryYear
                    cvv = state.cvv
                    cardholderName = state.cardholderName
                    isValid = state.isValid
                }
            }
        }
    }
}

// MARK: - Helper Extension for CardPaymentMethodScope

extension CardPaymentMethodScope {
    /// Update the card network when it changes.
    func updateCardNetwork(_ network: CardNetwork) async {
        // Implement your network update logic here.
    }
}

// Extension for applying the callback functions via view modifiers
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
