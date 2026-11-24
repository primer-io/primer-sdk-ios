//
//  DemoScaffold.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerSDK
import SwiftUI

/// Resolves a client token for a demo — reusing one supplied in the configuration, otherwise
/// requesting a session — then renders the demo content inside a dismissable navigation container.
/// Factored out so each demo only describes its checkout UI, not the loading boilerplate.
@available(iOS 15.0, *)
struct DemoScaffold<Content: View>: View {
    let configuration: DemoConfiguration
    let title: String
    @ViewBuilder let content: (String) -> Content

    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var clientToken: String?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        NavigationView {
            contentView
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
        .task { await loadToken() }
    }

    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            LoadingView()
        } else if let error {
            ErrorView(error: error, onRetry: { Task { await loadToken() } })
        } else if let clientToken {
            content(clientToken)
        }
    }

    private func loadToken() async {
        isLoading = true
        error = nil

        if let existing = configuration.clientToken, !existing.isEmpty {
            clientToken = existing
            isLoading = false
            return
        }

        guard let clientSession = configuration.clientSession else {
            error = "No session configuration provided - configure a session in the main settings screen"
            isLoading = false
            return
        }

        do {
            clientToken = try await NetworkingUtils.requestClientSession(body: clientSession, apiVersion: configuration.apiVersion)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
