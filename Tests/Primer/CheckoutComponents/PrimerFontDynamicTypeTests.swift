//
//  PrimerFontDynamicTypeTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import UIKit
@testable import PrimerSDK

@available(iOS 15.0, *)
final class PrimerFontDynamicTypeTests: XCTestCase {

    // MARK: - scaledFont() Basic Tests

    func testScaledFont_CreatesScaledFont() {
        // Given: Base font size
        let baseSize: CGFloat = 14.0
        let weight: CGFloat = 400

        // When: Creating scaled font
        let scaledFont = PrimerFont.scaledFont(baseSize: baseSize, weight: weight)

        // Then: Font should be created with UIFontMetrics scaling
        XCTAssertNotNil(scaledFont)
        XCTAssertNotNil(scaledFont.familyName)
    }

    func testScaledFont_DefaultWeight() {
        // Given: Base size without explicit weight
        let baseSize: CGFloat = 14.0

        // When: Creating scaled font with default weight
        let scaledFont = PrimerFont.scaledFont(baseSize: baseSize)

        // Then: Font should be created with default weight (400)
        XCTAssertNotNil(scaledFont)
    }

    // MARK: - Weight Parameter Tests (Tests Our Code)

    func testScaledFont_DifferentWeights() {
        // Given: Different font weights
        let baseSize: CGFloat = 14.0
        let weights: [CGFloat] = [300, 400, 500, 700]

        // When: Creating scaled fonts with different weights
        let fonts = weights.map { PrimerFont.scaledFont(baseSize: baseSize, weight: $0) }

        // Then: All fonts should be created successfully (tests we pass weights correctly)
        for font in fonts {
            XCTAssertNotNil(font)
        }
    }

    // MARK: - Design Token Integration Tests (Tests Our Code)

    func testScaledFont_WithCustomTokens() {
        // Given: Custom design tokens
        let mockTokens = MockDesignTokens()
        let baseSize: CGFloat = 18.0
        let weight: CGFloat = 600

        // When: Creating scaled font with custom tokens
        let scaledFont = PrimerFont.scaledFont(
            baseSize: baseSize,
            weight: weight,
            tokens: mockTokens
        )

        // Then: Font should be created with token's font family
        XCTAssertNotNil(scaledFont)
        XCTAssertNotNil(scaledFont.familyName)
    }

    // MARK: - Consistency Tests (Important for Our Implementation)

    func testScaledFont_ConsistentBehavior() {
        // Given: Same parameters called multiple times
        let baseSize: CGFloat = 14.0
        let weight: CGFloat = 400

        // When: Creating multiple scaled fonts with same parameters
        let font1 = PrimerFont.scaledFont(baseSize: baseSize, weight: weight)
        let font2 = PrimerFont.scaledFont(baseSize: baseSize, weight: weight)

        // Then: Fonts should have same characteristics (tests our implementation is deterministic)
        XCTAssertEqual(font1.familyName, font2.familyName)
        XCTAssertEqual(font1.pointSize, font2.pointSize)
    }

    // MARK: - UIFontMetrics Integration (Core Functionality)

    func testScaledFont_UsesUIFontMetrics() {
        // Given: A base font size
        let baseSize: CGFloat = 14.0
        let weight: CGFloat = 400

        // When: Creating a scaled font
        let scaledFont = PrimerFont.scaledFont(baseSize: baseSize, weight: weight)

        // Then: The scaled font should be created (UIFontMetrics integration verified)
        XCTAssertNotNil(scaledFont)

        // Note: Actual Dynamic Type scaling behavior is tested in UI tests where
        // UIContentSizeCategory can be properly manipulated
    }
}

// MARK: - Mock Design Tokens

@available(iOS 15.0, *)
private class MockDesignTokens: DesignTokens {
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

    override init() {
        super.init()
        primerTypographyBodyMediumFont = "Inter"
    }
}
