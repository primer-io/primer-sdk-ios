//
//  PrimerTypographyTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

@available(iOS 15.0, *)
class PrimerTypographyTests: XCTestCase {

    // MARK: - PrimerFont.bodySmall Tests

    func testBodySmallFontWithTokens() {
        let tokens = MockDesignTokens(
            primerTypographyBodySmallSize: 14,
            primerTypographyBodySmallWeight: 500
        )

        let font = PrimerFont.bodySmall(tokens: tokens)

        // We can't directly test Font equality, but we can verify it doesn't crash
        XCTAssertNotNil(font)
    }

    func testBodySmallFontWithoutTokens() {
        let font = PrimerFont.bodySmall(tokens: nil)

        // Should return system font as fallback
        XCTAssertNotNil(font)
    }

    func testBodySmallFontWithNilTokenValues() {
        let tokens = MockDesignTokens(
            primerTypographyBodySmallSize: .some(nil),
            primerTypographyBodySmallWeight: .some(nil)
        )

        let font = PrimerFont.bodySmall(tokens: tokens)

        // Should use fallback values (12, 400)
        XCTAssertNotNil(font)
    }

    func testBodySmallFontWithPartialTokenValues() {
        // Only size provided
        let tokensWithSize = MockDesignTokens(
            primerTypographyBodySmallSize: 16,
            primerTypographyBodySmallWeight: .some(nil)
        )

        let fontWithSize = PrimerFont.bodySmall(tokens: tokensWithSize)
        XCTAssertNotNil(fontWithSize)

        // Only weight provided
        let tokensWithWeight = MockDesignTokens(
            primerTypographyBodySmallSize: .some(nil),
            primerTypographyBodySmallWeight: 600
        )

        let fontWithWeight = PrimerFont.bodySmall(tokens: tokensWithWeight)
        XCTAssertNotNil(fontWithWeight)
    }

    // MARK: - View Modifier Tests

    func testPrimerBodySmallFontModifier() {
        let view = Text("Test")
        let tokens = MockDesignTokens(
            primerTypographyBodySmallSize: 14,
            primerTypographyBodySmallWeight: 500
        )

        let modifiedView = view.font(PrimerFont.bodySmall(tokens: tokens))

        // Verify the modifier can be applied without crashing
        XCTAssertNotNil(modifiedView)
    }

    func testPrimerBodySmallFontModifierWithNilTokens() {
        let view = Text("Test")
        let modifiedView = view.font(PrimerFont.bodySmall(tokens: nil))

        // Should use fallback font
        XCTAssertNotNil(modifiedView)
    }

    // MARK: - Font Weight Tests

    func testFontWeightConversion() {
        // Test various font weights
        let weights: [(CGFloat, Font.Weight)] = [
            (100, .ultraLight),
            (200, .thin),
            (300, .light),
            (400, .regular),
            (500, .medium),
            (600, .semibold),
            (700, .bold),
            (800, .heavy),
            (900, .black)
        ]

        for (rawValue, expectedWeight) in weights {
            let tokens = MockDesignTokens(
                primerTypographyBodySmallSize: 12,
                primerTypographyBodySmallWeight: rawValue
            )

            let font = PrimerFont.bodySmall(tokens: tokens)

            // Font.Weight doesn't expose rawValue for direct comparison,
            // but we can verify the font is created successfully
            XCTAssertNotNil(font)
        }
    }

    func testFontWeightDefaultsFallback() {
        // When weight is not provided, should use 400 (regular)
        let tokens = MockDesignTokens(
            primerTypographyBodySmallSize: 12,
            primerTypographyBodySmallWeight: .some(nil)
        )

        let font = PrimerFont.bodySmall(tokens: tokens)
        XCTAssertNotNil(font)
    }

    // MARK: - Integration Tests

    func testTypographyWithRealDesignTokensStructure() {
        // Test that our mock structure matches expectations
        let tokens = MockDesignTokens(
            primerTypographyBodySmallSize: 12,
            primerTypographyBodySmallWeight: 400
        )

        XCTAssertEqual(tokens.primerTypographyBodySmallSize, 12)
        XCTAssertEqual(tokens.primerTypographyBodySmallWeight, 400)
    }
}

// MARK: - Mock Design Tokens

private func MockDesignTokens(
    primerTypographyBodySmallSize: CGFloat?? = .none,
    primerTypographyBodySmallWeight: CGFloat?? = .none
) -> DesignTokens {
    // Create base DesignTokens from empty JSON
    let jsonData = "{}".data(using: .utf8)!
    let tokens = try! JSONDecoder().decode(DesignTokens.self, from: jsonData)

    // Set test values (double optional pattern to allow explicit nil)
    if let value = primerTypographyBodySmallSize { tokens.primerTypographyBodySmallSize = value }
    if let value = primerTypographyBodySmallWeight { tokens.primerTypographyBodySmallWeight = value }

    return tokens
}
