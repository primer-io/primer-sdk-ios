//
//  CardFormSheetDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Card Form Sheet — the default `PrimerCardForm` embedded inline beneath your own heading, showing
/// that it drops straight into a custom layout.
@available(iOS 15.0, *)
struct CardFormSheetDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            name: "Card Form Sheet",
            description: "Card form embedded beneath a custom heading",
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
            CardFormSheetContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct CardFormSheetContent: View {
    @StateObject private var session: PrimerCheckoutSession

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Card Form")
                    .font(.title2.weight(.bold))

                switch session.phase {
                case .initializing:
                    ProgressView().frame(maxWidth: .infinity)
                case .ready:
                    PrimerCardForm()
                }
            }
            .padding(16)
        }
        .demoCheckout(session)
    }
}
