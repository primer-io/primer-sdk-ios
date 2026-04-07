//
//  CodableStateTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerFoundation
import XCTest

final class CodableStateTests: XCTestCase {

    func testInitFromStringAnyDict() throws {
        let state = try CodableState(["name": "test", "count": 42, "active": true])
        XCTAssertEqual(state["name"], .string("test"))
        XCTAssertEqual(state["count"], .int(42))
        XCTAssertEqual(state["active"], .bool(true))
    }

    func testInitFromNestedDict() throws {
        let state = try CodableState(["outer": ["inner": "value"]])
        XCTAssertEqual(state["outer"], .object(["inner": .string("value")]))
    }
    
    func testInitFromDictWithArray() throws {
        let state = try CodableState(["items": [1, 2, 3]])
        XCTAssertEqual(state["items"], .array([.int(1), .int(2), .int(3)]))
    }

    func testInitFromEmptyDict() throws { XCTAssertTrue(try CodableState([:]).isEmpty) }
}
