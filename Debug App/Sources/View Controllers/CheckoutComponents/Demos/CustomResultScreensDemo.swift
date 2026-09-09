//
//  CustomResultScreensDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Custom Result Screens — replace the loading, success, and error UI with your own. The inline
/// session drives a custom loading view while initializing, the SDK checkout when ready, and a custom
/// success/error screen from the terminal state delivered to `onCompletion`.
@available(iOS 15.0, *)
struct CustomResultScreensDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            key: .customResultScreens,
            name: "Custom Result Screens",
            description: "Custom loading, success, and error screens",
            tags: ["PAYMENT_CARD"],
            isCustom: true,
            category: .navigation
        )
    }

    let configuration: DemoConfiguration

    init(configuration: DemoConfiguration) {
        self.configuration = configuration
    }

    var body: some View {
        DemoScaffold(configuration: configuration, title: Self.metadata.name) { clientToken in
            CustomResultScreensContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct CustomResultScreensContent: View {
    @StateObject private var session: PrimerCheckoutSession
    @State private var outcome: PrimerCheckoutState?

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    var body: some View {
        Group {
            switch outcome {
            case let .success(result):
                CustomSuccessScreen(result: result)
            case let .failure(error):
                CustomErrorScreen(error: error)
            default:
                checkout
            }
        }
        .primerCheckoutSession(session) { state in
            switch state {
            case .success, .failure: outcome = state
            default: break
            }
        }
    }

    @ViewBuilder private var checkout: some View {
        switch session.phase {
        case .initializing:
            CustomLoadingScreen()
        case .ready:
            ScrollView {
                VStack(spacing: 24) {
                    PrimerPaymentMethods()
                    PrimerCardForm()
                }
                .padding(16)
            }
        }
    }
}

@available(iOS 15.0, *)
private struct CustomLoadingScreen: View {
    var body: some View {
        VStack(spacing: 24) {
            ProgressView().controlSize(.large).tint(Color(red: 0.38, green: 0, blue: 0.93))
            Text("Preparing your checkout…").font(.headline)
            Text("This will only take a moment").font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

@available(iOS 15.0, *)
private struct CustomSuccessScreen: View {
    let result: PaymentResult

    var body: some View {
        VStack(spacing: 16) {
            resultBadge(systemName: "checkmark", color: .green)
            Text("Payment Successful!").font(.title2.weight(.bold)).foregroundStyle(.green)
            Text("Thank you for your purchase").foregroundStyle(.secondary)

            VStack(spacing: 8) {
                row("Payment ID", String(result.paymentId.prefix(12)) + "…")
                if let amount = result.amount, let currency = result.currencyCode {
                    row("Amount", "\(amount) \(currency)")
                }
                row("Status", "\(result.status)")
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }
}

@available(iOS 15.0, *)
private struct CustomErrorScreen: View {
    let error: PrimerError

    var body: some View {
        VStack(spacing: 16) {
            resultBadge(systemName: "xmark", color: .red)
            Text("Payment Failed").font(.title2.weight(.bold)).foregroundStyle(.red)
            Text(error.localizedDescription)
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

@available(iOS 15.0, *)
@ViewBuilder
private func resultBadge(systemName: String, color: Color) -> some View {
    Image(systemName: systemName)
        .font(.system(size: 36, weight: .bold))
        .foregroundStyle(.white)
        .frame(width: 80, height: 80)
        .background(color)
        .clipShape(Circle())
}
