//
//  PrimerStepResolverRegistryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
@testable import PrimerStepResolver
import XCTest

final class PrimerStepResolverRegistryTests: XCTestCase {
    func testRegisteredResolverIsCalled() async throws {
        let registry = PrimerStepResolverRegistry()
        let resolver = MockResolver()
        await registry.register(resolver, for: StepDomain.httpRequest)

        let result = try await registry.resolve(StepDomain.httpRequest, params: .null)
        XCTAssertEqual(result.outcome, .success)
        XCTAssertEqual(resolver.callCount, 1)
    }

    func testUnregisteredTypeReturnsUnsupported() async throws {
        let result = try await PrimerStepResolverRegistry().resolve("unknown.type", params: .null)
        XCTAssertEqual(result.outcome, .unsupported)
    }
}

private final class MockResolver: StepResolver {
    var callCount = 0
    func resolve(_ step: CodableValue) async throws -> StepResolutionResult {
        callCount += 1
        return StepResolutionResult(outcome: .success)
    }
}
