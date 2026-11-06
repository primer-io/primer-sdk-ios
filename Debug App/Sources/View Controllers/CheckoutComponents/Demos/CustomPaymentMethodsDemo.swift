//
//  CustomPaymentMethodsDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Custom Payment Methods — replace each row with your own view through the `method` slot, while the
/// SDK still owns the list, loading, and selection.
@available(iOS 15.0, *)
struct CustomPaymentMethodsDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            key: .customPaymentMethods,
            name: "Custom Payment Methods",
            description: "Custom row via the method slot",
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
            CustomPaymentMethodsContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct CustomPaymentMethodsContent: View {
    @StateObject private var session: PrimerCheckoutSession

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    var body: some View {
        ScrollView {
            switch session.phase {
            case .initializing:
                ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
            case .ready:
                PrimerPaymentMethods(method: { method, onSelect in
                    CustomPaymentMethodRow(name: method.name, onSelect: onSelect)
                })
                .padding(16)
            }
        }
        .demoCheckout(session)
    }
}

@available(iOS 15.0, *)
private struct CustomPaymentMethodRow: View {
    let name: String
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(name).fontWeight(.medium)
                Spacer()
                Text("→")
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.vertical, 6)
    }
}
