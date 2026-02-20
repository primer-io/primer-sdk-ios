//
//  AnalyticsHandler.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerStepResolver

final class AnalyticsHandler {
    private let registry: PrimerStepResolverRegistry
    
    init(registry: PrimerStepResolverRegistry) {
        self.registry = registry
    }
    
    func resolve(_ step: CodableValue) async throws -> CodableValue? {
        let resolver = try await registry.resolver(for: .analyticsLog)
        return try await resolver.resolve(step)
    }
}
