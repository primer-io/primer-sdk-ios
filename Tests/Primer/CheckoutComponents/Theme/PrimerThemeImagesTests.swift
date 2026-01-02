//
//  PrimerThemeImagesTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import UIKit
@testable import PrimerSDK

/// Tests for PrimerTheme+Images extension including BaseImage, BaseColoredURLs, BaseColors, and hexToUIColor.
final class PrimerThemeImagesTests: XCTestCase {

    // MARK: - BaseImage Tests

    func test_baseImage_initWithAllNil_returnsNil() {
        // When
        let image = PrimerTheme.BaseImage(colored: nil, light: nil, dark: nil)

        // Then
        XCTAssertNil(image)
    }

    func test_baseImage_initWithColoredImage_returnsInstance() {
        // Given
        let testImage = UIImage()

        // When
        let image = PrimerTheme.BaseImage(colored: testImage, light: nil, dark: nil)

        // Then
        XCTAssertNotNil(image)
        XCTAssertNotNil(image?.colored)
        XCTAssertNil(image?.light)
        XCTAssertNil(image?.dark)
    }

    func test_baseImage_initWithLightImage_returnsInstance() {
        // Given
        let testImage = UIImage()

        // When
        let image = PrimerTheme.BaseImage(colored: nil, light: testImage, dark: nil)

        // Then
        XCTAssertNotNil(image)
        XCTAssertNil(image?.colored)
        XCTAssertNotNil(image?.light)
        XCTAssertNil(image?.dark)
    }

    func test_baseImage_initWithDarkImage_returnsInstance() {
        // Given
        let testImage = UIImage()

        // When
        let image = PrimerTheme.BaseImage(colored: nil, light: nil, dark: testImage)

        // Then
        XCTAssertNotNil(image)
        XCTAssertNil(image?.colored)
        XCTAssertNil(image?.light)
        XCTAssertNotNil(image?.dark)
    }

    func test_baseImage_initWithAllImages_returnsInstance() {
        // Given
        let testImage = UIImage()

        // When
        let image = PrimerTheme.BaseImage(colored: testImage, light: testImage, dark: testImage)

        // Then
        XCTAssertNotNil(image)
        XCTAssertNotNil(image?.colored)
        XCTAssertNotNil(image?.light)
        XCTAssertNotNil(image?.dark)
    }

    // MARK: - BaseColors Tests

    func test_baseColors_initWithAllNil_returnsInstance() {
        // When - Unlike BaseColoredURLs, init does not return nil for all-nil
        let colors = PrimerTheme.BaseColors(coloredHex: nil, lightHex: nil, darkHex: nil)

        // Then
        XCTAssertNotNil(colors)
    }

    func test_baseColors_initWithColoredHex_setsProperty() {
        // When
        let colors = PrimerTheme.BaseColors(coloredHex: "#FF0000", lightHex: nil, darkHex: nil)

        // Then
        XCTAssertNotNil(colors)
        XCTAssertEqual(colors?.coloredHex, "#FF0000")
    }

    func test_baseColors_initWithAllHex_setsAllProperties() {
        // When
        let colors = PrimerTheme.BaseColors(coloredHex: "#FF0000", lightHex: "#00FF00", darkHex: "#0000FF")

        // Then
        XCTAssertNotNil(colors)
        XCTAssertEqual(colors?.coloredHex, "#FF0000")
        XCTAssertEqual(colors?.lightHex, "#00FF00")
        XCTAssertEqual(colors?.darkHex, "#0000FF")
    }

    func test_baseColors_decodable_withAllFields_succeeds() throws {
        // Given
        let json = """
        {
            "colored": "#FF0000",
            "light": "#00FF00",
            "dark": "#0000FF"
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let colors = try JSONDecoder().decode(PrimerTheme.BaseColors.self, from: data)

        // Then
        XCTAssertEqual(colors.coloredHex, "#FF0000")
        XCTAssertEqual(colors.lightHex, "#00FF00")
        XCTAssertEqual(colors.darkHex, "#0000FF")
    }

    func test_baseColors_decodable_withAllNil_throwsError() {
        // Given
        let json = "{}"
        let data = json.data(using: .utf8)!

        // When/Then
        XCTAssertThrowsError(try JSONDecoder().decode(PrimerTheme.BaseColors.self, from: data))
    }

    func test_baseColors_encodable_encodesCorrectly() throws {
        // Given
        let colors = PrimerTheme.BaseColors(coloredHex: "#123456", lightHex: "#ABCDEF", darkHex: "#789012")!

        // When
        let data = try JSONEncoder().encode(colors)
        let decoded = try JSONDecoder().decode(PrimerTheme.BaseColors.self, from: data)

        // Then
        XCTAssertEqual(decoded.coloredHex, "#123456")
        XCTAssertEqual(decoded.lightHex, "#ABCDEF")
        XCTAssertEqual(decoded.darkHex, "#789012")
    }

    // MARK: - BaseColoredURLs Tests

    func test_baseColoredURLs_initWithColoredUrl_setsProperty() {
        // When
        let urls = PrimerTheme.BaseColoredURLs(
            coloredUrlStr: "https://example.com/colored.png",
            lightUrlStr: nil,
            darkUrlStr: nil
        )

        // Then
        XCTAssertNotNil(urls)
        XCTAssertEqual(urls?.coloredUrlStr, "https://example.com/colored.png")
    }

    func test_baseColoredURLs_decodable_withAllFields_succeeds() throws {
        // Given
        let json = """
        {
            "colored": "https://example.com/colored.png",
            "light": "https://example.com/light.png",
            "dark": "https://example.com/dark.png"
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let urls = try JSONDecoder().decode(PrimerTheme.BaseColoredURLs.self, from: data)

        // Then
        XCTAssertEqual(urls.coloredUrlStr, "https://example.com/colored.png")
        XCTAssertEqual(urls.lightUrlStr, "https://example.com/light.png")
        XCTAssertEqual(urls.darkUrlStr, "https://example.com/dark.png")
    }

    func test_baseColoredURLs_decodable_withAllNil_throwsError() {
        // Given
        let json = "{}"
        let data = json.data(using: .utf8)!

        // When/Then
        XCTAssertThrowsError(try JSONDecoder().decode(PrimerTheme.BaseColoredURLs.self, from: data))
    }

    // MARK: - BaseBorderWidth Tests

    func test_baseBorderWidth_initWithValues_setsProperties() {
        // When
        let borderWidth = PrimerTheme.BaseBorderWidth(colored: 1.0, light: 0.5, dark: 2.0)

        // Then
        XCTAssertNotNil(borderWidth)
        XCTAssertEqual(borderWidth?.colored, 1.0)
        XCTAssertEqual(borderWidth?.light, 0.5)
        XCTAssertEqual(borderWidth?.dark, 2.0)
    }

    func test_baseBorderWidth_decodable_succeeds() throws {
        // Given
        let json = """
        {
            "colored": 1.0,
            "light": 0.5,
            "dark": 2.0
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let borderWidth = try JSONDecoder().decode(PrimerTheme.BaseBorderWidth.self, from: data)

        // Then
        XCTAssertEqual(borderWidth.colored, 1.0)
        XCTAssertEqual(borderWidth.light, 0.5)
        XCTAssertEqual(borderWidth.dark, 2.0)
    }

    // MARK: - hexToUIColor Tests

    func test_hexToUIColor_withValidHexWithHash_returnsColor() {
        // Given
        let hex = "#FF0000"

        // When
        let color = hex.hexToUIColor()

        // Then
        XCTAssertNotNil(color)
    }

    func test_hexToUIColor_withValidHexWithoutHash_returnsColor() {
        // Given
        let hex = "00FF00"

        // When
        let color = hex.hexToUIColor()

        // Then
        XCTAssertNotNil(color)
    }

    func test_hexToUIColor_withBlack_returnsBlack() {
        // Given
        let hex = "#000000"

        // When
        let color = hex.hexToUIColor()

        // Then
        XCTAssertNotNil(color)
        // Verify it's black by checking RGB components
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertEqual(red, 0, accuracy: 0.01)
        XCTAssertEqual(green, 0, accuracy: 0.01)
        XCTAssertEqual(blue, 0, accuracy: 0.01)
    }

    func test_hexToUIColor_withWhite_returnsWhite() {
        // Given
        let hex = "#FFFFFF"

        // When
        let color = hex.hexToUIColor()

        // Then
        XCTAssertNotNil(color)
        // Verify it's white by checking RGB components
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertEqual(red, 1, accuracy: 0.01)
        XCTAssertEqual(green, 1, accuracy: 0.01)
        XCTAssertEqual(blue, 1, accuracy: 0.01)
    }

    func test_hexToUIColor_withInvalidLength_returnsNil() {
        // Given
        let hex = "#FFF"

        // When
        let color = hex.hexToUIColor()

        // Then
        XCTAssertNil(color)
    }

    func test_hexToUIColor_withInvalidCharacters_returnsNil() {
        // Given
        let hex = "#GGGGGG"

        // When
        let color = hex.hexToUIColor()

        // Then
        XCTAssertNil(color)
    }

    func test_hexToUIColor_withWhitespace_trims() {
        // Given
        let hex = "  #FF0000  "

        // When
        let color = hex.hexToUIColor()

        // Then
        XCTAssertNotNil(color)
    }

    func test_hexToUIColor_withRed_returnsRed() {
        // Given
        let hex = "#FF0000"

        // When
        let color = hex.hexToUIColor()

        // Then
        XCTAssertNotNil(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertEqual(red, 1, accuracy: 0.01)
        XCTAssertEqual(green, 0, accuracy: 0.01)
        XCTAssertEqual(blue, 0, accuracy: 0.01)
    }
}
