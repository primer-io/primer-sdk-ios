//
//  RequiredCapabilitiesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerFoundation
import XCTest

final class RequiredCapabilitiesTests: XCTestCase {
    func testDecodesSteps() throws {
        let json = Data(#"{"steps":{"http.request":"^1.0.0"}}"#.utf8)
        let capabilities = try JSONDecoder().decode(RequiredCapabilities.self, from: json)

        XCTAssertEqual(capabilities.steps, ["http.request": .caret(SemanticVersion(1, 0, 0))])
    }

    func testMissingStepsDecodesEmpty() throws {
        let capabilities = try JSONDecoder().decode(RequiredCapabilities.self, from: Data("{}".utf8))
        XCTAssertTrue(capabilities.steps.isEmpty)
    }

    func testDecodesEverySection() throws {
        let json = Data(#"""
        {"steps":{"http.request":"^1.0.0","client.event":"^1.0.0"},
         "nodes":{"Box":"^1.0.0","paypal.buttons":"^1.0.0"},
         "nativeModules":["klarna"]}
        """#.utf8)
        let capabilities = try JSONDecoder().decode(RequiredCapabilities.self, from: json)

        XCTAssertEqual(capabilities.steps.keys.sorted(), ["client.event", "http.request"])
        XCTAssertEqual(capabilities.nodes.keys.sorted(), ["Box", "paypal.buttons"])
        XCTAssertEqual(capabilities.nativeModules, ["klarna"])
    }

    func testMissingNodesAndNativeModulesDecodeEmpty() throws {
        let capabilities = try JSONDecoder().decode(RequiredCapabilities.self, from: Data("{}".utf8))

        XCTAssertTrue(capabilities.nodes.isEmpty)
        XCTAssertTrue(capabilities.nativeModules.isEmpty)
    }

    func testUnreadableRangeDecodesRatherThanThrowing() throws {
        let json = Data(#"{"steps":{"http.request":">=1.0.0"}}"#.utf8)
        let capabilities = try JSONDecoder().decode(RequiredCapabilities.self, from: json)

        XCTAssertEqual(capabilities.steps, ["http.request": .unrecognised(">=1.0.0")])
    }
}
