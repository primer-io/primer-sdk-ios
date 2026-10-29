//
//  SDKCapabilitiesCurrentTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
@testable @_spi(PrimerInternal) import PrimerSDK
@_spi(PrimerInternal) import PrimerStepResolver
import XCTest

final class SDKCapabilitiesCurrentTests: XCTestCase {
    func testDeclaresStepTypesUIComponentsAndProbes() async {
        let uiComponents = PrimerUIComponentRegistry()
        await uiComponents.declare("klarna.options", version: "1.0.0")
        let probes = PrimerProbeRegistry()
        await probes.register(StubProbe(), for: "klarna.sdk")

        let capabilities = await SDKCapabilities.current(uiComponents: uiComponents, probes: probes)

        XCTAssertEqual(capabilities, SDKCapabilities(
            stepTypes: StepCapability.declaredVersions,
            uiComponents: ["klarna.options": "1.0.0"],
            probes: ["klarna.sdk": "1.0.0"]
        ))
    }
}

private struct StubProbe: Probe {
    let version = "1.0.0"

    func run(_ params: CodableValue) async throws -> ProbeResult {
        ProbeResult(outcome: .success)
    }
}
