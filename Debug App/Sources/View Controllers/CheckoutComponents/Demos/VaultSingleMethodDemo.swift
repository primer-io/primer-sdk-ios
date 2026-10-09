//
//  VaultSingleMethodDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Save With Own Button — the app's own button saves one method, with no SDK method list, splash,
/// success or error screen. The method's own screen still opens in the SDK sheet.
@available(iOS 15.0, *)
struct VaultSingleMethodDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            key: .vaultSingleMethod,
            name: "Save With Own Button",
            description: "App button saves one method, no SDK list or result screens",
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
            VaultSingleMethodContent(clientToken: clientToken, settings: configuration.settings.withMerchantResultScreens)
        }
    }
}

@available(iOS 15.0, *)
private struct VaultSingleMethodContent: View {
    @StateObject private var session: PrimerCheckoutSession
    @State private var result: String?

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(
            wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings, intent: .vault)
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            if let result {
                Text(result).font(.headline).multilineTextAlignment(.center)
            }
            if let selection = session.selection {
                SaveButton(selection: selection)
            } else {
                ProgressView()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .primerCheckoutSession(session) { state in
            switch state {
            case let .vaulted(saved): result = "Saved: \(saved.token.prefix(12))…"
            case .failure: result = "The save failed"
            default: break
            }
        }
    }
}

@available(iOS 15.0, *)
private struct SaveButton: View {
    @ObservedObject var selection: PrimerSelectionSession

    /// Cards only for now, because CheckoutComponents cannot save other methods yet.
    private let methodType = "PAYMENT_CARD"

    var body: some View {
        let method = selection.state.paymentMethods.first { $0.type == methodType }
        Button("Save card") {
            if let method { selection.select(method) }
        }
        .buttonStyle(.borderedProminent)
        .disabled(method == nil)
    }
}
