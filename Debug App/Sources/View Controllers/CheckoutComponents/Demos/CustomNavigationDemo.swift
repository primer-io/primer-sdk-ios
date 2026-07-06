//
//  CustomNavigationDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Custom Navigation — a custom success screen whose "View Order Details" button navigates to an
/// in-app order details view, pushed onto the surrounding navigation stack.
@available(iOS 15.0, *)
struct CustomNavigationDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            name: "Custom Navigation",
            description: "Success screen navigates to order details",
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
            CustomNavigationContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct CustomNavigationContent: View {
    @StateObject private var session: PrimerCheckoutSession
    @State private var outcome: PrimerCheckoutState?

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    var body: some View {
        Group {
            switch outcome {
            case let .success(result):
                SuccessWithNavigation(result: result)
            case let .failure(error):
                ErrorWithSupport(error: error)
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
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
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
private struct SuccessWithNavigation: View {
    let result: PaymentResult

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark")
                .font(.system(size: 36, weight: .bold)).foregroundStyle(.white)
                .frame(width: 80, height: 80).background(.green).clipShape(Circle())
            Text("Payment Successful!").font(.title2.weight(.bold)).foregroundStyle(.green)
            Text("Order #\(result.paymentId.prefix(8))").foregroundStyle(.secondary)

            NavigationLink {
                OrderDetailsScreen(orderId: result.paymentId)
            } label: {
                Text("View Order Details").frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)

            Button("Continue Shopping") {}
                .frame(maxWidth: .infinity, minHeight: 50)
                .buttonStyle(.bordered)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

@available(iOS 15.0, *)
private struct ErrorWithSupport: View {
    let error: PrimerError

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark")
                .font(.system(size: 36, weight: .bold)).foregroundStyle(.white)
                .frame(width: 80, height: 80).background(.red).clipShape(Circle())
            Text("Payment Failed").font(.title2.weight(.bold)).foregroundStyle(.red)
            Text(error.localizedDescription)
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            Button("Contact Support") {}
                .frame(maxWidth: .infinity, minHeight: 50)
                .buttonStyle(.bordered)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

@available(iOS 15.0, *)
private struct OrderDetailsScreen: View {
    let orderId: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Order Details").font(.title.weight(.bold))
                VStack(alignment: .leading, spacing: 16) {
                    labeled("Order ID", orderId)
                    labeled("Status", "✓ Payment Confirmed")
                    Text("Navigated here from the custom success screen.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(16)
        }
        .navigationTitle("Order")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func labeled(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).fontWeight(.medium)
        }
    }
}
