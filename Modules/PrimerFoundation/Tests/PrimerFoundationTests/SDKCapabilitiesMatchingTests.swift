//
//  SDKCapabilitiesMatchingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerFoundation
import XCTest

final class SDKCapabilitiesMatchingTests: XCTestCase {
    private let sdk = SDKCapabilities(
        steps: ["http.request": [1, 2], "url.open": [1]],
        nodes: ["Screen": [1]],
        presentations: ["fullscreen", "modal"]
    )

    func testEligibleWhenVersionsOverlap() throws {
        XCTAssertTrue(sdk.canExecute(try required(#"{"steps":{"http.request":[2]}}"#)))
    }

    func testEligibleWhenOnlyFallbackVersionOverlaps() throws {
        XCTAssertTrue(sdk.canExecute(try required(#"{"steps":{"http.request":[3,2]}}"#)))
    }

    func testIneligibleWhenStepTypeUnknown() throws {
        XCTAssertFalse(sdk.canExecute(try required(#"{"steps":{"wallet.launch":[1]}}"#)))
    }

    func testIneligibleWhenNoVersionOverlaps() throws {
        XCTAssertFalse(sdk.canExecute(try required(#"{"steps":{"url.open":[2]}}"#)))
    }

    func testMissingVersionListMeansVersionOne() throws {
        XCTAssertTrue(sdk.canExecute(try required(#"{"steps":{"url.open":[]}}"#)))

        let v2Only = SDKCapabilities(steps: ["url.open": [2]])
        XCTAssertFalse(v2Only.canExecute(try required(#"{"steps":{"url.open":[]}}"#)))
    }

    func testIneligibleWhenPresentationUnsupported() throws {
        XCTAssertFalse(sdk.canExecute(try required(#"{"presentations":["sheet"]}"#)))
    }

    func testEmptyRequirementsAreEligible() throws {
        XCTAssertTrue(sdk.canExecute(try required("{}")))
    }

    private func required(_ json: String) throws -> RequiredCapabilities {
        try JSONDecoder().decode(RequiredCapabilities.self, from: Data(json.utf8))
    }
}
