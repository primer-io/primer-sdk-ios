//
//  SDUITokenNamesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerBDCUI
@testable @_spi(PrimerInternal) import PrimerSDK
import SwiftUI
import XCTest

final class SDUITokenNamesTests: XCTestCase {
    func testWebStyleNamesMapOntoTheDesignTokenProperties() {
        XCTAssertEqual(SDUITokenNames.color("background-primary"), "primerColorBackgroundPrimary")
        XCTAssertEqual(SDUITokenNames.color("border-outlined-default"), "primerColorBorderOutlinedDefault")
        XCTAssertEqual(SDUITokenNames.color("text-primary"), "primerColorTextPrimary")
        XCTAssertEqual(SDUITokenNames.spacing("medium"), "primerSpaceMedium")
        XCTAssertEqual(SDUITokenNames.radius("medium"), "primerRadiusMedium")
        XCTAssertEqual(SDUITokenNames.size("xxlarge"), "primerSizeXxlarge")
    }

    func testTheResolversReadBothTheWebNamesAndThePropertyNames() {
        SDUITokenResolvers.register()
        let tokens = DesignTokens()
        XCTAssertEqual(resolveSpacing("medium"), tokens.primerSpaceMedium)
        XCTAssertEqual(resolveSpacing("primerSpaceMedium"), tokens.primerSpaceMedium)
        XCTAssertEqual(resolveRadius("medium"), tokens.primerRadiusMedium)
        XCTAssertEqual(resolveSize("large"), tokens.primerSizeLarge)
        XCTAssertNil(resolveSize("nonsense"))
        XCTAssertEqual(resolveColor("background-primary"), tokens.primerColorBackgroundPrimary)
        XCTAssertEqual(resolveColor("primerColorBackgroundPrimary"), tokens.primerColorBackgroundPrimary)
    }
}
