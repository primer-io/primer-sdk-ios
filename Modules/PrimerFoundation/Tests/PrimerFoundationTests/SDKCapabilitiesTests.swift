//
//  SDKCapabilitiesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerFoundation
import XCTest

final class SDKCapabilitiesTests: XCTestCase {
    func testEncodesEverySectionAsVersionStrings() throws {
        let capabilities = SDKCapabilities(stepTypes: ["http.request": "1.0.0", "url.open": "1.0.0 || 2.0.0"])

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let json = try XCTUnwrap(String(data: encoder.encode(capabilities), encoding: .utf8))

        XCTAssertEqual(json, """
        {"dependencies":{},"stepTypes":{"http.request":"1.0.0","url.open":"1.0.0 || 2.0.0"},"uiComponents":{}}
        """)
    }
}
