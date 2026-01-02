//
//  DesignTokensTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

/// Tests for DesignTokens covering default values and Decodable conformance.
@available(iOS 15.0, *)
final class DesignTokensTests: XCTestCase {

    // MARK: - Default Initializer Tests

    func test_defaultInit_backgroundColorIsNotNil() {
        // Given/When
        let tokens = DesignTokens()

        // Then
        XCTAssertNotNil(tokens.primerColorBackground)
    }

    func test_defaultInit_textColorsAreNotNil() {
        // Given/When
        let tokens = DesignTokens()

        // Then
        XCTAssertNotNil(tokens.primerColorTextPrimary)
        XCTAssertNotNil(tokens.primerColorTextPlaceholder)
        XCTAssertNotNil(tokens.primerColorTextDisabled)
        XCTAssertNotNil(tokens.primerColorTextNegative)
        XCTAssertNotNil(tokens.primerColorTextLink)
        XCTAssertNotNil(tokens.primerColorTextSecondary)
    }

    func test_defaultInit_borderOutlinedColorsAreNotNil() {
        // Given/When
        let tokens = DesignTokens()

        // Then
        XCTAssertNotNil(tokens.primerColorBorderOutlinedDefault)
        XCTAssertNotNil(tokens.primerColorBorderOutlinedHover)
        XCTAssertNotNil(tokens.primerColorBorderOutlinedActive)
        XCTAssertNotNil(tokens.primerColorBorderOutlinedFocus)
        XCTAssertNotNil(tokens.primerColorBorderOutlinedDisabled)
        XCTAssertNotNil(tokens.primerColorBorderOutlinedLoading)
        XCTAssertNotNil(tokens.primerColorBorderOutlinedSelected)
        XCTAssertNotNil(tokens.primerColorBorderOutlinedError)
    }

    func test_defaultInit_borderTransparentColorsAreNotNil() {
        // Given/When
        let tokens = DesignTokens()

        // Then
        XCTAssertNotNil(tokens.primerColorBorderTransparentDefault)
        XCTAssertNotNil(tokens.primerColorBorderTransparentHover)
        XCTAssertNotNil(tokens.primerColorBorderTransparentActive)
        XCTAssertNotNil(tokens.primerColorBorderTransparentFocus)
        XCTAssertNotNil(tokens.primerColorBorderTransparentDisabled)
        XCTAssertNotNil(tokens.primerColorBorderTransparentSelected)
    }

    func test_defaultInit_iconColorsAreNotNil() {
        // Given/When
        let tokens = DesignTokens()

        // Then
        XCTAssertNotNil(tokens.primerColorIconPrimary)
        XCTAssertNotNil(tokens.primerColorIconDisabled)
        XCTAssertNotNil(tokens.primerColorIconNegative)
        XCTAssertNotNil(tokens.primerColorIconPositive)
    }

    func test_defaultInit_utilityColorsAreNotNil() {
        // Given/When
        let tokens = DesignTokens()

        // Then
        XCTAssertNotNil(tokens.primerColorFocus)
        XCTAssertNotNil(tokens.primerColorLoader)
    }

    func test_defaultInit_grayColorsAreNotNil() {
        // Given/When
        let tokens = DesignTokens()

        // Then
        XCTAssertNotNil(tokens.primerColorGray000)
        XCTAssertNotNil(tokens.primerColorGray100)
        XCTAssertNotNil(tokens.primerColorGray200)
        XCTAssertNotNil(tokens.primerColorGray300)
        XCTAssertNotNil(tokens.primerColorGray400)
        XCTAssertNotNil(tokens.primerColorGray500)
        XCTAssertNotNil(tokens.primerColorGray600)
        XCTAssertNotNil(tokens.primerColorGray700)
        XCTAssertNotNil(tokens.primerColorGray900)
    }

    func test_defaultInit_brandColorsAreNotNil() {
        // Given/When
        let tokens = DesignTokens()

        // Then
        XCTAssertNotNil(tokens.primerColorGreen500)
        XCTAssertNotNil(tokens.primerColorBrand)
        XCTAssertNotNil(tokens.primerColorRed100)
        XCTAssertNotNil(tokens.primerColorRed500)
        XCTAssertNotNil(tokens.primerColorRed900)
        XCTAssertNotNil(tokens.primerColorBlue500)
        XCTAssertNotNil(tokens.primerColorBlue900)
    }

    func test_defaultInit_radiusValuesAreCorrect() {
        // Given/When
        let tokens = DesignTokens()

        // Then
        XCTAssertEqual(tokens.primerRadiusMedium, 8)
        XCTAssertEqual(tokens.primerRadiusSmall, 4)
        XCTAssertEqual(tokens.primerRadiusLarge, 12)
        XCTAssertEqual(tokens.primerRadiusXsmall, 2)
        XCTAssertEqual(tokens.primerRadiusBase, 4)
    }

    func test_defaultInit_typographyBrandIsCorrect() {
        // Given/When
        let tokens = DesignTokens()

        // Then
        XCTAssertEqual(tokens.primerTypographyBrand, "Inter")
    }

    func test_defaultInit_typographyTitleXlargeIsCorrect() {
        // Given/When
        let tokens = DesignTokens()

        // Then
        XCTAssertEqual(tokens.primerTypographyTitleXlargeFont, "Inter")
        XCTAssertEqual(tokens.primerTypographyTitleXlargeLetterSpacing, -0.6)
        XCTAssertEqual(tokens.primerTypographyTitleXlargeWeight, 550)
        XCTAssertEqual(tokens.primerTypographyTitleXlargeSize, 24)
        XCTAssertEqual(tokens.primerTypographyTitleXlargeLineHeight, 32)
    }

    func test_defaultInit_typographyTitleLargeIsCorrect() {
        // Given/When
        let tokens = DesignTokens()

        // Then
        XCTAssertEqual(tokens.primerTypographyTitleLargeFont, "Inter")
        XCTAssertEqual(tokens.primerTypographyTitleLargeLetterSpacing, -0.2)
        XCTAssertEqual(tokens.primerTypographyTitleLargeWeight, 550)
        XCTAssertEqual(tokens.primerTypographyTitleLargeSize, 16)
        XCTAssertEqual(tokens.primerTypographyTitleLargeLineHeight, 20)
    }

    func test_defaultInit_typographyBodyLargeIsCorrect() {
        // Given/When
        let tokens = DesignTokens()

        // Then
        XCTAssertEqual(tokens.primerTypographyBodyLargeFont, "Inter")
        XCTAssertEqual(tokens.primerTypographyBodyLargeLetterSpacing, -0.2)
        XCTAssertEqual(tokens.primerTypographyBodyLargeWeight, 400)
        XCTAssertEqual(tokens.primerTypographyBodyLargeSize, 16)
        XCTAssertEqual(tokens.primerTypographyBodyLargeLineHeight, 20)
    }

    func test_defaultInit_typographyBodyMediumIsCorrect() {
        // Given/When
        let tokens = DesignTokens()

        // Then
        XCTAssertEqual(tokens.primerTypographyBodyMediumFont, "Inter")
        XCTAssertEqual(tokens.primerTypographyBodyMediumLetterSpacing, 0)
        XCTAssertEqual(tokens.primerTypographyBodyMediumWeight, 400)
        XCTAssertEqual(tokens.primerTypographyBodyMediumSize, 14)
        XCTAssertEqual(tokens.primerTypographyBodyMediumLineHeight, 20)
    }

    func test_defaultInit_typographyBodySmallIsCorrect() {
        // Given/When
        let tokens = DesignTokens()

        // Then
        XCTAssertEqual(tokens.primerTypographyBodySmallFont, "Inter")
        XCTAssertEqual(tokens.primerTypographyBodySmallLetterSpacing, 0)
        XCTAssertEqual(tokens.primerTypographyBodySmallWeight, 400)
        XCTAssertEqual(tokens.primerTypographyBodySmallSize, 12)
        XCTAssertEqual(tokens.primerTypographyBodySmallLineHeight, 16)
    }

    func test_defaultInit_spacingValuesAreCorrect() {
        // Given/When
        let tokens = DesignTokens()

        // Then
        XCTAssertEqual(tokens.primerSpaceXxsmall, 2)
        XCTAssertEqual(tokens.primerSpaceXsmall, 4)
        XCTAssertEqual(tokens.primerSpaceSmall, 8)
        XCTAssertEqual(tokens.primerSpaceMedium, 12)
        XCTAssertEqual(tokens.primerSpaceLarge, 16)
        XCTAssertEqual(tokens.primerSpaceXlarge, 20)
        XCTAssertEqual(tokens.primerSpaceXxlarge, 24)
        XCTAssertEqual(tokens.primerSpaceBase, 4)
    }

    func test_defaultInit_sizeValuesAreCorrect() {
        // Given/When
        let tokens = DesignTokens()

        // Then
        XCTAssertEqual(tokens.primerSizeSmall, 16)
        XCTAssertEqual(tokens.primerSizeMedium, 20)
        XCTAssertEqual(tokens.primerSizeLarge, 24)
        XCTAssertEqual(tokens.primerSizeXlarge, 32)
        XCTAssertEqual(tokens.primerSizeXxlarge, 44)
        XCTAssertEqual(tokens.primerSizeXxxlarge, 56)
        XCTAssertEqual(tokens.primerSizeBase, 4)
    }

    // MARK: - Decodable Tests - Empty JSON

    func test_decode_withEmptyJSON_preservesDefaultColors() throws {
        // Given
        let json = "{}"
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokens.self, from: data)

        // Then - defaults should be preserved
        XCTAssertNotNil(tokens.primerColorBackground)
        XCTAssertNotNil(tokens.primerColorTextPrimary)
        XCTAssertNotNil(tokens.primerColorBrand)
    }

    func test_decode_withEmptyJSON_preservesDefaultRadii() throws {
        // Given
        let json = "{}"
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokens.self, from: data)

        // Then - default radii should be nil (decodeIfPresent returns nil for missing keys)
        XCTAssertNil(tokens.primerRadiusMedium)
        XCTAssertNil(tokens.primerRadiusSmall)
    }

    // MARK: - Decodable Tests - Color Decoding

    func test_decode_withValidColor_decodesCorrectly() throws {
        // Given
        let json = """
        {
            "primerColorBackground": [1.0, 0.5, 0.0, 1.0]
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokens.self, from: data)

        // Then
        XCTAssertNotNil(tokens.primerColorBackground)
    }

    func test_decode_withAllTextColors_decodesCorrectly() throws {
        // Given
        let json = """
        {
            "primerColorTextPrimary": [0.1, 0.1, 0.1, 1.0],
            "primerColorTextPlaceholder": [0.6, 0.6, 0.6, 1.0],
            "primerColorTextDisabled": [0.7, 0.7, 0.7, 1.0],
            "primerColorTextNegative": [0.7, 0.2, 0.3, 1.0],
            "primerColorTextLink": [0.1, 0.4, 0.9, 1.0],
            "primerColorTextSecondary": [0.4, 0.4, 0.4, 1.0]
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokens.self, from: data)

        // Then
        XCTAssertNotNil(tokens.primerColorTextPrimary)
        XCTAssertNotNil(tokens.primerColorTextPlaceholder)
        XCTAssertNotNil(tokens.primerColorTextDisabled)
        XCTAssertNotNil(tokens.primerColorTextNegative)
        XCTAssertNotNil(tokens.primerColorTextLink)
        XCTAssertNotNil(tokens.primerColorTextSecondary)
    }

    func test_decode_withBorderOutlinedColors_decodesCorrectly() throws {
        // Given
        let json = """
        {
            "primerColorBorderOutlinedDefault": [0.8, 0.8, 0.8, 1.0],
            "primerColorBorderOutlinedHover": [0.7, 0.7, 0.7, 1.0],
            "primerColorBorderOutlinedActive": [0.6, 0.6, 0.6, 1.0],
            "primerColorBorderOutlinedFocus": [0.2, 0.6, 1.0, 1.0],
            "primerColorBorderOutlinedDisabled": [0.9, 0.9, 0.9, 1.0],
            "primerColorBorderOutlinedLoading": [0.9, 0.9, 0.9, 1.0],
            "primerColorBorderOutlinedSelected": [0.2, 0.6, 1.0, 1.0],
            "primerColorBorderOutlinedError": [1.0, 0.4, 0.5, 1.0]
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokens.self, from: data)

        // Then
        XCTAssertNotNil(tokens.primerColorBorderOutlinedDefault)
        XCTAssertNotNil(tokens.primerColorBorderOutlinedHover)
        XCTAssertNotNil(tokens.primerColorBorderOutlinedActive)
        XCTAssertNotNil(tokens.primerColorBorderOutlinedFocus)
        XCTAssertNotNil(tokens.primerColorBorderOutlinedDisabled)
        XCTAssertNotNil(tokens.primerColorBorderOutlinedLoading)
        XCTAssertNotNil(tokens.primerColorBorderOutlinedSelected)
        XCTAssertNotNil(tokens.primerColorBorderOutlinedError)
    }

    func test_decode_withBorderTransparentColors_decodesCorrectly() throws {
        // Given
        let json = """
        {
            "primerColorBorderTransparentDefault": [1.0, 1.0, 1.0, 0.0],
            "primerColorBorderTransparentHover": [1.0, 1.0, 1.0, 0.0],
            "primerColorBorderTransparentActive": [1.0, 1.0, 1.0, 0.0],
            "primerColorBorderTransparentFocus": [0.2, 0.6, 1.0, 1.0],
            "primerColorBorderTransparentDisabled": [1.0, 1.0, 1.0, 0.0],
            "primerColorBorderTransparentSelected": [1.0, 1.0, 1.0, 0.0]
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokens.self, from: data)

        // Then
        XCTAssertNotNil(tokens.primerColorBorderTransparentDefault)
        XCTAssertNotNil(tokens.primerColorBorderTransparentHover)
        XCTAssertNotNil(tokens.primerColorBorderTransparentActive)
        XCTAssertNotNil(tokens.primerColorBorderTransparentFocus)
        XCTAssertNotNil(tokens.primerColorBorderTransparentDisabled)
        XCTAssertNotNil(tokens.primerColorBorderTransparentSelected)
    }

    func test_decode_withIconColors_decodesCorrectly() throws {
        // Given
        let json = """
        {
            "primerColorIconPrimary": [0.1, 0.1, 0.1, 1.0],
            "primerColorIconDisabled": [0.7, 0.7, 0.7, 1.0],
            "primerColorIconNegative": [1.0, 0.4, 0.5, 1.0],
            "primerColorIconPositive": [0.2, 0.7, 0.6, 1.0]
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokens.self, from: data)

        // Then
        XCTAssertNotNil(tokens.primerColorIconPrimary)
        XCTAssertNotNil(tokens.primerColorIconDisabled)
        XCTAssertNotNil(tokens.primerColorIconNegative)
        XCTAssertNotNil(tokens.primerColorIconPositive)
    }

    func test_decode_withGrayColors_decodesCorrectly() throws {
        // Given
        let json = """
        {
            "primerColorGray000": [1.0, 1.0, 1.0, 1.0],
            "primerColorGray100": [0.96, 0.96, 0.96, 1.0],
            "primerColorGray200": [0.93, 0.93, 0.93, 1.0],
            "primerColorGray300": [0.88, 0.88, 0.88, 1.0],
            "primerColorGray400": [0.74, 0.74, 0.74, 1.0],
            "primerColorGray500": [0.62, 0.62, 0.62, 1.0],
            "primerColorGray600": [0.46, 0.46, 0.46, 1.0],
            "primerColorGray700": [0.29, 0.29, 0.29, 1.0],
            "primerColorGray900": [0.13, 0.13, 0.13, 1.0]
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokens.self, from: data)

        // Then
        XCTAssertNotNil(tokens.primerColorGray000)
        XCTAssertNotNil(tokens.primerColorGray100)
        XCTAssertNotNil(tokens.primerColorGray200)
        XCTAssertNotNil(tokens.primerColorGray300)
        XCTAssertNotNil(tokens.primerColorGray400)
        XCTAssertNotNil(tokens.primerColorGray500)
        XCTAssertNotNil(tokens.primerColorGray600)
        XCTAssertNotNil(tokens.primerColorGray700)
        XCTAssertNotNil(tokens.primerColorGray900)
    }

    func test_decode_withTransparentColor_decodesCorrectly() throws {
        // Given - color with 0 opacity
        let json = """
        {
            "primerColorBorderTransparentDefault": [1.0, 1.0, 1.0, 0.0]
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokens.self, from: data)

        // Then
        XCTAssertNotNil(tokens.primerColorBorderTransparentDefault)
    }

    // MARK: - Decodable Tests - CGFloat Decoding

    func test_decode_withRadiusValues_decodesCorrectly() throws {
        // Given
        let json = """
        {
            "primerRadiusMedium": 10,
            "primerRadiusSmall": 5,
            "primerRadiusLarge": 15,
            "primerRadiusXsmall": 3,
            "primerRadiusBase": 5
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokens.self, from: data)

        // Then
        XCTAssertEqual(tokens.primerRadiusMedium, 10)
        XCTAssertEqual(tokens.primerRadiusSmall, 5)
        XCTAssertEqual(tokens.primerRadiusLarge, 15)
        XCTAssertEqual(tokens.primerRadiusXsmall, 3)
        XCTAssertEqual(tokens.primerRadiusBase, 5)
    }

    func test_decode_withSpacingValues_decodesCorrectly() throws {
        // Given
        let json = """
        {
            "primerSpaceXxsmall": 4,
            "primerSpaceXsmall": 8,
            "primerSpaceSmall": 12,
            "primerSpaceMedium": 16,
            "primerSpaceLarge": 24,
            "primerSpaceXlarge": 32,
            "primerSpaceXxlarge": 40,
            "primerSpaceBase": 8
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokens.self, from: data)

        // Then
        XCTAssertEqual(tokens.primerSpaceXxsmall, 4)
        XCTAssertEqual(tokens.primerSpaceXsmall, 8)
        XCTAssertEqual(tokens.primerSpaceSmall, 12)
        XCTAssertEqual(tokens.primerSpaceMedium, 16)
        XCTAssertEqual(tokens.primerSpaceLarge, 24)
        XCTAssertEqual(tokens.primerSpaceXlarge, 32)
        XCTAssertEqual(tokens.primerSpaceXxlarge, 40)
        XCTAssertEqual(tokens.primerSpaceBase, 8)
    }

    func test_decode_withSizeValues_decodesCorrectly() throws {
        // Given
        let json = """
        {
            "primerSizeSmall": 20,
            "primerSizeMedium": 24,
            "primerSizeLarge": 28,
            "primerSizeXlarge": 36,
            "primerSizeXxlarge": 48,
            "primerSizeXxxlarge": 60,
            "primerSizeBase": 8
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokens.self, from: data)

        // Then
        XCTAssertEqual(tokens.primerSizeSmall, 20)
        XCTAssertEqual(tokens.primerSizeMedium, 24)
        XCTAssertEqual(tokens.primerSizeLarge, 28)
        XCTAssertEqual(tokens.primerSizeXlarge, 36)
        XCTAssertEqual(tokens.primerSizeXxlarge, 48)
        XCTAssertEqual(tokens.primerSizeXxxlarge, 60)
        XCTAssertEqual(tokens.primerSizeBase, 8)
    }

    // MARK: - Decodable Tests - String Decoding

    func test_decode_withTypographyFonts_decodesCorrectly() throws {
        // Given
        let json = """
        {
            "primerTypographyBrand": "CustomFont",
            "primerTypographyTitleXlargeFont": "CustomFont-Bold",
            "primerTypographyTitleLargeFont": "CustomFont-Medium",
            "primerTypographyBodyLargeFont": "CustomFont-Regular",
            "primerTypographyBodyMediumFont": "CustomFont-Regular",
            "primerTypographyBodySmallFont": "CustomFont-Light"
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokens.self, from: data)

        // Then
        XCTAssertEqual(tokens.primerTypographyBrand, "CustomFont")
        XCTAssertEqual(tokens.primerTypographyTitleXlargeFont, "CustomFont-Bold")
        XCTAssertEqual(tokens.primerTypographyTitleLargeFont, "CustomFont-Medium")
        XCTAssertEqual(tokens.primerTypographyBodyLargeFont, "CustomFont-Regular")
        XCTAssertEqual(tokens.primerTypographyBodyMediumFont, "CustomFont-Regular")
        XCTAssertEqual(tokens.primerTypographyBodySmallFont, "CustomFont-Light")
    }

    func test_decode_withTypographyValues_decodesCorrectly() throws {
        // Given
        let json = """
        {
            "primerTypographyTitleXlargeLetterSpacing": -0.8,
            "primerTypographyTitleXlargeWeight": 600,
            "primerTypographyTitleXlargeSize": 28,
            "primerTypographyTitleXlargeLineHeight": 36
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokens.self, from: data)

        // Then
        XCTAssertEqual(tokens.primerTypographyTitleXlargeLetterSpacing, -0.8)
        XCTAssertEqual(tokens.primerTypographyTitleXlargeWeight, 600)
        XCTAssertEqual(tokens.primerTypographyTitleXlargeSize, 28)
        XCTAssertEqual(tokens.primerTypographyTitleXlargeLineHeight, 36)
    }

    // MARK: - Partial Decode Tests

    func test_decode_withPartialJSON_decodesOnlyProvided() throws {
        // Given - only some properties are provided
        let json = """
        {
            "primerColorBrand": [0.0, 0.5, 1.0, 1.0],
            "primerRadiusMedium": 16,
            "primerTypographyBrand": "Roboto"
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokens.self, from: data)

        // Then - decoded values
        XCTAssertNotNil(tokens.primerColorBrand)
        XCTAssertEqual(tokens.primerRadiusMedium, 16)
        XCTAssertEqual(tokens.primerTypographyBrand, "Roboto")

        // Other values should be nil (from decodeIfPresent)
        XCTAssertNil(tokens.primerRadiusSmall)
        XCTAssertNil(tokens.primerSpaceSmall)
    }

    // MARK: - Complete JSON Tests

    func test_decode_withCompleteJSON_decodesAllValues() throws {
        // Given - comprehensive JSON with all property types
        let json = """
        {
            "primerColorBackground": [0.95, 0.95, 0.95, 1.0],
            "primerColorTextPrimary": [0.1, 0.1, 0.1, 1.0],
            "primerColorBrand": [0.2, 0.5, 0.9, 1.0],
            "primerColorFocus": [0.0, 0.5, 1.0, 1.0],
            "primerColorLoader": [0.0, 0.5, 1.0, 1.0],
            "primerRadiusMedium": 12,
            "primerRadiusSmall": 6,
            "primerRadiusLarge": 18,
            "primerTypographyBrand": "SF Pro",
            "primerTypographyTitleXlargeFont": "SF Pro",
            "primerTypographyTitleXlargeSize": 26,
            "primerSpaceSmall": 10,
            "primerSpaceMedium": 14,
            "primerSizeSmall": 18,
            "primerSizeMedium": 22
        }
        """
        let data = json.data(using: .utf8)!

        // When
        let tokens = try JSONDecoder().decode(DesignTokens.self, from: data)

        // Then
        XCTAssertNotNil(tokens.primerColorBackground)
        XCTAssertNotNil(tokens.primerColorTextPrimary)
        XCTAssertNotNil(tokens.primerColorBrand)
        XCTAssertNotNil(tokens.primerColorFocus)
        XCTAssertNotNil(tokens.primerColorLoader)
        XCTAssertEqual(tokens.primerRadiusMedium, 12)
        XCTAssertEqual(tokens.primerRadiusSmall, 6)
        XCTAssertEqual(tokens.primerRadiusLarge, 18)
        XCTAssertEqual(tokens.primerTypographyBrand, "SF Pro")
        XCTAssertEqual(tokens.primerTypographyTitleXlargeFont, "SF Pro")
        XCTAssertEqual(tokens.primerTypographyTitleXlargeSize, 26)
        XCTAssertEqual(tokens.primerSpaceSmall, 10)
        XCTAssertEqual(tokens.primerSpaceMedium, 14)
        XCTAssertEqual(tokens.primerSizeSmall, 18)
        XCTAssertEqual(tokens.primerSizeMedium, 22)
    }

    // MARK: - CodingKeys Tests

    func test_codingKeys_allKeysMatchPropertyNames() {
        // Given - access enum cases via rawValue
        let keys: [DesignTokens.CodingKeys] = [
            .primerColorBackground,
            .primerColorTextPrimary,
            .primerColorBrand,
            .primerRadiusMedium,
            .primerTypographyBrand,
            .primerSpaceSmall,
            .primerSizeSmall
        ]

        // Then - verify raw values match expected strings
        XCTAssertEqual(DesignTokens.CodingKeys.primerColorBackground.rawValue, "primerColorBackground")
        XCTAssertEqual(DesignTokens.CodingKeys.primerColorTextPrimary.rawValue, "primerColorTextPrimary")
        XCTAssertEqual(DesignTokens.CodingKeys.primerColorBrand.rawValue, "primerColorBrand")
        XCTAssertEqual(DesignTokens.CodingKeys.primerRadiusMedium.rawValue, "primerRadiusMedium")
        XCTAssertEqual(DesignTokens.CodingKeys.primerTypographyBrand.rawValue, "primerTypographyBrand")
        XCTAssertEqual(DesignTokens.CodingKeys.primerSpaceSmall.rawValue, "primerSpaceSmall")
        XCTAssertEqual(DesignTokens.CodingKeys.primerSizeSmall.rawValue, "primerSizeSmall")
        XCTAssertEqual(keys.count, 7)
    }
}
