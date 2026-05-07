//
//  PrimerStepResolver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

public protocol StepResolver: Sendable {
    func resolve(_ step: CodableValue) async throws -> StepResolutionResult
}

public struct StepResolutionResult: Sendable {
    public let outcome: TerminalOutcome
    public let data: CodableValue?

    public init(outcome: TerminalOutcome, data: CodableValue? = nil) {
        self.outcome = outcome
        self.data = data
    }
}

public actor PrimerStepResolverRegistry {
    public static let shared = PrimerStepResolverRegistry()

    private let logger = Logger()
    private var resolvers: [String: StepResolver] = [:]

    public init() {}

    public func register(_ resolver: StepResolver, for type: String) {
        logger.info("Registering resolver for step type: \(type)")
        resolvers[type] = resolver
    }

    public func resolve(_ type: String, params: CodableValue) async throws -> StepResolutionResult {
        logger.info("Resolving step type: \(type)")
        guard let resolver = resolvers[type] else {
            logger.info("No resolver for type '\(type)' — returning unsupported")
            return StepResolutionResult(outcome: .unsupported)
        }
        return try await resolver.resolve(params)
    }
}
