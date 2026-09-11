//
//  RequiredCapabilitiesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerFoundation
import XCTest

final class RequiredCapabilitiesTests: XCTestCase {
    func testDecodesPartialPayloadWithMissingSectionsEmpty() throws {
        let json = Data(#"{"steps":{"http.request":[2,1]}}"#.utf8)
        let capabilities = try JSONDecoder().decode(RequiredCapabilities.self, from: json)
        
        XCTAssertEqual(capabilities.steps, ["http.request": [1, 2]])
        XCTAssertTrue(capabilities.nodes.isEmpty)
        XCTAssertTrue(capabilities.presentations.isEmpty)
    }
    
    func testDecodesFullPayload() throws {
        let json = Data(#"{"steps":{"url.open":[1]},"nodes":{"Screen":[1]},"presentations":["fullscreen"]}"#.utf8)
        let capabilities = try JSONDecoder().decode(RequiredCapabilities.self, from: json)
        
        XCTAssertEqual(capabilities.steps, ["url.open": [1]])
        XCTAssertEqual(capabilities.nodes, ["Screen": [1]])
        XCTAssertEqual(capabilities.presentations, ["fullscreen"])
    }
}
