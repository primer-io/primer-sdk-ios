//
//  PrefillCardholderNameDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Prefill Cardholder Name — read the customer from the client session and write their name into the
/// card form's cardholder field, leaving it editable.
///
/// The SDK never fills this in on its own: `customer.firstName` / `lastName` are order metadata, not
/// card data, so prefilling is the merchant's call.
@available(iOS 15.0, *)
struct PrefillCardholderNameDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            key: .prefillCardholderName,
            name: "Prefill Cardholder Name",
            description: "Prefill the card form from the client session's customer",
            tags: ["PAYMENT_CARD"],
            isCustom: true,
            category: .core
        )
    }

    let configuration: DemoConfiguration

    init(configuration: DemoConfiguration) {
        self.configuration = configuration
    }

    var body: some View {
        DemoScaffold(configuration: configuration, title: Self.metadata.name) { clientToken in
            PrefillCardholderNameContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct PrefillCardholderNameContent: View {
    @StateObject private var session: PrimerCheckoutSession
    @State private var prefilledName: String?

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    var body: some View {
        ScrollView {
            switch session.phase {
            case .initializing:
                ProgressView().padding(.top, 40)
            case .ready:
                VStack(alignment: .leading, spacing: 12) {
                    makeBanner()
                    PrimerCardForm()
                }
                .padding(12)
                .task { await prefillCardholderName() }
            }
        }
        .demoCheckout(session)
    }

    private func makeBanner() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(prefilledName == nil ? "Nothing prefilled" : "Prefilled from client session")
                .font(.subheadline.weight(.semibold))
            Text(bannerDetail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }

    private var bannerDetail: String {
        if let prefilledName {
            return "Cardholder name set to “\(prefilledName)” — edit it freely, the SDK will not overwrite it."
        }
        if customerName == nil {
            return "This client session carries no customer name, so the field is left untouched."
        }
        return "This session does not collect a cardholder name, so there is no field to prefill."
    }

    /// The name the merchant would show the customer, assembled the same way Android's demo does it.
    private var customerName: String? {
        let customer = session.clientSession?.customer
        let name = [customer?.firstName, customer?.lastName]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }

    private func prefillCardholderName() async {
        guard prefilledName == nil, let customerName, let cardForm = session.cardForm else { return }

        // iOS fills `configuration` in when the card-form scope is built, so the field list is already
        // the session's by the time `cardForm` resolves. Android has to await it, so keep a bounded
        // guard here rather than depending on that ordering.
        var attempts = 0
        while cardForm.state.configuration.cardFields.isEmpty, attempts < 50 {
            try? await Task.sleep(nanoseconds: 20_000_000)
            attempts += 1
        }

        // A session that does not collect the cardholder name has no field to write into.
        guard cardForm.state.configuration.cardFields.contains(.cardholderName) else { return }

        cardForm.updateCardholderName(customerName)
        prefilledName = customerName
    }
}
