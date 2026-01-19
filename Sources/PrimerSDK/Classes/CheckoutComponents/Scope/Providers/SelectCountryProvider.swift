//
//  SelectCountryProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Provider view that wraps content with country selection scope access and navigation handling.
///
/// Use `SelectCountryProvider` when embedding country selection in your own navigation hierarchy:
/// ```swift
/// SelectCountryProvider(
///     onCountrySelected: { code, name in
///         print("Selected: \(name) (\(code))")
///     },
///     onCancel: {
///         print("User cancelled")
///     }
/// ) { scope in
///     SelectCountryScreen(scope: scope)
/// }
/// ```
///
/// Callbacks are invoked when provided. If no callbacks are provided, navigation events
/// are handled by the SDK's default behavior.
@available(iOS 15.0, *)
public struct SelectCountryProvider<Content: View>: View, LogReporter {
    private let onCountrySelected: ((String, String) -> Void)?
    private let onCancel: (() -> Void)?
    private let content: (any PrimerSelectCountryScope) -> Content

    @Environment(\.primerSelectCountryScope) private var countryScope
    @State private var lastSelectedCountryCode: String?

    /// Creates a SelectCountryProvider.
    /// - Parameters:
    ///   - onCountrySelected: Called when user selects a country with (code, name)
    ///   - onCancel: Called when user cancels the selection (optional, typically handled by navigation)
    ///   - content: ViewBuilder that receives the select country scope
    public init(
        onCountrySelected: ((String, String) -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (any PrimerSelectCountryScope) -> Content
    ) {
        self.onCountrySelected = onCountrySelected
        self.onCancel = onCancel
        self.content = content
    }

    public var body: some View {
        if let countryScope {
            content(countryScope)
                .environment(\.primerSelectCountryScope, countryScope)
                .task {
                    await observeCountrySelection()
                }
        } else {
            // Fallback when scope is not available
            Text("Country selection scope not available")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - State Observation

    /// Observes country selection state changes and invokes appropriate callbacks.
    /// Uses iOS-native async/await pattern with AsyncStream.
    private func observeCountrySelection() async {
        guard let countryScope else { return }

        for await state in countryScope.state {
            await handleStateChange(state)
        }
    }

    /// Handles country selection state changes by invoking the appropriate callback.
    @MainActor
    private func handleStateChange(_ state: PrimerSelectCountryState) {
        // Check if a NEW country was selected (different from last seen)
        if let selectedCountry = state.selectedCountry,
           selectedCountry.code != lastSelectedCountryCode {
            lastSelectedCountryCode = selectedCountry.code
            onCountrySelected?(selectedCountry.code, selectedCountry.name)
        }
    }
}
