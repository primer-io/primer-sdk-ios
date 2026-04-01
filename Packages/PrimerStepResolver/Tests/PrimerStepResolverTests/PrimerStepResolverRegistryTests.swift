//
//  PrimerStepResolverRegistryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
@testable import PrimerStepResolver
import XCTest

final class PrimerStepResolverRegistryTests: XCTestCase {
    func testResolverCanBeRegisteredAndRetrieved() async throws {
        let registry = PrimerStepResolverRegistry()
        await registry.register(MockStepResolver(), forStepType: .httpRequest)
        let resolved = try await registry.resolver(for: .httpRequest)
        XCTAssertTrue(resolved is MockStepResolver)
    }

    func testResolverForUnregisteredTypeThrows() async {
        do {
            _ = try await PrimerStepResolverRegistry().resolver(for: .platformLog)
            XCTFail("Expected error for unregistered step type")
        } catch {
            // correct
        }
    }
}

private final class MockStepResolver: StepResolver {
    func resolve(_ step: CodableValue) async throws -> CodableValue? { nil }
}
