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

    @State private var selectedDemo: DemoMetadata?

    init(settings: PrimerSettings, apiVersion: PrimerApiVersion, clientSession: ClientSessionRequestBody? = nil, clientToken: String? = nil) {
        configuration = DemoConfiguration(
            settings: settings,
            apiVersion: apiVersion,
            clientSession: clientSession,
            clientToken: clientToken
        )
    }

    var body: some View {
        List {
            ForEach(DemoRegistry.sections, id: \.category) { section in
                Section(section.category.rawValue) {
                    ForEach(section.demos) { metadata in
                        DemoRow(metadata: metadata) {
                            selectedDemo = metadata
                        }
                    }
                }
            }
        }
        .navigationTitle("Examples")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedDemo) { demo in
            DemoRegistry.createDemo(key: demo.key, configuration: configuration)
        }
    }
}
