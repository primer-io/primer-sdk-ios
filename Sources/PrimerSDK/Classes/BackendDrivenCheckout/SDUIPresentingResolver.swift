//
//  SDUIPresentingResolver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

@MainActor
final class SDUIPresentingResolver: StepResolver {
    static let stepType = "ui.render"

    private let registry: PrimerStepResolverRegistry
    private let present: @MainActor () async -> Bool
    private var forwarding = false

    init(registry: PrimerStepResolverRegistry = .shared, present: @escaping @MainActor () async -> Bool) {
        self.registry = registry
        self.present = present
        registry.register(weak: self, for: Self.stepType)
    }

    func resolve(_ data: CodableValue) async throws -> StepResolutionResult {
        guard !forwarding, await present() else { return StepResolutionResult(outcome: .unsupported) }
        forwarding = true
        defer { forwarding = false }
        return try await registry.resolve(Self.stepType, data: data)
    }
}
