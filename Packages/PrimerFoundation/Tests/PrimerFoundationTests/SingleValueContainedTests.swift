//
//  SingleValueContainedTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerFoundation
import XCTest

private enum TestSVC: String, SingleValueContained {
    case alpha = "ALPHA"
    case beta = "BETA"
}

final class SingleValueContainedTests: XCTestCase {

    func testDecodeValidValue() throws {
        let json = Data(#""ALPHA""#.utf8)
        XCTAssertEqual(try JSONDecoder().decode(TestSVC.self, from: json), .alpha)
    }

    func testDecodeAnotherValidValue() throws {
        let json = Data(#""BETA""#.utf8)
        XCTAssertEqual(try JSONDecoder().decode(TestSVC.self, from: json), .beta)
    }

    func testDecodeInvalidValueThrows() {
        let json = Data(#""GAMMA""#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(TestSVC.self, from: json))
    }

    func testEncodeProducesRawValue() throws {
        let data = try JSONEncoder().encode(TestSVC.alpha)
        let string = String(data: data, encoding: .utf8)
        XCTAssertEqual(string, #""ALPHA""#)
    }

    func testRoundTrip() throws {
        let original = TestSVC.beta
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TestSVC.self, from: data)
        XCTAssertEqual(decoded, original)
    }
}
