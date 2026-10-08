//
//  PaymentMethodAssetVariantTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class PaymentMethodAssetVariantTests: XCTestCase {

    private typealias Variant = PaymentMethodAssetVariant

    // MARK: - pick

    func test_pick_allVersionsInLight_returnsColored() {
        XCTAssertEqual(Variant.pick(colored: "c", light: "l", dark: "d", isDark: false), .colored)
    }

    func test_pick_allVersionsInDark_returnsColored() {
        XCTAssertEqual(Variant.pick(colored: "c", light: "l", dark: "d", isDark: true), .colored)
    }

    func test_pick_noColoredInLight_returnsLight() {
        XCTAssertEqual(Variant.pick(colored: nil, light: "l", dark: "d", isDark: false), .light)
    }

    func test_pick_noColoredInDark_returnsDark() {
        XCTAssertEqual(Variant.pick(colored: nil, light: "l", dark: "d", isDark: true), .dark)
    }

    func test_pick_onlyDarkInLight_returnsDark() {
        XCTAssertEqual(Variant.pick(colored: nil, light: nil, dark: "d", isDark: false), .dark)
    }

    func test_pick_onlyLightInDark_returnsLight() {
        XCTAssertEqual(Variant.pick(colored: nil, light: "l", dark: nil, isDark: true), .light)
    }

    func test_pick_noVersions_returnsNil() {
        XCTAssertNil(Variant.pick(colored: String?.none, light: nil, dark: nil, isDark: false))
        XCTAssertNil(Variant.pick(colored: String?.none, light: nil, dark: nil, isDark: true))
    }

    // MARK: - forBackground

    func test_forBackground_noBackground_followsTheMode() {
        XCTAssertEqual(Variant.forBackground(nil, isDark: false), .light)
        XCTAssertEqual(Variant.forBackground(nil, isDark: true), .dark)
    }

    func test_forBackground_coloredBackground_returnsColoredInBothModes() {
        // Given
        let background = PrimerTheme.BaseColors(coloredHex: "#FFC439", lightHex: "#FFFFFF", darkHex: "#000000")

        // When / Then
        XCTAssertEqual(Variant.forBackground(background, isDark: false), .colored)
        XCTAssertEqual(Variant.forBackground(background, isDark: true), .colored)
    }

    // MARK: - valueOrAny

    func test_valueOrAny_coloredWithOnlyDarkValue_returnsDarkValue() {
        XCTAssertEqual(Variant.colored.valueOrAny(colored: nil, light: nil, dark: "d", isDark: false), "d")
    }

    func test_valueOrAny_lightWithOnlyColoredValue_returnsColoredValue() {
        XCTAssertEqual(Variant.light.valueOrAny(colored: "c", light: nil, dark: nil, isDark: false), "c")
    }

    func test_valueOrAny_versionPresent_returnsItsOwnValue() {
        XCTAssertEqual(Variant.dark.valueOrAny(colored: "c", light: "l", dark: "d", isDark: false), "d")
    }

    func test_valueOrAny_noValues_returnsNil() {
        XCTAssertNil(Variant.light.valueOrAny(colored: String?.none, light: nil, dark: nil, isDark: true))
    }
}
