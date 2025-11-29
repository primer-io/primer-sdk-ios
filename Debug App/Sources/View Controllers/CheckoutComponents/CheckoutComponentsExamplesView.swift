//
//  CheckoutComponentsExamplesView.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

@available(iOS 15.0, *)
struct CheckoutComponentsExamplesView: View {
    private let settings: PrimerSettings
    private let apiVersion: PrimerApiVersion
    private let clientSession: ClientSessionRequestBody?

    init(settings: PrimerSettings, apiVersion: PrimerApiVersion, clientSession: ClientSessionRequestBody? = nil) {
        self.settings = settings
        self.apiVersion = apiVersion
        self.clientSession = clientSession
        // Initialize with settings, API version and optional client session
    }

    var body: some View {
        // Render main view body with example categories

        List {
            ForEach(ExampleCategory.allCases, id: \.self) { category in
                NavigationLink(
                    destination: CategoryExamplesView(
                        category: category,
                        settings: settings,
                        apiVersion: apiVersion,
                        clientSession: clientSession
                    )
                ) {
                    CategoryRow(category: category)
                }
            }
        }
    }
}

// MARK: - Category Row View

@available(iOS 15.0, *)
private struct CategoryRow: View {
    fileprivate let category: ExampleCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.rawValue)
                .font(.headline)
                .foregroundColor(.primary)

            Text(category.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Text("\(category.examples.count) examples")
                    .font(.caption)
                    .foregroundColor(.blue)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Category Examples View

@available(iOS 15.0, *)
private struct CategoryExamplesView: View {
    fileprivate let category: ExampleCategory
    fileprivate let settings: PrimerSettings
    fileprivate let apiVersion: PrimerApiVersion
    fileprivate let clientSession: ClientSessionRequestBody?

    @State private var presentedExample: ExampleConfig?

    var body: some View {
        List {
            ForEach(category.examples) { example in
                ExampleRow(
                    example: example,
                    onTap: {
                        presentedExample = example
                    }
                )
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $presentedExample) { example in
            CheckoutExampleView(
                example: example,
                settings: settings,
                apiVersion: apiVersion,
                clientSession: clientSession
            )
            .onAppear {
                // CheckoutExampleView appeared
            }
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
            makeVStack()
        }
        .buttonStyle(.plain)
    }

    private func makeVStack() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(example.name)
                .font(.headline)
                .foregroundColor(.primary)

            Text(example.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            makePaymentMethodsHStack()

            if let customization = example.customization {
                makeCustomizationHStack(customization: customization)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private func makePaymentMethodsHStack() -> some View {
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

    private func makeCustomizationHStack(customization: ExampleConfig.CheckoutCustomization) -> some View {
        HStack {
            Text("Style:")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(String(describing: customization))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.green)

            Spacer()
        }
    }
}
