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
                onErrorChange: { _ in }
            )
            .primerTextFieldStyle()

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
                    onErrorChange: { _ in }
                )
                .primerTextFieldStyle()

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
                    onErrorChange: { _ in }
                )
                .primerTextFieldStyle()
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
                onErrorChange: { _ in }
            )
            .primerTextFieldStyle()

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
