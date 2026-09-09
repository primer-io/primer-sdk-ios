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
            key: .beforePaymentGate,
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
    @State private var gate = PaymentGate()

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
                // The SDK may call this off the main actor; hop back before touching UI.
                Task { @MainActor in gate.request(decision) }
            }
        }
    }
}

/// Confirms the payment before the SDK creates it.
///
/// Auto-launching methods (Apple Pay, PayPal, web redirects) put the SDK's own sheet on screen the
/// moment they are selected, so a SwiftUI `.alert` attached to the merchant's inline content is
/// either covered by that sheet or dropped by UIKit mid-transition — leaving the decision handler
/// unresolved and the SDK suspended. Presenting from the top-most controller, and only once no
/// transition is in flight, keeps the gate reachable from every flow.
@available(iOS 15.0, *)
@MainActor
private final class PaymentGate {
    private static let retryDelay: TimeInterval = 0.1

    private var pending: ((PrimerPaymentCreationDecision) -> Void)?
    private var isPresenting = false

    private var topViewController: UIViewController? {
        var top = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }

    func request(_ decision: @escaping (PrimerPaymentCreationDecision) -> Void) {
        // A still-pending handler means the previous attempt was abandoned (shopper backed out).
        // Resolving it is mandatory: dropping it leaks the SDK's continuation and leaves that
        // payment task suspended forever.
        pending?(.abortPaymentCreation(withErrorMessage: "Payment attempt abandoned"))
        pending = decision
        presentConfirmation()
    }

    private func presentConfirmation() {
        // A retry may be queued from an earlier request — one alert resolves whatever is pending.
        guard !isPresenting else { return }

        guard let top = topViewController, top.transitionCoordinator == nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.retryDelay) { [self] in
                presentConfirmation()
            }
            return
        }

        let alert = UIAlertController(
            title: "Confirm payment",
            message: "Accept the terms to continue with your payment.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [self] _ in
            resolve(.abortPaymentCreation(withErrorMessage: "Terms not accepted"))
        })
        alert.addAction(UIAlertAction(title: "Accept & Pay", style: .default) { [self] _ in
            resolve(.continuePaymentCreation(withIdempotencyKey: UUID().uuidString))
        })
        isPresenting = true
        top.present(alert, animated: true)
    }

    private func resolve(_ decision: PrimerPaymentCreationDecision) {
        isPresenting = false
        pending?(decision)
        pending = nil
    }
}
