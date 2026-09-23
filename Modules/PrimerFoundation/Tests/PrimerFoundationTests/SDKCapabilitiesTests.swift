//
//  SDKCapabilitiesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerFoundation
import XCTest

final class SDKCapabilitiesTests: XCTestCase {
    func testEncodesVersionsAsStrings() throws {
        let capabilities = SDKCapabilities(
            steps: ["http.request": SemanticVersion(1, 0, 0), "url.open": SemanticVersion(2, 1, 3)],
            nodes: ["Box": SemanticVersion(1, 0, 0)],
            nativeModules: ["klarna"]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let json = try XCTUnwrap(String(data: encoder.encode(capabilities), encoding: .utf8))

        XCTAssertEqual(json, """
        {"nativeModules":["klarna"],"nodes":{"Box":"1.0.0"},"steps":{"http.request":"1.0.0","url.open":"2.1.3"}}
        """)
    }
}
