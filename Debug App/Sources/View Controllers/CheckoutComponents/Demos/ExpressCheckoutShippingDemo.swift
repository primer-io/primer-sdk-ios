//
//  ExpressCheckoutShippingDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Express Checkout shipping — supply shipping options for the shopper's address while the Apple Pay
/// sheet is open, and commit the selection so Primer recomputes the authoritative total.
///
/// Stands in for a merchant backend: the options are computed locally from the address, and the commit
/// PATCHes the client session. A real integration does the PATCH server-side with its secret API key.
///
/// Turn on "Capture shipping details" and "Require shipping method" in the app's Apple Pay settings
/// first — Apple only sends a shipping contact when the sheet asks for one.
@available(iOS 15.0, *)
struct ExpressCheckoutShippingDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            key: .expressCheckoutShipping,
            name: "Express Checkout Shipping",
            description: "Apple Pay shipping options from the app, committed per selection",
            tags: ["APPLE_PAY"],
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
            ExpressCheckoutShippingContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct ExpressCheckoutShippingContent: View {
    @StateObject private var session: PrimerCheckoutSession
    @StateObject private var log = ShippingLog()
    private let clientToken: String

    init(clientToken: String, settings: PrimerSettings) {
        self.clientToken = clientToken
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Express Checkout Shipping").font(.title2.weight(.bold))
                Text("Pick Apple Pay, then change the shipping address and method in the sheet")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("Needs \"Capture shipping details\" and \"Require shipping method\" in Apple Pay settings")
                    .font(.caption).foregroundStyle(.secondary)

                switch session.phase {
                case .initializing:
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 24)
                case .ready:
                    PrimerPaymentMethods().padding(.top, 16)
                }

                if !log.entries.isEmpty {
                    Text("Callback log").font(.headline).padding(.top, 16)
                    ForEach(Array(log.entries.enumerated()), id: \.offset) { _, entry in
                        Text(entry).font(.caption.monospaced())
                    }
                }
            }
            .padding(16)
        }
        .demoCheckout(session)
        .onAppear {
            let (log, clientToken) = (log, clientToken)
            session.shippingCallbacks = PrimerShippingCallbacks(
                onShippingAddressChange: { address in
                    await log.record("address → \(address.countryCode ?? "??") \(address.postalCode ?? "")")
                    return MerchantShippingBackend.options(for: address)
                },
                onShippingOptionChange: { option in
                    await log.record("commit → \(option.id) @ \(option.amount)")
                    try await MerchantShippingBackend.commit(option, clientToken: clientToken)
                    await log.record("commit ok → \(option.id)")
                }
            )
        }
    }
}

/// Stands in for the merchant's own backend.
@available(iOS 15.0, *)
private enum MerchantShippingBackend {

    /// An unserviceable country proves the empty-list path: Apple shows its own "cannot deliver to
    /// this address" error in the sheet and nothing is charged.
    private static let unserviceableCountryCodes = ["AQ", "KP"]

    static func options(for address: PrimerAddress) -> [PrimerShippingOption] {
        guard let country = address.countryCode, !unserviceableCountryCodes.contains(country) else {
            return []
        }

        let isDomestic = country == "GB"
        return [
            PrimerShippingOption(
                id: "standard",
                name: "Standard",
                description: isDomestic ? "3-5 business days" : "7-10 business days",
                amount: isDomestic ? 500 : 1200
            ),
            PrimerShippingOption(
                id: "express",
                name: "Express",
                description: isDomestic ? "Next business day" : "2-3 business days",
                amount: isDomestic ? 1500 : 2800
            )
        ]
    }

    /// A real merchant PATCHes from its backend with a secret API key. The demo goes direct so the
    /// flow can be exercised end to end from the simulator.
    static func commit(_ option: PrimerShippingOption, clientToken: String) async throws {
        try await NetworkingUtils.patchClientSessionShipping(
            clientToken: clientToken,
            methodId: option.id,
            methodName: option.name,
            methodDescription: option.description,
            amount: option.amount
        )
    }
}

@available(iOS 15.0, *)
@MainActor
private final class ShippingLog: ObservableObject {
    @Published private(set) var entries: [String] = []

    func record(_ entry: String) {
        entries.append(entry)
    }
}
