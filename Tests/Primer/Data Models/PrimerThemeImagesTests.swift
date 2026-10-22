//
//  PrimerThemeImagesTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import UIKit
import XCTest

final class PrimerThemeImagesTests: XCTestCase {

    private let light = UITraitCollection(userInterfaceStyle: .light)
    private let dark = UITraitCollection(userInterfaceStyle: .dark)

    override func tearDown() {
        Primer.shared.configure(settings: PrimerSettings())
        super.tearDown()
    }

    // MARK: - BaseColors

    func test_uiColor_resolvedInEachTraitCollection_returnsThatSchemesColour() {
        // Given
        let colors = PrimerTheme.BaseColors(coloredHex: "#FFFFFF", lightHex: nil, darkHex: "#000000")!

        // When
        let color = colors.uiColor!

        // Then
        XCTAssertEqual(color.resolvedColor(with: light).whiteComponent, 1, accuracy: 0.001)
        XCTAssertEqual(color.resolvedColor(with: dark).whiteComponent, 0, accuracy: 0.001)
    }

    func test_uiColor_withOnlyAColoredHex_isTheSameInBothSchemes() {
        // Given
        let colors = PrimerTheme.BaseColors(coloredHex: "#FF0000", lightHex: nil, darkHex: nil)!

        // When
        let color = colors.uiColor!

        // Then
        XCTAssertEqual(color.resolvedColor(with: light), UIColor(red: 1, green: 0, blue: 0, alpha: 1))
        XCTAssertEqual(color.resolvedColor(with: dark), UIColor(red: 1, green: 0, blue: 0, alpha: 1))
    }

    func test_uiColor_withoutAnyHex_isNil() {
        // Given
        let colors = PrimerTheme.BaseColors(coloredHex: nil, lightHex: nil, darkHex: nil)!

        // When / Then
        XCTAssertNil(colors.uiColor)
    }

    func test_uiColor_withAMalformedHex_keepsTheOneShotResolutionForTheForcedAppearance() throws {
        // Given
        let colors = PrimerTheme.BaseColors(coloredHex: "#FFFFFF", lightHex: nil, darkHex: "#FFF")!

        // When / Then
        Primer.shared.configure(settings: PrimerSettings(uiOptions: PrimerUIOptions(appearanceMode: .dark)))
        XCTAssertNil(colors.uiColor)

        Primer.shared.configure(settings: PrimerSettings(uiOptions: PrimerUIOptions(appearanceMode: .light)))
        let color = try XCTUnwrap(colors.uiColor)
        XCTAssertEqual(color.resolvedColor(with: dark).whiteComponent, 1, accuracy: 0.001)
    }

    func test_hex_isDark_prefersDarkThenColoredThenLight() {
        XCTAssertEqual(PrimerTheme.BaseColors(coloredHex: "#111111", lightHex: "#222222", darkHex: "#333333")!.hex(isDark: true), "#333333")
        XCTAssertEqual(PrimerTheme.BaseColors(coloredHex: "#111111", lightHex: "#222222", darkHex: nil)!.hex(isDark: true), "#111111")
        XCTAssertEqual(PrimerTheme.BaseColors(coloredHex: nil, lightHex: "#222222", darkHex: nil)!.hex(isDark: true), "#222222")
    }

    func test_hex_isLight_prefersColoredThenLightThenDark() {
        XCTAssertEqual(PrimerTheme.BaseColors(coloredHex: "#111111", lightHex: "#222222", darkHex: "#333333")!.hex(isDark: false), "#111111")
        XCTAssertEqual(PrimerTheme.BaseColors(coloredHex: nil, lightHex: "#222222", darkHex: "#333333")!.hex(isDark: false), "#222222")
        XCTAssertEqual(PrimerTheme.BaseColors(coloredHex: nil, lightHex: nil, darkHex: "#333333")!.hex(isDark: false), "#333333")
    }

    // MARK: - BaseBorderWidth

    func test_resolvedValue_isDark_prefersDarkThenColoredThenLight() {
        XCTAssertEqual(PrimerTheme.BaseBorderWidth(colored: 1, light: 2, dark: 3)!.resolvedValue(isDark: true), 3)
        XCTAssertEqual(PrimerTheme.BaseBorderWidth(colored: 1, light: 2, dark: nil)!.resolvedValue(isDark: true), 1)
        XCTAssertEqual(PrimerTheme.BaseBorderWidth(colored: nil, light: 2, dark: nil)!.resolvedValue(isDark: true), 2)
    }

    func test_resolvedValue_isLight_prefersColoredThenLightThenDark() {
        XCTAssertEqual(PrimerTheme.BaseBorderWidth(colored: 1, light: 2, dark: 3)!.resolvedValue(isDark: false), 1)
        XCTAssertEqual(PrimerTheme.BaseBorderWidth(colored: nil, light: 2, dark: 3)!.resolvedValue(isDark: false), 2)
        XCTAssertEqual(PrimerTheme.BaseBorderWidth(colored: nil, light: nil, dark: 3)!.resolvedValue(isDark: false), 3)
    }

    // MARK: - BaseImage

    func test_image_isDark_prefersDarkThenColoredThenLight() {
        let colored = UIImage(systemName: "paintbrush")!
        let lightImage = UIImage(systemName: "sun.max")!
        let darkImage = UIImage(systemName: "sun.min")!

        XCTAssertEqual(PrimerTheme.BaseImage(colored: colored, light: lightImage, dark: darkImage)!.image(isDark: true), darkImage)
        XCTAssertEqual(PrimerTheme.BaseImage(colored: colored, light: lightImage, dark: nil)!.image(isDark: true), colored)
        XCTAssertEqual(PrimerTheme.BaseImage(colored: nil, light: lightImage, dark: nil)!.image(isDark: true), lightImage)
    }

    func test_image_isLight_prefersColoredThenLightThenDark() {
        let colored = UIImage(systemName: "paintbrush")!
        let lightImage = UIImage(systemName: "sun.max")!
        let darkImage = UIImage(systemName: "sun.min")!

        XCTAssertEqual(PrimerTheme.BaseImage(colored: colored, light: lightImage, dark: darkImage)!.image(isDark: false), colored)
        XCTAssertEqual(PrimerTheme.BaseImage(colored: nil, light: lightImage, dark: darkImage)!.image(isDark: false), lightImage)
        XCTAssertEqual(PrimerTheme.BaseImage(colored: nil, light: nil, dark: darkImage)!.image(isDark: false), darkImage)
    }
}

private extension UIColor {
    var whiteComponent: CGFloat {
        var white: CGFloat = 0
        getWhite(&white, alpha: nil)
        return white
    }
}
