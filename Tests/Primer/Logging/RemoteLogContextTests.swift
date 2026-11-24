//
//  RemoteLogContextTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class RemoteLogContextTests: XCTestCase {

    private var sut: RemoteLogContext!

    override func setUp() {
        super.setUp()
        sut = RemoteLogContext()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_merged_emptyContext_returnsTheCallersFields() {
        XCTAssertNil(sut.merged(into: nil))
        XCTAssertEqual(sut.merged(into: ["a": 1]) as? NSDictionary, ["a": 1])
    }

    func test_merged_addsTheContextAndTheCallerWins() {
        sut["flag"] = true
        sut["a"] = "context"

        XCTAssertEqual(sut.merged(into: nil) as? NSDictionary, ["flag": true, "a": "context"])
        XCTAssertEqual(sut.merged(into: ["a": "caller"]) as? NSDictionary, ["flag": true, "a": "caller"])
    }

    func test_settingNil_removesTheField() {
        sut["flag"] = true

        sut["flag"] = nil

        XCTAssertNil(sut["flag"])
        XCTAssertNil(sut.merged(into: nil))
    }
}
