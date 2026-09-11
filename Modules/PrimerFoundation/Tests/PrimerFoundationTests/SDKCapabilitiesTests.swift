//
//  SDKCapabilitiesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerFoundation
import XCTest

final class SDKCapabilitiesTests: XCTestCase {
    func testEncodesWithSortedValues() throws {
        let capabilities = SDKCapabilities(
            steps: ["http.request": [2, 1], "url.open": [1]],
            nodes: ["TextField": [2, 1]],
            presentations: ["modal", "fullscreen"]
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let json = try XCTUnwrap(String(data: encoder.encode(capabilities), encoding: .utf8))
        
        XCTAssertEqual(json, """
        {"nodes":{"TextField":[1,2]},"presentations":["fullscreen","modal"],\
        "steps":{"http.request":[1,2],"url.open":[1]}}
        """)
    }
}
