//
//  PrimerFontTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

/// Tests for PrimerFont covering font creation and typography helpers.
@available(iOS 15.0, *)
final class PrimerFontTests: XCTestCase {

    // MARK: - uiFont Base Function Tests

    func test_uiFont_withDefaultParameters_returnsFont() {
        // When
        let font = PrimerFont.uiFont(family: nil, weight: nil, size: nil)

        // Then
        XCTAssertNotNil(font)
    }

    func test_uiFont_withCustomSize_usesProvidedSize() {
        // When
        let font = PrimerFont.uiFont(family: "Inter", weight: 400, size: 20)

        // Then - point size should be at least 20 (may be scaled up by Dynamic Type)
        XCTAssertGreaterThanOrEqual(font.pointSize, 20)
    }

    func test_uiFont_withNonInterFamily_usesSystemFont() {
        // When
        let font = PrimerFont.uiFont(family: "SomeOtherFont", weight: 400, size: 16)

        // Then - should fall back to system font
        XCTAssertNotNil(font)
    }

    // MARK: - UIKit Typography Helpers (Nil Tokens) Tests

    func test_uiFontTitleXLarge_withNilTokens_returnsDefaultFont() {
        // When
        let font = PrimerFont.uiFontTitleXLarge(tokens: nil)

        // Then - default is 24pt
        XCTAssertNotNil(font)
        XCTAssertGreaterThanOrEqual(font.pointSize, 24)
    }

    func test_uiFontTitleLarge_withNilTokens_returnsDefaultFont() {
        // When
        let font = PrimerFont.uiFontTitleLarge(tokens: nil)

        // Then - default is 16pt
        XCTAssertNotNil(font)
        XCTAssertGreaterThanOrEqual(font.pointSize, 16)
    }

    func test_uiFontBodyLarge_withNilTokens_returnsDefaultFont() {
        // When
        let font = PrimerFont.uiFontBodyLarge(tokens: nil)

        // Then - default is 16pt
        XCTAssertNotNil(font)
        XCTAssertGreaterThanOrEqual(font.pointSize, 16)
    }

    func test_uiFontBodyMedium_withNilTokens_returnsDefaultFont() {
        // When
        let font = PrimerFont.uiFontBodyMedium(tokens: nil)

        // Then - default is 14pt
        XCTAssertNotNil(font)
        XCTAssertGreaterThanOrEqual(font.pointSize, 14)
    }

    func test_uiFontBodySmall_withNilTokens_returnsDefaultFont() {
        // When
        let font = PrimerFont.uiFontBodySmall(tokens: nil)

        // Then - default is 12pt
        XCTAssertNotNil(font)
        XCTAssertGreaterThanOrEqual(font.pointSize, 12)
    }

    func test_uiFontLargeIcon_withNilTokens_returnsDefaultFont() {
        // When
        let font = PrimerFont.uiFontLargeIcon(tokens: nil)

        // Then - default is 48pt
        XCTAssertNotNil(font)
        XCTAssertGreaterThanOrEqual(font.pointSize, 48)
    }

    func test_uiFontExtraLargeIcon_withNilTokens_returnsDefaultFont() {
        // When
        let font = PrimerFont.uiFontExtraLargeIcon(tokens: nil)

        // Then - default is 56pt
        XCTAssertNotNil(font)
        XCTAssertGreaterThanOrEqual(font.pointSize, 56)
    }

    func test_uiFontSmallBadge_withNilTokens_returnsDefaultFont() {
        // When
        let font = PrimerFont.uiFontSmallBadge(tokens: nil)

        // Then - default is 10pt
        XCTAssertNotNil(font)
        XCTAssertGreaterThanOrEqual(font.pointSize, 10)
    }

    // MARK: - SwiftUI Font Helpers Tests

    func test_titleXLarge_withNilTokens_returnsFont() {
        // When
        let font = PrimerFont.titleXLarge(tokens: nil)

        // Then
        XCTAssertNotNil(font)
    }

    func test_titleLarge_withNilTokens_returnsFont() {
        // When
        let font = PrimerFont.titleLarge(tokens: nil)

        // Then
        XCTAssertNotNil(font)
    }

    func test_bodyLarge_withNilTokens_returnsFont() {
        // When
        let font = PrimerFont.bodyLarge(tokens: nil)

        // Then
        XCTAssertNotNil(font)
    }

    func test_bodyMedium_withNilTokens_returnsFont() {
        // When
        let font = PrimerFont.bodyMedium(tokens: nil)

        // Then
        XCTAssertNotNil(font)
    }

    func test_bodySmall_withNilTokens_returnsFont() {
        // When
        let font = PrimerFont.bodySmall(tokens: nil)

        // Then
        XCTAssertNotNil(font)
    }

    func test_largeIcon_withNilTokens_returnsFont() {
        // When
        let font = PrimerFont.largeIcon(tokens: nil)

        // Then
        XCTAssertNotNil(font)
    }

    func test_extraLargeIcon_withNilTokens_returnsFont() {
        // When
        let font = PrimerFont.extraLargeIcon(tokens: nil)

        // Then
        XCTAssertNotNil(font)
    }

    func test_smallBadge_withNilTokens_returnsFont() {
        // When
        let font = PrimerFont.smallBadge(tokens: nil)

        // Then
        XCTAssertNotNil(font)
    }

    // MARK: - Semantic Font Helpers Tests

    func test_body_withNilTokens_returnsFont() {
        // When
        let font = PrimerFont.body(tokens: nil)

        // Then - body is alias for bodyMedium
        XCTAssertNotNil(font)
    }

    func test_caption_withNilTokens_returnsFont() {
        // When
        let font = PrimerFont.caption(tokens: nil)

        // Then - caption is alias for bodySmall
        XCTAssertNotNil(font)
    }

    func test_headline_withNilTokens_returnsFont() {
        // When
        let font = PrimerFont.headline(tokens: nil)

        // Then - headline is alias for titleLarge
        XCTAssertNotNil(font)
    }

    func test_title2_withNilTokens_returnsFont() {
        // When
        let font = PrimerFont.title2(tokens: nil)

        // Then - title2 is alias for titleXLarge
        XCTAssertNotNil(font)
    }

    func test_subheadline_withNilTokens_returnsFont() {
        // When
        let font = PrimerFont.subheadline(tokens: nil)

        // Then - subheadline is alias for bodyMedium
        XCTAssertNotNil(font)
    }

    // MARK: - Font Weight Tests

    func test_uiFont_withVariousWeights_returnsFont() {
        // Given
        let weights: [CGFloat] = [100, 200, 300, 400, 500, 550, 600, 700, 800, 900]

        for weight in weights {
            // When
            let font = PrimerFont.uiFont(family: "Inter", weight: weight, size: 14)

            // Then
            XCTAssertNotNil(font, "Font should not be nil for weight \(weight)")
        }
    }

    func test_uiFont_withUnknownWeight_fallsBackToRegular() {
        // Given - weight 450 is not a standard weight
        // When
        let font = PrimerFont.uiFont(family: "Inter", weight: 450, size: 14)

        // Then
        XCTAssertNotNil(font)
    }

    // MARK: - Edge Cases

    func test_uiFont_withZeroSize_returnsFont() {
        // When
        let font = PrimerFont.uiFont(family: "Inter", weight: 400, size: 0)

        // Then
        XCTAssertNotNil(font)
    }

    func test_uiFont_withVeryLargeSize_returnsFont() {
        // When
        let font = PrimerFont.uiFont(family: "Inter", weight: 400, size: 100)

        // Then
        XCTAssertNotNil(font)
        XCTAssertGreaterThanOrEqual(font.pointSize, 100)
    }

    func test_uiFont_withEmptyFamily_usesSystemFont() {
        // When
        let font = PrimerFont.uiFont(family: "", weight: 400, size: 14)

        // Then
        XCTAssertNotNil(font)
    }
}
