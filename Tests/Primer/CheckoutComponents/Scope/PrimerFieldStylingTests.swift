//
//  PrimerFieldStylingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

/// Tests for PrimerFieldStyling struct initialization and helper methods.
@available(iOS 15.0, *)
final class PrimerFieldStylingTests: XCTestCase {

    // MARK: - Initialization Tests

    func test_init_allNil_createsEmptyStyling() {
        // When
        let styling = PrimerFieldStyling()

        // Then
        XCTAssertNil(styling.fontName)
        XCTAssertNil(styling.fontSize)
        XCTAssertNil(styling.fontWeight)
        XCTAssertNil(styling.labelFontName)
        XCTAssertNil(styling.labelFontSize)
        XCTAssertNil(styling.labelFontWeight)
        XCTAssertNil(styling.textColor)
        XCTAssertNil(styling.labelColor)
        XCTAssertNil(styling.backgroundColor)
        XCTAssertNil(styling.borderColor)
        XCTAssertNil(styling.focusedBorderColor)
        XCTAssertNil(styling.errorBorderColor)
        XCTAssertNil(styling.placeholderColor)
        XCTAssertNil(styling.cornerRadius)
        XCTAssertNil(styling.borderWidth)
        XCTAssertNil(styling.padding)
        XCTAssertNil(styling.fieldHeight)
    }

    func test_init_withTypography_setsTypography() {
        // When
        let styling = PrimerFieldStyling(
            fontName: "Helvetica",
            fontSize: 16.0,
            fontWeight: 400
        )

        // Then
        XCTAssertEqual(styling.fontName, "Helvetica")
        XCTAssertEqual(styling.fontSize, 16.0)
        XCTAssertEqual(styling.fontWeight, 400)
    }

    func test_init_withLabelTypography_setsLabelTypography() {
        // When
        let styling = PrimerFieldStyling(
            labelFontName: "Arial",
            labelFontSize: 12.0,
            labelFontWeight: 300
        )

        // Then
        XCTAssertEqual(styling.labelFontName, "Arial")
        XCTAssertEqual(styling.labelFontSize, 12.0)
        XCTAssertEqual(styling.labelFontWeight, 300)
    }

    func test_init_withColors_setsColors() {
        // When
        let styling = PrimerFieldStyling(
            textColor: .black,
            labelColor: .gray,
            backgroundColor: .white,
            borderColor: .gray,
            focusedBorderColor: .blue,
            errorBorderColor: .red,
            placeholderColor: .secondary
        )

        // Then
        XCTAssertNotNil(styling.textColor)
        XCTAssertNotNil(styling.labelColor)
        XCTAssertNotNil(styling.backgroundColor)
        XCTAssertNotNil(styling.borderColor)
        XCTAssertNotNil(styling.focusedBorderColor)
        XCTAssertNotNil(styling.errorBorderColor)
        XCTAssertNotNil(styling.placeholderColor)
    }

    func test_init_withLayout_setsLayout() {
        // When
        let padding = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        let styling = PrimerFieldStyling(
            cornerRadius: 8.0,
            borderWidth: 1.0,
            padding: padding,
            fieldHeight: 48.0
        )

        // Then
        XCTAssertEqual(styling.cornerRadius, 8.0)
        XCTAssertEqual(styling.borderWidth, 1.0)
        XCTAssertEqual(styling.padding, padding)
        XCTAssertEqual(styling.fieldHeight, 48.0)
    }

    func test_init_withAllProperties_setsAllProperties() {
        // Given
        let padding = EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)

        // When
        let styling = PrimerFieldStyling(
            fontName: "SF Pro",
            fontSize: 16.0,
            fontWeight: 500,
            labelFontName: "SF Pro",
            labelFontSize: 12.0,
            labelFontWeight: 400,
            textColor: .primary,
            labelColor: .secondary,
            backgroundColor: .white,
            borderColor: .gray,
            focusedBorderColor: .blue,
            errorBorderColor: .red,
            placeholderColor: .secondary,
            cornerRadius: 12.0,
            borderWidth: 2.0,
            padding: padding,
            fieldHeight: 56.0
        )

        // Then
        XCTAssertEqual(styling.fontName, "SF Pro")
        XCTAssertEqual(styling.fontSize, 16.0)
        XCTAssertEqual(styling.fontWeight, 500)
        XCTAssertEqual(styling.labelFontName, "SF Pro")
        XCTAssertEqual(styling.labelFontSize, 12.0)
        XCTAssertEqual(styling.labelFontWeight, 400)
        XCTAssertNotNil(styling.textColor)
        XCTAssertNotNil(styling.labelColor)
        XCTAssertNotNil(styling.backgroundColor)
        XCTAssertNotNil(styling.borderColor)
        XCTAssertNotNil(styling.focusedBorderColor)
        XCTAssertNotNil(styling.errorBorderColor)
        XCTAssertNotNil(styling.placeholderColor)
        XCTAssertEqual(styling.cornerRadius, 12.0)
        XCTAssertEqual(styling.borderWidth, 2.0)
        XCTAssertEqual(styling.padding, padding)
        XCTAssertEqual(styling.fieldHeight, 56.0)
    }

    // MARK: - resolvedFont Tests

    func test_resolvedFont_withNilFontName_returnsFallbackFont() {
        // Given
        let styling = PrimerFieldStyling()

        // When
        let font = styling.resolvedFont(tokens: nil)

        // Then - Should return a valid Font
        XCTAssertNotNil(font)
    }

    func test_resolvedFont_withCustomFontName_returnsCustomFont() {
        // Given
        let styling = PrimerFieldStyling(
            fontName: "Helvetica",
            fontSize: 18.0,
            fontWeight: 500
        )

        // When
        let font = styling.resolvedFont(tokens: nil)

        // Then - Should return a valid Font
        XCTAssertNotNil(font)
    }

    func test_resolvedFont_withDesignTokens_usesTokens() {
        // Given
        let styling = PrimerFieldStyling()
        let tokens = DesignTokens()

        // When
        let font = styling.resolvedFont(tokens: tokens)

        // Then - Should return a valid Font
        XCTAssertNotNil(font)
    }

    // MARK: - resolvedLabelFont Tests

    func test_resolvedLabelFont_withNilFontName_returnsFallbackFont() {
        // Given
        let styling = PrimerFieldStyling()

        // When
        let font = styling.resolvedLabelFont(tokens: nil)

        // Then - Should return a valid Font
        XCTAssertNotNil(font)
    }

    func test_resolvedLabelFont_withCustomFontName_returnsCustomFont() {
        // Given
        let styling = PrimerFieldStyling(
            labelFontName: "Arial",
            labelFontSize: 14.0,
            labelFontWeight: 400
        )

        // When
        let font = styling.resolvedLabelFont(tokens: nil)

        // Then - Should return a valid Font
        XCTAssertNotNil(font)
    }

    func test_resolvedLabelFont_withDesignTokens_usesTokens() {
        // Given
        let styling = PrimerFieldStyling()
        let tokens = DesignTokens()

        // When
        let font = styling.resolvedLabelFont(tokens: tokens)

        // Then - Should return a valid Font
        XCTAssertNotNil(font)
    }
}
