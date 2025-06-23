//
//  DesignTokensManager.swift
//
//
//  Created by Boris on 12.2.25..
//
// DesignTokensManager.swift

import Foundation
import SwiftUI

final class DesignTokensManager: ObservableObject {
    @Published var tokens: DesignTokens?

    /// Loads and merges the design token JSON files based on the current color scheme.
    /// - Parameter colorScheme: The current color scheme (.light or .dark).
    /// - Throws: An error if loading or decoding the JSON fails.
    func fetchTokens(for colorScheme: ColorScheme) async throws {
        // Load light tokens (from base.json)
        let lightDict = try loadJSONDictionary(from: "base")

        let mergedDict: [String: Any]
        if colorScheme == .dark {
            // For dark mode, load dark overrides (from dark.json) and merge them
            let darkDict = try loadJSONDictionary(from: "dark")
            mergedDict = mergeDictionaries(lightDict, with: darkDict)
        } else {
            mergedDict = lightDict
        }

        // Convert the merged dictionary back to JSON data.
        let mergedData = try JSONSerialization.data(withJSONObject: mergedDict, options: [])
        let decoder = JSONDecoder()
        let tokens = try decoder.decode(DesignTokens.self, from: mergedData)

        // Update on the main thread.
        await MainActor.run {
            self.tokens = tokens
        }
    }

    // MARK: - Private Helper Methods

    /// Loads a JSON dictionary from a file in the main bundle.
    /// - Parameter fileName: The name of the JSON file (without extension).
    /// - Returns: A dictionary representation of the JSON.
    private func loadJSONDictionary(from fileName: String) throws -> [String: Any] {
        guard let url = Bundle.primerResources.url(forResource: fileName, withExtension: "json") else {
            throw NSError(domain: "DesignTokensManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "File \(fileName).json not found"])
        }
        let data = try Data(contentsOf: url)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw NSError(domain: "DesignTokensManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON from \(fileName).json"])
        }
        return dictionary
    }

    /// Recursively merges two dictionaries.
    /// Values from the override dictionary replace those from the base dictionary.
    /// - Parameters:
    ///   - base: The base dictionary.
    ///   - override: The dictionary with override values.
    /// - Returns: A merged dictionary.
    private func mergeDictionaries(_ base: [String: Any], with override: [String: Any]) -> [String: Any] {
        var merged = base
        for (key, overrideValue) in override {
            if let baseValue = base[key] as? [String: Any],
               let overrideDict = overrideValue as? [String: Any] {
                // Merge nested dictionaries recursively.
                merged[key] = mergeDictionaries(baseValue, with: overrideDict)
            } else {
                // Otherwise, use the override value.
                merged[key] = overrideValue
            }
        }
        return merged
    }
}
