//
//  StepCapabilityTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerStepResolver
import XCTest

final class StepCapabilityTests: XCTestCase {
    func testDeclaresEveryStepTypeAtItsVersion() {
        XCTAssertEqual(
            StepCapability.declaredVersions,
            ["http.request": "1.0.0", "url.open": "1.0.0", "platform.log": "1.0.0"]
        )
    }
}
