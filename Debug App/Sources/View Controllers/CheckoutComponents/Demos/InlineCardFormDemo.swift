//
//  InlineCardFormDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Inline Card Form — just the embedded card form, nothing else. `PrimerCardForm` with its default
/// slots, wired to an inline ``PrimerCheckoutSession``.
@available(iOS 15.0, *)
struct InlineCardFormDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            key: .inlineCardForm,
            name: "Inline Card Form",
            description: "Embedded card form via PrimerCheckoutSession",
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
            InlineCardFormContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct InlineCardFormContent: View {
    @StateObject private var session: PrimerCheckoutSession

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    var body: some View {
        ScrollView {
            switch session.phase {
            case .initializing:
                ProgressView().padding(.top, 40)
            case .ready:
                PrimerCardForm().padding(12)
            }
        }
        .demoCheckout(session)
    }
}
