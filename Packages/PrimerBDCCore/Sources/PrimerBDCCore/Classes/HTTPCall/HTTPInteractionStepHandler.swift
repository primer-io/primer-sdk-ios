//
//  HTTPInteractionStepHandler.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation
import PrimerStepResolver

@MainActor
final class HTTPInteractionStepHandler {    
    private let registry: PrimerStepResolverRegistry
    
    init(registry: PrimerStepResolverRegistry) {
        self.registry = registry
    }
    
    func resolve(_ data: CodableValue) async throws -> CodableValue? {
        let resolver = try await registry.resolver(for: .httpRequest)
        return try await resolver.resolve(data)
    }
}
