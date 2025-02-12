//
//  DesignTokensManager.swift
//  
//
//  Created by Boris on 12.2.25..
//

import SwiftUI

/// An ObservableObject that fetches design tokens from an API.
@MainActor
class DesignTokensManager: ObservableObject {
    @Published var tokens: DesignTokens?

    /// Fetches design tokens asynchronously.
    func fetchTokens() async {
        guard let url = URL(string: "https://example.com/api/designTokens") else {
            print("Invalid URL for design tokens API")
            // Provide mocked design tokens as a fallback.
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let fetchedTokens = try decoder.decode(DesignTokens.self, from: data)

            // Update the published property on the main actor.
            self.tokens = fetchedTokens
        } catch {
            print("Failed to fetch design tokens: \(error), using mocked data instead.")
            tokens = DesignTokens(primerColorGray100: "#ff0000",
                                  primerColorGray200: "#00ff00",
                                  primerColorBrand: "#0000ff")

        }
    }
}
