//
//  CustomCardFormDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Fully Custom Card Form — build your own fields and submit button, driven entirely by
/// ``PrimerCardFormSession``. Read values from `state.data`, push edits through the `update…`
/// methods, gate the button on `state.isValid`, and call `submit()`.
@available(iOS 15.0, *)
struct CustomCardFormDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            key: .customCardForm,
            name: "Fully Custom Card Form",
            description: "Build your own form with PrimerCardFormSession",
            tags: ["PAYMENT_CARD"],
            isCustom: true,
            category: .core
        )
    }

    let configuration: DemoConfiguration

    init(configuration: DemoConfiguration) {
        self.configuration = configuration
    }

    var body: some View {
        DemoScaffold(configuration: configuration, title: Self.metadata.name) { clientToken in
            CustomCardFormContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct CustomCardFormContent: View {
    @StateObject private var session: PrimerCheckoutSession

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom Card Form").font(.title2.weight(.bold))
                Text("Fully custom UI driven by PrimerCardFormSession")
                    .font(.subheadline).foregroundStyle(.secondary)

                switch session.phase {
                case .initializing:
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 24)
                case .ready:
                    if let cardForm = session.cardForm {
                        CustomCardFields(cardForm: cardForm).padding(.top, 16)
                    } else {
                        Text("Card payment method not available").foregroundStyle(.red)
                    }
                }
            }
            .padding(16)
        }
        .demoCheckout(session)
    }
}

@available(iOS 15.0, *)
private struct CustomCardFields: View {
    @ObservedObject var cardForm: PrimerCardFormSession

    var body: some View {
        let state = cardForm.state
        VStack(alignment: .leading, spacing: 16) {
            field("Card Number", placeholder: "4242 4242 4242 4242", text: cardNumber)
                .keyboardType(.numberPad)

            HStack(spacing: 12) {
                field("Expiry", placeholder: "MM/YY", text: expiry).keyboardType(.numberPad)
                field("CVV", placeholder: "123", text: cvv).keyboardType(.numberPad)
            }

            if state.configuration.cardFields.contains(.cardholderName) {
                field("Cardholder Name", placeholder: "John Doe", text: cardholderName)
            }

            Text(state.isValid ? "Form is valid" : "Please complete all fields")
                .font(.footnote)
                .foregroundStyle(state.isValid ? .green : .secondary)

            Button(action: cardForm.submit) {
                Group {
                    if state.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Pay Now").font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!state.isValid || state.isLoading)
        }
    }

    private func field(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.roundedBorder)
            .autocorrectionDisabled()
            .accessibilityLabel(label)
    }

    private var cardNumber: Binding<String> {
        Binding(
            get: { cardForm.state.data[.cardNumber] },
            set: { cardForm.updateCardNumber(String($0.filter(\.isNumber).prefix(19))) }
        )
    }

    private var cvv: Binding<String> {
        Binding(
            get: { cardForm.state.data[.cvv] },
            set: { cardForm.updateCvv(String($0.filter(\.isNumber).prefix(4))) }
        )
    }

    private var cardholderName: Binding<String> {
        Binding(
            get: { cardForm.state.data[.cardholderName] },
            set: { cardForm.updateCardholderName($0) }
        )
    }

    private var expiry: Binding<String> {
        Binding(
            get: { cardForm.state.data[.expiryDate] },
            set: { value in
                let digits = String(value.filter(\.isNumber).prefix(4))
                let formatted = digits.count > 2
                    ? "\(digits.prefix(2))/\(digits.dropFirst(2))"
                    : digits
                cardForm.updateExpiryDate(formatted)
            }
        )
    }
}
