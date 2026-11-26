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

    func testTheTokensReadBothTheWebNamesAndThePropertyNames() {
        let tokens = DesignTokens()
        let sduiTokens = SDUITokens(tokens)
        XCTAssertEqual(sduiTokens.spacing("medium"), tokens.primerSpaceMedium)
        XCTAssertEqual(sduiTokens.spacing("primerSpaceMedium"), tokens.primerSpaceMedium)
        XCTAssertEqual(sduiTokens.radius("medium"), tokens.primerRadiusMedium)
        XCTAssertEqual(sduiTokens.size("large"), tokens.primerSizeLarge)
        XCTAssertNil(sduiTokens.size("nonsense"))
        XCTAssertEqual(sduiTokens.color("background-primary"), tokens.primerColorBackgroundPrimary)
        XCTAssertEqual(sduiTokens.color("primerColorBackgroundPrimary"), tokens.primerColorBackgroundPrimary)
    }

    @MainActor
    func testAThemeOverridesTheTokensTheSchemaNamesReadAndDarkModeLoadsTheDarkSet() async throws {
        let purple = Color(red: 0.5, green: 0.25, blue: 0.75)
        let manager = DesignTokensManager()
        manager.applyTheme(PrimerCheckoutTheme(
            colors: ColorOverrides(primerColorBrand: purple),
            radius: RadiusOverrides(primerRadiusMedium: 20)
        ))
        try await manager.fetchTokens(for: .light)
        let themed = SDUITokens(try XCTUnwrap(manager.tokens))

        XCTAssertEqual(themed.radius("medium"), 20)
        XCTAssertEqual(themed.spacing("medium"), DesignTokens().primerSpaceMedium)
        assertPurple(themed.color("primerColorBrand"))
        assertPurple(themed.color("border-outlined-selected"))

        let plain = DesignTokensManager()
        try await plain.fetchTokens(for: .light)
        let light = SDUITokens(try XCTUnwrap(plain.tokens))
        try await plain.fetchTokens(for: .dark)
        let dark = SDUITokens(try XCTUnwrap(plain.tokens))
        XCTAssertNotEqual(light.color("background-primary"), dark.color("background-primary"))
    }

    private func assertPurple(_ color: Color, line: UInt = #line) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertEqual(red, 0.5, accuracy: 0.01, line: line)
        XCTAssertEqual(green, 0.25, accuracy: 0.01, line: line)
        XCTAssertEqual(blue, 0.75, accuracy: 0.01, line: line)
    }
}
