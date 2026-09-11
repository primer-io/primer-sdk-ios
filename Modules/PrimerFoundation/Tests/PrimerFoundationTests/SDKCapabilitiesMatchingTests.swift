//
//  SDKCapabilitiesMatchingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerFoundation
import XCTest

final class SDKCapabilitiesMatchingTests: XCTestCase {
    private let sdk = SDKCapabilities(
        steps: ["http.request": SemanticVersion(1, 4, 0), "url.open": SemanticVersion(1, 0, 0)],
        nodes: ["Box": SemanticVersion(1, 4, 0)],
        nativeModules: ["klarna"]
    )

    func testEligibleWhenOurVersionSatisfiesTheRange() throws {
        XCTAssertTrue(sdk.canExecute(try required(#"{"steps":{"http.request":"^1.0.0"}}"#)))
    }

    func testIneligibleWhenOurVersionIsTooOld() throws {
        XCTAssertFalse(sdk.canExecute(try required(#"{"steps":{"url.open":"^1.2.0"}}"#)))
    }

    func testIneligibleWhenTheRangeWantsANewerMajor() throws {
        XCTAssertFalse(sdk.canExecute(try required(#"{"steps":{"http.request":"^2.0.0"}}"#)))
    }

    func testIneligibleWhenStepTypeUnknown() throws {
        XCTAssertFalse(sdk.canExecute(try required(#"{"steps":{"client.event":"^1.0.0"}}"#)))
    }

    func testIneligibleWhenTheRangeIsUnreadable() throws {
        XCTAssertFalse(sdk.canExecute(try required(#"{"steps":{"http.request":">=1.0.0"}}"#)))
    }

    func testEligibleWhenOurNodeSatisfiesTheRange() throws {
        XCTAssertTrue(sdk.canExecute(try required(#"{"nodes":{"Box":"^1.0.0"}}"#)))
    }

    func testIneligibleWhenNodeTypeUnknown() throws {
        XCTAssertFalse(sdk.canExecute(try required(#"{"nodes":{"paypal.buttons":"^1.0.0"}}"#)))
    }

    func testEligibleWhenWeLinkTheNativeModule() throws {
        XCTAssertTrue(sdk.canExecute(try required(#"{"nativeModules":["klarna"]}"#)))
    }

    func testIneligibleWhenTheNativeModuleIsMissing() throws {
        XCTAssertFalse(sdk.canExecute(try required(#"{"nativeModules":["klarna","stripe"]}"#)))
    }

    func testEverySectionMustPass() throws {
        let json = #"{"steps":{"http.request":"^1.0.0"},"nodes":{"paypal.buttons":"^1.0.0"}}"#
        XCTAssertFalse(sdk.canExecute(try required(json)))
    }

    func testEmptyRequirementsAreEligible() throws {
        XCTAssertTrue(sdk.canExecute(try required("{}")))
    }

    private func required(_ json: String) throws -> RequiredCapabilities {
        try JSONDecoder().decode(RequiredCapabilities.self, from: Data(json.utf8))
    }
}
