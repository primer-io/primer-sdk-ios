//
//  RefreshClientSessionDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Refresh Client Session — verify `session.refresh()` re-fetches configuration and updates every
/// observer (state, payment methods, vault).
@available(iOS 15.0, *)
struct RefreshClientSessionDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            key: .refreshClientSession,
            name: "Refresh Client Session",
            description: "Verify refresh() updates state, methods, vault",
            tags: ["PAYMENT_CARD", "VAULT"],
            isCustom: true,
            category: .utility
        )
    }

    let configuration: DemoConfiguration

    init(configuration: DemoConfiguration) {
        self.configuration = configuration
    }

    var body: some View {
        DemoScaffold(configuration: configuration, title: Self.metadata.name) { clientToken in
            RefreshClientSessionContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct RefreshClientSessionContent: View {
    @StateObject private var session: PrimerCheckoutSession
    @State private var refreshCount = 0

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    private var isLoading: Bool { session.phase == .initializing }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Refresh Client Session").font(.title2.weight(.bold))
                Text("Verify that refresh() updates all observers")
                    .font(.subheadline).foregroundStyle(.secondary)

                stateCard

                Button {
                    refreshCount += 1
                    Task { await session.refresh() }
                } label: {
                    Text("Refresh Client Session").frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)

                if session.phase == .ready {
                    let methodCount = session.selection?.state.paymentMethods.count ?? 0
                    let vaultedCount = session.selection?.vaultedPaymentMethods.count ?? 0

                    Text("Payment Methods (\(methodCount))").font(.headline)
                    PrimerPaymentMethods()

                    Text("Vaulted Methods (\(vaultedCount))").font(.headline)
                    if vaultedCount == 0 {
                        Text("No saved payment methods").foregroundStyle(.secondary)
                    } else {
                        PrimerVaultedPaymentMethods()
                    }
                }
            }
            .padding(16)
        }
        .demoCheckout(session)
    }

    private var stateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Checkout State").font(.headline)
            stateRow("isLoading", "\(isLoading)")
            stateRow("phase", session.phase == .ready ? "ready" : "initializing")
            stateRow("refreshCount", "\(refreshCount)")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func stateRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }
}
