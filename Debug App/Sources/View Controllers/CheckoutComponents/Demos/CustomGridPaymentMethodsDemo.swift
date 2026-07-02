//
//  CustomGridPaymentMethodsDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Custom Grid — lay the payment methods out in a two-column grid built from the selection session's
/// own `state.paymentMethods`, calling `select(_:)` on tap.
@available(iOS 15.0, *)
struct CustomGridPaymentMethodsDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            name: "Custom Grid",
            description: "Two-column grid of payment methods",
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
            CustomGridContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct CustomGridContent: View {
    @StateObject private var session: PrimerCheckoutSession

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose Payment Method").font(.title2.weight(.bold))
                Text("Custom 2-column grid via PrimerSelectionSession")
                    .font(.subheadline).foregroundStyle(.secondary)

                switch session.phase {
                case .initializing:
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 24)
                case .ready:
                    if let selection = session.selection {
                        PaymentMethodGrid(selection: selection).padding(.top, 16)
                    }
                }
            }
            .padding(16)
        }
        .demoCheckout(session)
    }
}

@available(iOS 15.0, *)
private struct PaymentMethodGrid: View {
    @ObservedObject var selection: PrimerSelectionSession

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(selection.state.paymentMethods) { method in
                Button { selection.select(method) } label: {
                    VStack(spacing: 12) {
                        Text(method.type.prefix(2).uppercased())
                            .font(.headline)
                            .frame(width: 48, height: 48)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text(method.name)
                            .font(.subheadline.weight(.medium))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1.2, contentMode: .fit)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
