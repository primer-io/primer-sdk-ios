//
//  MerchantNavigationDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Merchant Navigation — a tabbed Checkout + Profile experience with screen-to-screen navigation, all
/// sharing one inline ``PrimerCheckoutSession``.
@available(iOS 15.0, *)
struct MerchantNavigationDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            name: "Merchant Navigation",
            description: "Tabbed checkout + profile navigation",
            tags: ["PAYMENT_CARD", "VAULT"],
            isCustom: true,
            category: .navigation
        )
    }

    let configuration: DemoConfiguration

    init(configuration: DemoConfiguration) {
        self.configuration = configuration
    }

    var body: some View {
        DemoScaffold(configuration: configuration, title: Self.metadata.name) { clientToken in
            MerchantNavigationContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct MerchantNavigationContent: View {
    @StateObject private var session: PrimerCheckoutSession
    @State private var tab: Tab = .checkout
    @State private var checkoutScreen: CheckoutScreen = .methods

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    private enum Tab { case checkout, profile }
    private enum CheckoutScreen { case methods, cardForm }

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            tabBar
        }
        .primerCheckoutSession(session) { state in
            if case .success = state { checkoutScreen = .methods }
        }
    }

    @ViewBuilder private var content: some View {
        switch tab {
        case .checkout:
            switch session.phase {
            case .initializing:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .ready:
                switch checkoutScreen {
                case .methods: methodsScreen
                case .cardForm: cardFormScreen
                }
            }
        case .profile:
            profileScreen
        }
    }

    private var methodsScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order #12345").font(.headline)
                    Text("Total: €10.00").font(.title2.weight(.bold)).foregroundStyle(Color.accentColor)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("How would you like to pay?").font(.headline)

                PrimerPaymentMethods(method: { method, onSelect in
                    let isCard = method.type == "PAYMENT_CARD"
                    Button {
                        if isCard { checkoutScreen = .cardForm } else { onSelect() }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(method.name).fontWeight(.medium)
                                if isCard {
                                    Text("Enter card details").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text("→").foregroundStyle(.secondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(isCard ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                })
            }
            .padding(16)
        }
    }

    private var cardFormScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Button { checkoutScreen = .methods } label: {
                    HStack { Image(systemName: "chevron.left"); Text("Back") }
                }
                HStack {
                    Text("🔒")
                    Text("Your payment is secure and encrypted")
                        .font(.caption).foregroundStyle(.green)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                PrimerCardForm()
            }
            .padding(16)
        }
    }

    private var profileScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 16) {
                    Text("JD")
                        .font(.title2.weight(.bold)).foregroundStyle(.white)
                        .frame(width: 60, height: 60).background(Color.accentColor).clipShape(Circle())
                    VStack(alignment: .leading) {
                        Text("John Doe").font(.headline)
                        Text("john.doe@example.com").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("Saved Payment Methods").font(.headline)

                if session.phase == .ready {
                    PrimerVaultedPaymentMethods()
                } else {
                    ProgressView()
                }
            }
            .padding(16)
        }
    }

    private var tabBar: some View {
        HStack {
            tabButton(.checkout, "cart", "Checkout")
            tabButton(.profile, "person", "Profile")
        }
        .padding(.top, 8)
    }

    private func tabButton(_ value: Tab, _ icon: String, _ label: String) -> some View {
        Button {
            tab = value
            if value == .checkout { checkoutScreen = .methods }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                Text(label).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(tab == value ? Color.accentColor : .secondary)
        }
    }
}
