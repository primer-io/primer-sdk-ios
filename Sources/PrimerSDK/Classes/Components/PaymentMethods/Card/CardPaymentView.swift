//
//  CardPaymentView.swift
//
//  Created on 21.03.2025.
//

import SwiftUI

@available(iOS 15.0, *)
struct CardPaymentView: View, LogReporter {
    let scope: any CardPaymentMethodScope

    @State private var cardNumberValue = ""
    @State private var expiryDateValue = ""
    @State private var cvvValue = ""
    @State private var nameValue = ""
    @State private var isCardNumberValid = false
    @State private var isExpiryValid = false
    @State private var isCvvValid = false
    @State private var isNameValid = false
    @State private var isValid = false
    @State private var isSubmitting = false
    @State private var currentCardNetwork: CardNetwork = .unknown

    // Error states
    @State private var cardNumberError: String?
    @State private var expiryError: String?
    @State private var cvvError: String?
    @State private var nameError: String?

    @Environment(\.designTokens) private var tokens

    var body: some View {
        VStack(spacing: 16) {
            // MARK: Card Number
            CardNumberInputField(
                placeholder: "Card Number",
                onFormattedChange: { formatted in
                    let raw = formatted.filter { $0.isNumber }
                    cardNumberValue = raw
                    scope.updateCardNumber(raw)
                    // network detection now in closure
                    let network = CardNetwork(cardNumber: raw)
                    currentCardNetwork = network
                    scope.updateCardNetwork(network)
                },
                onValidationChange: { valid in
                    isCardNumberValid = valid
                    updateFormValidity()
                },
                onErrorChange: { errorMsg in
                    cardNumberError = errorMsg
                }
            )
            .primerTextFieldStyle(isError: cardNumberError != nil)
            .overlay(alignment: .bottomLeading) {
                errorOverlay(message: cardNumberError)
            }

            // MARK: Expiry + CVV
            HStack(spacing: 16) {
                ExpiryDateInputField(
                    placeholder: "MM/YY",
                    onFormattedChange: { formatted in
                        expiryDateValue = formatted
                        let parts = formatted.split(separator: "/")
                        if parts.count == 2 {
                            scope.updateExpiryMonth(String(parts[0]))
                            scope.updateExpiryYear(String(parts[1]))
                        }
                    },
                    onValidationChange: { valid in
                        isExpiryValid = valid
                        updateFormValidity()
                    },
                    onErrorChange: { errorMsg in
                        expiryError = errorMsg  // FIXED: Was cardNumberError
                    }
                )
                .primerTextFieldStyle(isError: expiryError != nil)  // Add isError parameter
                .overlay(alignment: .bottomLeading) {
                    errorOverlay(message: expiryError)
                }

                CVVInputField(
                    placeholder: currentCardNetwork == .amex ? "1234" : "123",
                    cardNetwork: currentCardNetwork,
                    onFormattedChange: { formatted in
                        cvvValue = formatted
                        scope.updateCvv(formatted)
                    },
                    onValidationChange: { valid in
                        isCvvValid = valid
                        updateFormValidity()
                    },
                    onErrorChange: { errorMsg in
                        cvvError = errorMsg  // FIXED: Was cardNumberError
                    }
                )
                .primerTextFieldStyle(isError: cvvError != nil)  // Add isError parameter
                .overlay(alignment: .bottomLeading) {
                    errorOverlay(message: cvvError)
                }
            }

            // MARK: Cardholder Name
            CardholderNameInputField(
                placeholder: "Cardholder Name",
                onFormattedChange: { formatted in
                    nameValue = formatted
                    scope.updateCardholderName(formatted)
                },
                onValidationChange: { valid in
                    isNameValid = valid
                    updateFormValidity()
                },
                onErrorChange: { errorMsg in
                    nameError = errorMsg  // FIXED: Was cardNumberError
                }
            )
            .primerTextFieldStyle(isError: nameError != nil)  // Add isError parameter
            .overlay(alignment: .bottomLeading) {
                errorOverlay(message: nameError)
            }

            // MARK: Pay Button
            Button {
                isSubmitting = true
                Task {
                    do {
                        _ = try await scope.submit()
                        // success handling…
                    } catch {
                        // failure handling…
                    }
                    isSubmitting = false
                }
            } label: {
                Text(isSubmitting ? "Processing…" : "Pay")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValid
                                    ? (tokens?.primerColorBrand ?? .blue)
                                    : (tokens?.primerColorGray400 ?? .gray))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!isValid || isSubmitting)
        }
        .padding(16)
    }

    @ViewBuilder
    private func errorOverlay(message: String?) -> some View {
        if let errorMessage = message {
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.red)
                .padding(.top, 2)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.7))  // Add a semi-transparent background
        } else {
            Color.clear.frame(height: 0)  // Empty placeholder when no error
        }
    }
    
    private func updateFormValidity() {
        isValid = isCardNumberValid
            && isExpiryValid
            && isCvvValid
            && isNameValid
            && !cardNumberValue.isEmpty
            && !expiryDateValue.isEmpty
            && !cvvValue.isEmpty
            && !nameValue.isEmpty
    }
}
