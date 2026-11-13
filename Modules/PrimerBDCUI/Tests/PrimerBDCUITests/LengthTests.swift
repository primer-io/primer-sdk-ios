//
//  LengthTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerBDCUI
@_spi(PrimerInternal) import PrimerFoundation
import XCTest

final class LengthTests: XCTestCase {
    func testANumberIsALiteralAndANameIsAToken() throws {
        XCTAssertEqual(try decode("8"), .literal(8))
        XCTAssertEqual(try decode("\"12\""), .literal(12))
        XCTAssertEqual(try decode("\"medium\""), .token("medium"))
    }

    func testATokenResolvesThroughTheResolverAndALiteralDoesNot() {
        XCTAssertEqual(Length.token("medium")({ $0 == "medium" ? 8 : nil }), 8)
        XCTAssertEqual(Length.literal(6)({ _ in 99 }), 6)
        XCTAssertNil(Length.token("unknown")({ _ in nil }))
    }

    func testASizeNameIsATokenAndANumericStringALiteral() {
        XCTAssertEqual(Size(codableValue: .string("large")), .token("large"))
        XCTAssertEqual(Size(codableValue: .string("48")), .literal(48))
        XCTAssertEqual(Size(codableValue: .string("fill")), .fill)
    }

    func testAColumnReadsTokenRadiusAndMinHeightAndDefaultsTheBorderWidthToItsColour() throws {
        let props = try JSONDecoder().decode(ColumnProps.self, from: Data("""
        {"borderRadius": "medium", "minHeight": "xxlarge", "borderColor": "border-outlined-default"}
        """.utf8))
        XCTAssertEqual(props.borderRadius, .token("medium"))
        XCTAssertEqual(props.minHeight, .token("xxlarge"))
        XCTAssertEqual(props.strokeWidth, 1)
        XCTAssertEqual(try JSONDecoder().decode(ColumnProps.self, from: Data("{}".utf8)).strokeWidth, 0)
    }

    func testSpacingReadsNumbersAndNames() {
        resolveSpacing = { $0 == "medium" ? 12 : 0 }
        XCTAssertEqual(Spacing.value(of: .int(10)), 10)
        XCTAssertEqual(Spacing.value(of: .string("medium")), 12)
        XCTAssertEqual(Spacing.value(of: .string("4")), 4)
    }

    private func decode(_ json: String) throws -> Length {
        try JSONDecoder().decode(Length.self, from: Data(json.utf8))
    }
}
