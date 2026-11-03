//
//  ClientRequirementsProbesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerFoundation
@testable @_spi(PrimerInternal) import PrimerSDK
@_spi(PrimerInternal) import PrimerStepResolver
import XCTest

final class ClientRequirementsProbesTests: XCTestCase {
    func testNoRequestsGiveNoResults() async {
        let results = await ClientRequirements.runProbes([], registry: PrimerProbeRegistry())
        XCTAssertEqual(results, [:])
    }

    func testResultsAreKeyedByRequest() async {
        let registry = PrimerProbeRegistry()
        await registry.register(EchoProbe(), for: "library")
        let requests = [
            ProbeRequest(key: "library:a", probe: "library", params: .string("a")),
            ProbeRequest(key: "library:b", probe: "library", params: .string("b")),
        ]

        let results = await ClientRequirements.runProbes(requests, registry: registry)

        XCTAssertEqual(results, [
            "library:a": ProbeResult(outcome: .success, data: .string("a")),
            "library:b": ProbeResult(outcome: .success, data: .string("b")),
        ])
    }

    func testUnregisteredProbeIsAnError() async {
        let request = ProbeRequest(key: "missing", probe: "missing", params: .null)

        let results = await ClientRequirements.runProbes([request], registry: PrimerProbeRegistry())

        XCTAssertEqual(results, ["missing": ProbeResult(outcome: .error)])
    }

    func testProbesRunInParallel() async {
        let registry = PrimerProbeRegistry()
        for name in ["a", "b", "c"] {
            await registry.register(DelayedProbe(seconds: 0.3), for: name)
        }
        let requests = ["a", "b", "c"].map { ProbeRequest(key: $0, probe: $0, params: .null) }
        let start = Date()

        let results = await ClientRequirements.runProbes(requests, registry: registry)

        XCTAssertEqual(results.count, 3)
        XCTAssertLessThan(Date().timeIntervalSince(start), 0.8)
    }
}

private struct EchoProbe: Probe {
    let version = "1.0.0"

    func run(_ params: CodableValue) async throws -> ProbeResult {
        ProbeResult(outcome: .success, data: params)
    }
}

private struct DelayedProbe: Probe {
    let version = "1.0.0"
    let seconds: Double

    func run(_ params: CodableValue) async throws -> ProbeResult {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        return ProbeResult(outcome: .success)
    }
}
