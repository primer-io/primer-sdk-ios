//
//  ClientRequirementsSettler.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerFoundation

/// Checks every item against what this SDK declares and knows.
@MainActor @_spi(PrimerInternal)
public struct ClientRequirementsSettler {
    private let engine: any BDCEngineProtocol
    private let logger = Logger()

    public init(engine: any BDCEngineProtocol) {
        self.engine = engine
    }

    public func settle(_ items: [ClientRequirementsItem], client: BDCClient) async throws -> ClientRequirementsVerdicts {
        let startedAt = Date()
        logger.info("Checking client requirements for \(items.map(\.summary))")
        let verdicts = try await engine.checkClientRequirements(items: items, client: client)
        let elapsed = Int(Date().timeIntervalSince(startedAt) * 1000)
        logger.info("Client requirements settled in \(elapsed)ms: \(verdicts.mapValues(\.summary))")
        return verdicts
    }
}

private extension ClientRequirementsItem {
    var summary: String {
        "\(type) (\(id)): \(clientRequirements.map(\.description) ?? "none sent, legacy defaults apply")"
    }
}

private extension ClientRequirementsCheck {
    var summary: String {
        satisfied ? "available" : unmet.map { "\($0.kind) \($0.name): \($0.reason)" }.joined(separator: ", ")
    }
}
