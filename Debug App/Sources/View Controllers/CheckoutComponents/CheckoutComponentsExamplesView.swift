//
//  CheckoutComponentsExamplesView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

@available(iOS 15.0, *)
struct CheckoutComponentsExamplesView: View {
    private let configuration: DemoConfiguration

    @State private var selectedDemoId: UUID?

    init(settings: PrimerSettings, apiVersion: PrimerApiVersion, clientSession: ClientSessionRequestBody? = nil) {
        self.configuration = DemoConfiguration(
            settings: settings,
            apiVersion: apiVersion,
            clientSession: clientSession
        )
    }

    var body: some View {
        List {
            ForEach(DemoRegistry.allMetadata) { metadata in
                DemoRow(metadata: metadata) {
                    selectedDemoId = metadata.id
                }
            }
        }
        .navigationTitle("Examples")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedDemoId) { demoId in
            if let demoView = DemoRegistry.createDemo(id: demoId, configuration: configuration) {
                demoView
            }
        }
    }
}

// MARK: - UUID Identifiable Conformance

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}
