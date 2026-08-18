//
//  PrimerStepResolver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) @preconcurrency import PrimerFoundation

@_spi(PrimerInternal)
public typealias ClassResolver = AnyObject & StepResolver

@_spi(PrimerInternal)
public protocol StepResolver: Sendable {
    func resolve(_ data: CodableValue) async throws -> StepResolutionResult
}

@_spi(PrimerInternal)
public struct StepResolutionResult: Sendable {
    public let outcome: TerminalOutcome
    public let data: CodableValue?

    public init(outcome: TerminalOutcome, data: CodableValue? = nil) {
        self.outcome = outcome
        self.data = data
    }
}

@_spi(PrimerInternal)
public final class PrimerStepResolverRegistry {
    public static let shared = PrimerStepResolverRegistry()

    private let lock = NSLock()
    private let logger = Logger()
    private var resolvers: [String: Registration] = [:]

    public init() {}

    public func register(_ resolver: StepResolver, for type: String) {
        logger.info("Registering resolver for step type: \(type)")
        lock.withLock { resolvers[type] = .strong(resolver) }
    }

    public func register(weak resolver: ClassResolver, for type: String) {
        logger.info("Registering weak resolver for step type: \(type)")
        lock.withLock { resolvers[type] = .weak(WeakResolver(resolver)) }
    }

    @discardableResult
    public func resolve(_ type: String, data: CodableValue) async throws -> StepResolutionResult {
        logger.info("Resolving step type: \(type)")
        guard let resolver = lock.withLock({ resolvers[type]?() }) else {
            logger.info("No resolver for type '\(type)' — returning unsupported")
            return StepResolutionResult(outcome: .unsupported)
        }
        return try await resolver.resolve(data)
    }
}

private extension PrimerStepResolverRegistry {
    enum Registration {
        case strong(StepResolver)
        case weak(WeakResolver)

        func callAsFunction() -> StepResolver? {
            switch self {
            case let .strong(resolver): resolver
            case let .weak(box): box.value
            }
        }
    }

    final class WeakResolver {
        weak var value: ClassResolver?

        init(_ value: ClassResolver) {
            self.value = value
        }
    }
}
