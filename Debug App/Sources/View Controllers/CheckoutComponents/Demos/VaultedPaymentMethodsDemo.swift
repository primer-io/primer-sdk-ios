//
//  VaultedPaymentMethodsDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Vaulted Methods (Custom) — the default vaulted list alongside a fully custom row built through the
/// `item` slot, reading masked card data from the vaulted method.
@available(iOS 15.0, *)
struct VaultedPaymentMethodsDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            key: .vaultedPaymentMethods,
            name: "Vaulted Methods (Custom)",
            description: "Custom vaulted-card rows",
            tags: ["VAULT", "PAYMENT_CARD"],
            isCustom: true,
            category: .vault
        )
    }

    let configuration: DemoConfiguration

    init(configuration: DemoConfiguration) {
        self.configuration = configuration
    }

    var body: some View {
        DemoScaffold(configuration: configuration, title: Self.metadata.name) { clientToken in
            VaultedPaymentMethodsContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct VaultedPaymentMethodsContent: View {
    @StateObject private var session: PrimerCheckoutSession

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Vaulted Payment Methods").font(.title2.weight(.bold))

                switch session.phase {
                case .initializing:
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 24)
                case .ready:
                    section("1. Default Component", "Default styling") {
                        PrimerVaultedPaymentMethods()
                    }
                    section("2. Custom Rows", "Custom card UI via the item slot") {
                        PrimerVaultedPaymentMethods(item: { method, isSelected, onSelect in
                            AnyView(VaultedCardRow(method: method, isSelected: isSelected, onSelect: onSelect))
                        })
                    }
                }
            }
            .padding(16)
        }
        .demoCheckout(session)
    }

    private func section(_ title: String, _ subtitle: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

@available(iOS 15.0, *)
private struct VaultedCardRow: View {
    let method: PrimerVaultedPaymentMethods.VaultedMethod
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: "creditcard")
                    .font(.title2).foregroundStyle(.secondary)
                VStack(alignment: .leading) {
                    Text("•••• \(method.paymentInstrumentData.last4Digits ?? "****")")
                        .fontWeight(.medium)
                    Text(method.paymentInstrumentData.network ?? method.paymentMethodType)
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if let month = method.paymentInstrumentData.expirationMonth,
                   let year = method.paymentInstrumentData.expirationYear {
                    Text("\(month)/\(year)").font(.caption).foregroundStyle(.secondary)
                }
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}
