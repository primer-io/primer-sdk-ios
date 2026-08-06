//
//  PaymentMethodListOnlyDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Payment Methods Only — render just the list. Tapping a method (e.g. card) lets the SDK open the
/// follow-up flow automatically via the inline flow host.
@available(iOS 15.0, *)
struct PaymentMethodListOnlyDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            name: "Payment Methods Only",
            description: "Inline list — card form opens automatically",
            tags: ["PAYMENT_CARD", "APM"],
            isCustom: true,
            category: .paymentMethods
        )
    }

    let configuration: DemoConfiguration

    init(configuration: DemoConfiguration) {
        self.configuration = configuration
    }

    var body: some View {
        DemoScaffold(configuration: configuration, title: Self.metadata.name) { clientToken in
            PaymentMethodListOnlyContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct PaymentMethodListOnlyContent: View {
    @StateObject private var session: PrimerCheckoutSession

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Payment Method").font(.title2.weight(.bold))
                Text("Tap any method — the card form opens automatically")
                    .font(.subheadline).foregroundStyle(.secondary)

                switch session.phase {
                case .initializing:
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 24)
                case .ready:
                    PrimerPaymentMethods().padding(.top, 16)
                }
            }
            .padding(16)
        }
        .demoCheckout(session)
    }
}
