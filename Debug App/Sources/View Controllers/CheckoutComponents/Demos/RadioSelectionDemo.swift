//
//  RadioSelectionDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Radio Selection — present the payment methods as a radio group with a floating Pay button that
/// pays the chosen method only on confirmation. The inline session doesn't surface the order total,
/// so the summary uses the demo's known sandbox amount.
@available(iOS 15.0, *)
struct RadioSelectionDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            key: .radioSelection,
            name: "Radio Selection",
            description: "Radio group with a floating Pay button",
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
            RadioSelectionContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct RadioSelectionContent: View {
    @StateObject private var session: PrimerCheckoutSession

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    var body: some View {
        Group {
            switch session.phase {
            case .initializing:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .ready:
                if let selection = session.selection {
                    RadioContent(selection: selection)
                }
            }
        }
        .demoCheckout(session)
    }
}

@available(iOS 15.0, *)
private struct RadioContent: View {
    @ObservedObject var selection: PrimerSelectionSession
    @State private var selected: CheckoutPaymentMethod?

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    Text("Select Payment Method")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    methodsCard
                }
                .padding(16)
                .padding(.bottom, 100)
            }

            if let selected {
                payBar(for: selected)
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order Summary").font(.headline)
            HStack {
                Text("Premium Subscription").foregroundStyle(.secondary)
                Spacer()
                Text("€10.00")
            }
            Divider()
            HStack {
                Text("Total due today").fontWeight(.bold)
                Spacer()
                Text("€10.00").fontWeight(.bold)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var methodsCard: some View {
        VStack(spacing: 0) {
            ForEach(selection.state.paymentMethods) { method in
                Button { selected = method } label: {
                    HStack(spacing: 12) {
                        Image(systemName: selected?.id == method.id ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(selected?.id == method.id ? Color.accentColor : .secondary)
                        VStack(alignment: .leading) {
                            Text(method.name)
                                .fontWeight(selected?.id == method.id ? .medium : .regular)
                            Text(method.type).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if method.id != selection.state.paymentMethods.last?.id { Divider() }
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func payBar(for method: CheckoutPaymentMethod) -> some View {
        VStack(spacing: 8) {
            Text("Selected: \(method.name)")
                .font(.subheadline).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button { selection.select(method) } label: {
                Text("Pay with \(method.name)")
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(.regularMaterial)
    }
}
