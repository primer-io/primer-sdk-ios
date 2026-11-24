//
//  KlarnaWidgetComponentTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
@_spi(PrimerInternal) import PrimerFoundation
@testable @_spi(PrimerInternal) import PrimerSDK
@_spi(PrimerInternal) import PrimerStepResolver
import XCTest

final class KlarnaWidgetComponentTests: XCTestCase {
    func testRegisterDeclaresTheWidgetAndTheSDKProbe() async {
        let uiComponents = PrimerUIComponentRegistry()
        let probes = PrimerProbeRegistry()

        await KlarnaWidgetComponent.register(uiComponents: uiComponents, probes: probes)

        let declaredComponents = await uiComponents.declaredVersions
        let declaredProbes = await probes.declaredVersions
        XCTAssertEqual(declaredComponents, ["klarna.widget": "1.0.0"])
        XCTAssertEqual(declaredProbes, ["klarna.sdk": "1.0.0"])
    }

    func testKlarnaSDKProbeAnswersSuccess() async {
        let probes = PrimerProbeRegistry()
        await probes.register(KlarnaSDKProbe(), for: KlarnaSDKProbe.name)

        let result = await probes.run("klarna.sdk", params: .object([:]))

        XCTAssertEqual(result, ProbeResult(outcome: .success))
    }
}
#endif
