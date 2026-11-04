//
//  PrimerUIComponentRegistryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerStepResolver
import XCTest

final class PrimerUIComponentRegistryTests: XCTestCase {
    func testDeclaresNothingByDefault() async {
        let versions = await PrimerUIComponentRegistry().declaredVersions
        XCTAssertEqual(versions, [:])
    }

    func testLaterDeclarationReplacesTheVersion() async {
        let registry = PrimerUIComponentRegistry()
        await registry.declare("klarna.options", version: "1.0.0")
        await registry.declare("klarna.options", version: "1.1.0")

        let versions = await registry.declaredVersions
        XCTAssertEqual(versions, ["klarna.options": "1.1.0"])
    }
}
