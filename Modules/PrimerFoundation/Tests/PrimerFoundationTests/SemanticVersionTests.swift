//
//  SemanticVersionTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerFoundation
import XCTest

final class SemanticVersionTests: XCTestCase {
    func testParsesThreeComponents() throws {
        let version = try XCTUnwrap(SemanticVersion("1.2.3"))
        XCTAssertEqual(version.major, 1)
        XCTAssertEqual(version.minor, 2)
        XCTAssertEqual(version.patch, 3)
        XCTAssertEqual(version.description, "1.2.3")
    }

    func testRejectsMalformedInput() {
        for input in ["1.2", "1.2.3.4", "1.x.0", "", "-1.0.0", "1.2.3 ", "v1.2.3"] {
            XCTAssertNil(SemanticVersion(input), "expected nil for '\(input)'")
        }
    }

    func testOrdersByComponentNotByString() {
        XCTAssertTrue(SemanticVersion(1, 9, 0) < SemanticVersion(1, 10, 0))
        XCTAssertTrue(SemanticVersion(1, 0, 0) < SemanticVersion(2, 0, 0))
        XCTAssertTrue(SemanticVersion(1, 0, 1) > SemanticVersion(1, 0, 0))
        XCTAssertEqual(SemanticVersion(1, 0, 0), SemanticVersion(1, 0, 0))
    }
}
