//
//  BeforePaymentGateDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Before Payment Gate — pause the SDK right before it creates the payment to confirm terms and
/// supply a per-attempt idempotency key. Set `session.onBeforePaymentCreate`; the SDK calls it with a
/// decision handler to continue (with an idempotency key) or abort.
@available(iOS 15.0, *)
struct BeforePaymentGateDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            name: "Before Payment Gate",
            description: "Confirm terms / set idempotency key before payment",
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
            BeforePaymentGateContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct BeforePaymentGateContent: View {
    @StateObject private var session: PrimerCheckoutSession
    @StateObject private var gate = PaymentGate()

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Before Payment Gate").font(.title2.weight(.bold))
                Text("Accept the terms before the payment is created")
                    .font(.subheadline).foregroundStyle(.secondary)

                switch session.phase {
                case .initializing:
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 24)
                case .ready:
                    PrimerCardForm().padding(.top, 16)
                    PrimerPaymentMethods(method: { method, onSelect in
                        if method.type != "PAYMENT_CARD" {
                            PaymentMethodsDefaults.method(method, onSelect: onSelect)
                        }
                    })
                }
            }
            .padding(16)
        }
        .demoCheckout(session)
        .onAppear {
            session.onBeforePaymentCreate = { _, decision in
                // The SDK may call this off the main actor; hop back before touching UI state.
                DispatchQueue.main.async { gate.pending = decision }
            }
        }
        .alert("Confirm payment", isPresented: gate.isPresented) {
            Button("Cancel", role: .cancel) {
                gate.resolve(.abortPaymentCreation(withErrorMessage: "Terms not accepted"))
            }
            Button("Accept & Pay") {
                gate.resolve(.continuePaymentCreation(withIdempotencyKey: UUID().uuidString))
            }
        } message: {
            Text("Accept the terms to continue with your payment.")
        }
    }
}

/// Holds the pending payment-creation decision so a SwiftUI alert can resolve it.
@available(iOS 15.0, *)
private final class PaymentGate: ObservableObject {
    @Published var pending: ((PrimerPaymentCreationDecision) -> Void)?

    var isPresented: Binding<Bool> {
        Binding(get: { self.pending != nil }, set: { if !$0 { self.pending = nil } })
    }

    func resolve(_ decision: PrimerPaymentCreationDecision) {
        pending?(decision)
        pending = nil
    }
}
