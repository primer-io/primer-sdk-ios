//
//  DynamicVaultDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Dynamic Vault — a fully custom single-page checkout layout (a product card with the card form
/// embedded below). Per-form `vaultOnSuccess` toggling isn't exposed on ``PrimerCardFormSession`` yet,
/// so the save-card control is shown disabled to mark the gap.
@available(iOS 15.0, *)
struct DynamicVaultDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            name: "Dynamic Vault",
            description: "Custom single-page checkout layout",
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
            DynamicVaultContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct DynamicVaultContent: View {
    @StateObject private var session: PrimerCheckoutSession

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                productCard

                switch session.phase {
                case .initializing:
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 24)
                case .ready:
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pay with card").font(.headline)
                        PrimerCardForm()
                        Toggle("Save card for future payments", isOn: .constant(false))
                            .disabled(true)
                        Text("Per-form vault toggling isn't exposed on iOS yet.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .demoCheckout(session)
    }

    private var productCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🇷🇴 Romania").font(.largeTitle.weight(.bold))
            Divider()
            Text("Package").font(.caption).foregroundStyle(.secondary)
            infoRow(icon: "location", label: "Coverage", value: "Romania")
            infoRow(icon: "info.circle", label: "Data", value: "1 GB")
            infoRow(icon: "calendar", label: "Validity", value: "3 days")
            HStack {
                Image(systemName: "star.fill").foregroundStyle(.orange)
                Text("You'll earn 0.20 € in cashback from this purchase").font(.caption)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.bold)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
