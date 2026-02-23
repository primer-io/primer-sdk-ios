//
//  PrimerStepResolver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

public protocol StepResolver: Sendable {
	func resolve(_ step: CodableValue) async throws -> CodableValue?
}

public actor PrimerStepResolverRegistry {
	public static let shared = PrimerStepResolverRegistry()
	
    private let logger = Logger()
    private var resolvers: [StepDomain: StepResolver] = [:]

	public init() {}
	
    public func register<R: StepResolver>(_ resolver: R, forStepType type: StepDomain)  {
        logger.info("Registering resolver for action: \(type.rawValue)")
        resolvers[type] = resolver
    }
    
    public func resolver(for step: StepDomain) throws -> StepResolver {
        logger.info("Finding resolver for action: \(step.rawValue)")
        guard let resolver = resolvers[step] else {
            logger.error("No resolver found for action: \(step.rawValue)")
            throw StepResolutionError.noResolverFound
        }
        return resolver
    }
}

private enum StepResolutionError: Error {
    case noResolverFound
}
