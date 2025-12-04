//
//  CheckoutComponentsExamplesView.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import PrimerSDK

@available(iOS 15.0, *)
struct CheckoutComponentsExamplesView: View {
    private let settings: PrimerSettings
    private let apiVersion: PrimerApiVersion
    private let clientSession: ClientSessionRequestBody?

    @State private var presentedExample: ExampleConfig?

    init(settings: PrimerSettings, apiVersion: PrimerApiVersion, clientSession: ClientSessionRequestBody? = nil) {
        self.settings = settings
        self.apiVersion = apiVersion
        self.clientSession = clientSession
    }

    var body: some View {
        List {
            ForEach(allExamples) { example in
                ExampleRow(
                    example: example,
                    onTap: {
                        presentedExample = example
                    }
                )
            }
        }
        .navigationTitle("Examples")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $presentedExample) { example in
            CheckoutExampleView(
                example: example,
                settings: settings,
                apiVersion: apiVersion,
                clientSession: clientSession
            )
        }
    }
}

// MARK: - Example Row View

@available(iOS 15.0, *)
private struct ExampleRow: View {
    fileprivate let example: ExampleConfig
    fileprivate let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(example.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if example.isCustom {
                        Text("Custom")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                    }
                }

                Text(example.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    Text("Payment Methods:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(example.paymentMethods.joined(separator: ", "))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
