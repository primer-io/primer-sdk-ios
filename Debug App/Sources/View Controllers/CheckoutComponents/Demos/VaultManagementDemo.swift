//
//  VaultManagementDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Vault Management — show saved (vaulted) payment methods above the available payment methods, both
/// with their default Primer components.
@available(iOS 15.0, *)
struct VaultManagementDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            key: .vaultManagement,
            name: "Vault Management",
            description: "Display and manage saved payment methods",
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
            VaultManagementContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct VaultManagementContent: View {
    @StateObject private var session: PrimerCheckoutSession

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Saved Payment Methods").font(.title2.weight(.bold))

                switch session.phase {
                case .initializing:
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 24)
                case .ready:
                    PrimerVaultedPaymentMethods()
                    Divider()
                    PrimerPaymentMethods()
                }
            }
            .padding(16)
        }
        .demoCheckout(session)
    }
}
