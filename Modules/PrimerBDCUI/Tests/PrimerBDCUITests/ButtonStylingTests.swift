//
//  ButtonStylingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerBDCUI
@_spi(PrimerInternal) import PrimerFoundation
import XCTest

final class ButtonStylingTests: XCTestCase {
    func testAPrimaryButtonIsFilledWithTheBrandColour() throws {
        let styling = try decode(#"{"variant": "primary"}"#).styling
        XCTAssertEqual(styling, ButtonStyling(
            backgroundColor: "primerColorBrand", borderColor: nil, foregroundColor: "primerColorGray000", borderRadius: .token("medium")
        ))
    }

    func testASecondaryButtonIsOutlined() throws {
        let styling = try decode(#"{"variant": "secondary"}"#).styling
        XCTAssertEqual(styling, ButtonStyling(
            backgroundColor: "background-primary", borderColor: "border-outlined-default", foregroundColor: "text-primary", borderRadius: .token("medium")
        ))
    }

    func testATertiaryButtonIsBare() throws {
        let styling = try decode(#"{"variant": "tertiary"}"#).styling
        XCTAssertNil(styling.backgroundColor)
        XCTAssertNil(styling.borderColor)
        XCTAssertNil(styling.foregroundColor)
    }

    func testThePropsOverrideTheVariant() throws {
        let styling = try decode(#"{"variant": "primary", "backgroundColor": "background-secondary", "borderColor": "border-outlined-error", "borderRadius": 6}"#).styling
        XCTAssertEqual(styling.backgroundColor, "background-secondary")
        XCTAssertEqual(styling.borderColor, "border-outlined-error")
        XCTAssertEqual(styling.borderRadius, .literal(6))
    }

    func testAnUnknownVariantIsPrimary() throws {
        XCTAssertEqual(try decode(#"{"variant": "fancy"}"#).variant, .primary)
    }

    private func decode(_ json: String) throws -> ButtonProps {
        try JSONDecoder().decode(ButtonProps.self, from: Data(json.utf8))
    }
}
