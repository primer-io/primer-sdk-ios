//
//  PrimerProbeRegistryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
@testable @_spi(PrimerInternal) import PrimerStepResolver
import XCTest

final class PrimerProbeRegistryTests: XCTestCase {
    func testDeclaresEachRegisteredProbeAtItsVersion() async {
        let registry = PrimerProbeRegistry()
        await registry.register(MockProbe(version: "1.0.0"), for: "library")
        await registry.register(MockProbe(version: "2.1.0"), for: "app")

        let versions = await registry.declaredVersions
        XCTAssertEqual(versions, ["library": "1.0.0", "app": "2.1.0"])
    }

    func testRunsTheProbeWithItsParams() async {
        let registry = PrimerProbeRegistry()
        let probe = MockProbe(result: ProbeResult(outcome: .success, data: .object(["version": .string("5.0.0")])))
        await registry.register(probe, for: "library")

        let result = await registry.run("library", params: .object(["id": .string("klarna")]))
        XCTAssertEqual(result, ProbeResult(outcome: .success, data: .object(["version": .string("5.0.0")])))
        XCTAssertEqual(probe.receivedParams, [.object(["id": .string("klarna")])])
    }

    func testMissingProbeAnswersError() async {
        let result = await PrimerProbeRegistry().run("unknown", params: .null)
        XCTAssertEqual(result, ProbeResult(outcome: .error))
    }

    func testThrowingProbeAnswersError() async {
        let registry = PrimerProbeRegistry()
        await registry.register(MockProbe(error: URLError(.timedOut)), for: "library")

        let result = await registry.run("library", params: .null)
        XCTAssertEqual(result, ProbeResult(outcome: .error))
    }

    func testEncodesOutcomeAndData() throws {
        let result = ProbeResult(outcome: .failure, data: .object(["version": .string("4.0.0")]))
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let json = try XCTUnwrap(String(data: encoder.encode(result), encoding: .utf8))
        XCTAssertEqual(json, #"{"data":{"version":"4.0.0"},"outcome":"failure"}"#)
    }
}

private final class MockProbe: Probe, @unchecked Sendable {
    let version: String
    private let result: ProbeResult
    private let error: Error?
    private(set) var receivedParams: [CodableValue] = []

    init(version: String = "1.0.0", result: ProbeResult = ProbeResult(outcome: .success), error: Error? = nil) {
        self.version = version
        self.result = result
        self.error = error
    }

    func run(_ params: CodableValue) async throws -> ProbeResult {
        receivedParams.append(params)
        if let error { throw error }
        return result
    }
}
