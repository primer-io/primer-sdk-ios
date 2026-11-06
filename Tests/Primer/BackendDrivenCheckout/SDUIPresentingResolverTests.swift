//
//  SDUIPresentingResolverTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
@testable @_spi(PrimerInternal) import PrimerSDK
@_spi(PrimerInternal) import PrimerStepResolver
import XCTest

@MainActor
final class SDUIPresentingResolverTests: XCTestCase {
    private var registry: PrimerStepResolverRegistry!
    private var presentations = 0

    override func setUp() {
        super.setUp()
        registry = PrimerStepResolverRegistry()
        presentations = 0
    }

    func testRenderIsUnsupportedWhenNothingCanBePresented() async throws {
        let sut = SDUIPresentingResolver(registry: registry) { [self] in
            presentations += 1
            return false
        }

        let result = try await registry.resolve(SDUIPresentingResolver.stepType, data: .object([:]))

        XCTAssertEqual(result.outcome, .unsupported)
        XCTAssertEqual(presentations, 1)
        _ = sut
    }

    func testRenderIsForwardedToTheResolverTheSheetRegisters() async throws {
        let sheet = StubResolver(result: StepResolutionResult(outcome: .success, data: .string("rendered")))
        let sut = SDUIPresentingResolver(registry: registry) { [self] in
            presentations += 1
            registry.register(sheet, for: SDUIPresentingResolver.stepType)
            return true
        }

        let result = try await registry.resolve(SDUIPresentingResolver.stepType, data: .object([:]))

        XCTAssertEqual(result.outcome, .success)
        XCTAssertEqual(result.data, .string("rendered"))
        XCTAssertEqual(presentations, 1)
        _ = sut
    }

    func testRenderIsUnsupportedWhenTheSheetRegistersNoResolver() async throws {
        let sut = SDUIPresentingResolver(registry: registry) { [self] in
            presentations += 1
            return true
        }

        let result = try await registry.resolve(SDUIPresentingResolver.stepType, data: .object([:]))

        XCTAssertEqual(result.outcome, .unsupported)
        XCTAssertEqual(presentations, 1)
        _ = sut
    }
}

private struct StubResolver: StepResolver {
    let result: StepResolutionResult

    func resolve(_: CodableValue) async throws -> StepResolutionResult { result }
}
