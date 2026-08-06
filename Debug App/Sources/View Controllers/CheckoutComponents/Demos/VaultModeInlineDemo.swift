//
//  VaultModeInlineDemo.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Vault Mode Inline — custom navigation that saves a new method: pick a method, enter card details
/// on a dedicated screen, and show the resulting token.
@available(iOS 15.0, *)
struct VaultModeInlineDemo: View, CheckoutComponentsDemo {
    static var metadata: DemoMetadata {
        DemoMetadata(
            name: "Vault Mode Inline",
            description: "Select card → enter details → token shown",
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
            VaultModeInlineContent(clientToken: clientToken, settings: configuration.settings)
        }
    }
}

@available(iOS 15.0, *)
private struct VaultModeInlineContent: View {
    @StateObject private var session: PrimerCheckoutSession
    @State private var screen: Screen = .list
    @State private var lastToken: String?

    init(clientToken: String, settings: PrimerSettings) {
        _session = StateObject(wrappedValue: PrimerCheckoutSession(clientToken: clientToken, settings: settings))
    }

    private enum Screen { case list, cardForm }

    var body: some View {
        Group {
            switch session.phase {
            case .initializing:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .ready:
                switch screen {
                case .list: listScreen
                case .cardForm: cardFormScreen
                }
            }
        }
        .primerCheckoutSession(session) { state in
            switch state {
            case let .success(result):
                lastToken = result.paymentId
                screen = .list
            case .failure:
                screen = .list
            default:
                break
            }
        }
    }

    private var listScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Vault Mode").font(.title2.weight(.bold))
                Text("Save a new payment method to your vault")
                    .font(.subheadline).foregroundStyle(.secondary)

                if let lastToken {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Token Created Successfully!").font(.headline).foregroundStyle(.green)
                        Text("Token: \(lastToken.prefix(20))…").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text("Select a payment method to save:").font(.headline)

                PrimerPaymentMethods(method: { method, onSelect in
                    let isCard = method.type == "PAYMENT_CARD"
                    Button {
                        if isCard { screen = .cardForm } else { onSelect() }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(method.name).fontWeight(.medium)
                                if isCard {
                                    Text("Tap to enter card details")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text("→").font(.title3)
                                .foregroundStyle(isCard ? Color.accentColor : .secondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(isCard ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                })
            }
            .padding(16)
        }
    }

    private var cardFormScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Button { screen = .list } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back to Payment Methods").fontWeight(.medium)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter Card Details").font(.title2.weight(.bold))
                    Text("Your card will be saved for future payments")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                PrimerCardForm()
            }
            .padding(16)
        }
    }
}
