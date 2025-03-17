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

    // Reference to the input field for direct access
    @State private var cardNumberField: CardNumberInputField?

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
        if #available(iOS 15.0, *) {
            VStack(spacing: 16) {
                // Card number field - using the updated CardNumberInputField
                CardNumberInputField(
                    label: "Card Number",
                    placeholder: "4242 4242 4242 4242",
                    onCardNetworkChange: { network in
                        currentCardNetwork = network
                        // Update the scope with the detected card network
                        Task {
                            await scope.updateCardNetwork(network)
                        }
                    },
                    onValidationChange: { isCardNumberValid in
                        // Get card number directly from the field and update the scope
                        if let field = cardNumberField {
                            let cardNumber = field.getCardNumber()
                            Task {
                                scope.updateCardNumber(cardNumber)
                            }
                        }
                    }
                )

                // Expiry date and CVV row
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

                // Cardholder name field
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

                // Submit button
                Button {
                    isSubmitting = true
                    Task {
                        do {
                            let result = try await scope.submit()
                            print("Payment successful: \(result)")
                            // Handle successful payment
                        } catch {
                            print("Payment failed: \(error)")
                            // Handle payment failure
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
            .task {
                for await state in scope.state() {
                    if let state = state {
                        // Update the UI from the state
                        // Note: For card number, we don't directly set it
                        // as the field manages its own state
                        expiryMonth = state.expiryMonth
                        expiryYear = state.expiryYear
                        cvv = state.cvv
                        cardholderName = state.cardholderName
                        isValid = state.isValid
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            Text("Requires iOS 15 or later")
                .foregroundColor(.secondary)
                .padding()
        }
    }
}

// MARK: - Helper Extensions

extension CardPaymentMethodScope {
    /// Update the card network when it changes
    func updateCardNetwork(_ network: CardNetwork) async {
        // This method would need to be implemented in your CardPaymentMethodScope protocol
        // For now, it's a placeholder
    }
}
