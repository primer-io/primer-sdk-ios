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
        // Load and merge tokens
        let baseDict = try loadJSON(named: "base")
        let mergedDict = colorScheme == .dark
            ? DesignTokensProcessor.mergeDictionaries(baseDict, with: try loadJSON(named: "dark"))
            : baseDict

        // Process tokens through transformation pipeline
        var processedDict = DesignTokensProcessor.resolveReferences(in: mergedDict)
        processedDict = DesignTokensProcessor.convertHexColors(in: processedDict)
        var flatDict = DesignTokensProcessor.flattenTokenDictionary(processedDict)
        flatDict = DesignTokensProcessor.resolveFlattenedReferences(in: flatDict, source: processedDict)
        flatDict = DesignTokensProcessor.evaluateMath(in: flatDict)

        // Decode and publish
        let data = try JSONSerialization.data(withJSONObject: flatDict)
        let tokens = try JSONDecoder().decode(DesignTokens.self, from: data)

        await MainActor.run {
            self.tokens = tokens
        }
    }

    // MARK: - JSON Loading

    private func loadJSON(named fileName: String) throws -> [String: Any] {
        guard let url = Bundle.primerResources.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PrimerError.failedToLoadDesignTokens(fileName: fileName)
        }
        return dictionary
    }
}
