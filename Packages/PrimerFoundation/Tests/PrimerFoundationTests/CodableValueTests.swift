//
//  CodableValueTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerFoundation
import XCTest

final class CodableValueTests: XCTestCase {

    func testDecodeString() throws { try assertDecode(#""hello""#, .string("hello")) }
    func testDecodeInt() throws { try assertDecode("42", .int(42)) }
    func testDecodeDouble() throws { try assertDecode("3.14", .double(3.14)) }
    func testDecodeBool() throws { try assertDecode("true", .bool(true)) }
    func testDecodeNull() throws { try assertDecode("null", .null) }
    func testDecodeArray() throws { try assertDecode("[1, 2]", .array([.int(1), .int(2)])) }
    func testDecodeObject() throws { try assertDecode(#"{"k": "v"}"#, .object(["k": .string("v")])) }
    func testDecodeNested() throws { try assertDecode(#"{"a": {"b": 1} }"#, .object(["a": .object(["b": .int(1)])])) }

    func testRoundTripString() throws { try assertRoundTrip(.string("test")) }
    func testRoundTripInt() throws { try assertRoundTrip(.int(99)) }
    func testRoundTripBool() throws { try assertRoundTrip(.bool(false)) }
    func testRoundTripNull() throws { try assertRoundTrip(.null) }
    func testRoundTripArray() throws { try assertRoundTrip(.array([.string("a"), .int(1), .null])) }
    func testRoundTripObject() throws { try assertRoundTrip(.object(["k": .string("v"), "n": .int(5)])) }

    func testStringAccessorOnString() { XCTAssertEqual(CodableValue.string("abc").string, "abc") }
    func testStringAccessorOnInt() { XCTAssertEqual(CodableValue.int(7).string, "7") }
    func testStringAccessorOnBool() { XCTAssertNil(CodableValue.bool(true).string) }
    func testStringAccessorOnNull() { XCTAssertNil(CodableValue.null.string) }

    func testJsonStringForPrimitive() throws { XCTAssertEqual(try CodableValue.string("hello").jsonString, #""hello""#) }
    func testJsonStringForObject() throws {
        let json = try CodableValue.object(["a": .int(1)]).jsonString
        XCTAssertTrue(["\"a\"", "1"].allSatisfy(json.contains))
    }
}

private extension CodableValueTests {
    func assertDecode(_ input: String, _ expected: CodableValue, file: StaticString = #file, line: UInt = #line) throws {
        let json = Data(input.utf8)
        let value = try JSONDecoder().decode(CodableValue.self, from: json)
        XCTAssertEqual(value, expected, file: file, line: line)
    }

    func assertRoundTrip(_ input: CodableValue, file: StaticString = #file, line: UInt = #line) throws {
        let data = try JSONEncoder().encode(input)
        let decoded = try JSONDecoder().decode(CodableValue.self, from: data)
        XCTAssertEqual(decoded, input, file: file, line: line)
    }
}
