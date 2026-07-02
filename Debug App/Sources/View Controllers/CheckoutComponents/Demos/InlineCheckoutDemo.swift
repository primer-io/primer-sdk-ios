//
//  InlineCheckoutDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Inline Checkout — embed the card form and the remaining payment methods directly in your own
/// layout instead of presenting the managed sheet. Any Primer composable placed under
/// `.primerCheckoutSession(_:)` resolves its session from the environment.
@available(iOS 15.0, *)
struct InlineCheckoutDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            name: "Inline Checkout",
            description: "Embedded card form with other payment methods",
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
            InlineCheckoutContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct InlineCheckoutContent: View {
    @StateObject private var session: PrimerCheckoutSession

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                switch session.phase {
                case .initializing:
                    ProgressView().padding(.top, 40)
                case .ready:
                    PrimerCardForm()
                    // The card form is rendered above, so omit the card row from the list.
                    PrimerPaymentMethods(method: { method, onSelect in
                        if method.type != "PAYMENT_CARD" {
                            PaymentMethodsDefaults.method(method, onSelect: onSelect)
                        }
                    })
                }
            }
            .padding(16)
        }
        .demoCheckout(session)
    }
}
