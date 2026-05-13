//
//  ExtensionsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerFoundation
import XCTest

// MARK: - Encodable

final class EncodableExtensionsTests: XCTestCase {

    private struct Sample: Codable, Equatable {
        let name: String
        let age: Int
    }

    func testCastedToIncompatibleTypeThrows() {
        let source = Sample(name: "Charlie", age: 20)
        XCTAssertThrowsError(try source.casted(to: Manifest.self))
    }
}

// MARK: - Set

final class SetExtensionsTests: XCTestCase {

    func testToggledAddsElement() {
        let set: Set<Int> = [1, 2, 3]
        let result = set.toggled(4)
        XCTAssertTrue(result.contains(4))
        XCTAssertEqual(result.count, 4)
    }

    func testToggledRemovesElement() {
        let set: Set<Int> = [1, 2, 3]
        let result = set.toggled(2)
        XCTAssertFalse(result.contains(2))
        XCTAssertEqual(result.count, 2)
    }

    func testToggledOnEmptySet() {
        let set: Set<String> = []
        let result = set.toggled("a")
        XCTAssertEqual(result, ["a"])
    }
}

// MARK: - String

final class StringExtensionsTests: XCTestCase {

    func testJsonObjectParsesDict() throws {
        let json = #"{"key": "value"}"#
        let dict: [String: Any] = try json.jsonObject()
        XCTAssertEqual(dict["key"] as? String, "value")
    }

    func testJsonObjectParsesArray() throws {
        let json = "[1, 2, 3]"
        let array: [Int] = try json.jsonObject()
        XCTAssertEqual(array.count, 3)
    }

    func testJsonObjectThrowsOnTypeMismatch() {
        let json = #"{"key": "value"}"#
        XCTAssertThrowsError(try json.jsonObject() as [Int])
    }

    func testJsonObjectThrowsOnInvalidJSON() {
        let json = "not json"
        XCTAssertThrowsError(try json.jsonObject() as String)
    }
}
