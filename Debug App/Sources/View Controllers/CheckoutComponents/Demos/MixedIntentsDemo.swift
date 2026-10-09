//
//  MixedIntentsDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Mixed Intents — one session saves a card without a payment, while every other method pays.
@available(iOS 15.0, *)
struct MixedIntentsDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            key: .mixedIntents,
            name: "Mixed Intents",
            description: "Card saves without a payment, other methods pay",
            tags: ["VAULT", "PAYMENT_CARD"],
            isCustom: false,
            category: .vault
        )
    }

    let configuration: DemoConfiguration

    init(configuration: DemoConfiguration) {
        self.configuration = configuration
    }

    var body: some View {
        DemoScaffold(configuration: configuration, title: Self.metadata.name) { clientToken in
            MixedIntentsContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct MixedIntentsContent: View {
    let clientToken: String
    let settings: PrimerSettings
    @State private var result: String?

    var body: some View {
        if let result {
            Text(result)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            PrimerCheckout(
                clientToken: clientToken,
                primerSettings: settings,
                paymentMethodIntents: ["PAYMENT_CARD": .vault],
                onCompletion: { state in
                    switch state {
                    case let .vaulted(saved): result = "Card saved: \(saved.token.prefix(12))…"
                    case let .success(payment): result = "Paid: \(payment.paymentId)"
                    default: break
                    }
                }
            )
        }
    }
}
