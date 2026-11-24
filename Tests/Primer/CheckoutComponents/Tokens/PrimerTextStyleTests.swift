//
//  PrimerTextStyleTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import UIKit
import XCTest

@available(iOS 15.0, *)
@MainActor
final class PrimerTextStyleTests: XCTestCase {

    /// Ships several weights on every iOS version, so a weight trait resolves visibly different faces.
    private let brandFamily = "Helvetica Neue"

    override func setUp() {
        super.setUp()
        FontRegistration.registerFonts()
    }

    // MARK: - Line Height

    func test_lineHeight_readsTheToken() async throws {
        // Given
        let tokens = try await loadTokens()

        // Then
        XCTAssertEqual(
            PrimerTextStyle.bodyMedium.lineHeight(tokens: tokens),
            UIFontMetrics.default.scaledValue(for: 20)
        )
        XCTAssertEqual(
            PrimerTextStyle.titleXLarge.lineHeight(tokens: tokens),
            UIFontMetrics.default.scaledValue(for: 32)
        )
    }

    func test_lineHeight_followsAMerchantOverride() async throws {
        // Given
        let tokens = try await loadTokens(
            typography: TypographyOverrides(bodyMedium: .init(lineHeight: 30))
        )

        // Then
        XCTAssertEqual(
            PrimerTextStyle.bodyMedium.lineHeight(tokens: tokens),
            UIFontMetrics.default.scaledValue(for: 30)
        )
    }

    func test_lineHeight_isNilWithoutTokens() {
        XCTAssertNil(PrimerTextStyle.bodyMedium.lineHeight(tokens: nil))
    }

    // MARK: - Letter Spacing

    func test_letterSpacing_readsTheToken() async throws {
        // Given
        let tokens = try await loadTokens()

        // Then
        XCTAssertEqual(
            PrimerTextStyle.titleXLarge.letterSpacing(tokens: tokens),
            UIFontMetrics.default.scaledValue(for: -0.6)
        )
        XCTAssertEqual(PrimerTextStyle.bodyMedium.letterSpacing(tokens: tokens), 0)
    }

    func test_letterSpacing_followsAMerchantOverride() async throws {
        // Given
        let tokens = try await loadTokens(
            typography: TypographyOverrides(bodyMedium: .init(letterSpacing: 1.5))
        )

        // Then
        XCTAssertEqual(
            PrimerTextStyle.bodyMedium.letterSpacing(tokens: tokens),
            UIFontMetrics.default.scaledValue(for: 1.5)
        )
    }

    // MARK: - Semantic Aliases

    func test_semanticAliases_mapOntoTheThemedStyles() {
        XCTAssertEqual(PrimerTextStyle.body, .bodyMedium)
        XCTAssertEqual(PrimerTextStyle.subheadline, .bodyMedium)
        XCTAssertEqual(PrimerTextStyle.caption, .bodySmall)
        XCTAssertEqual(PrimerTextStyle.headline, .titleLarge)
        XCTAssertEqual(PrimerTextStyle.title2, .titleXLarge)
    }

    // MARK: - Styles Built Without Tokens

    func test_smallBadge_followsTheBodySmallWeight() async throws {
        // Given a merchant asking for bold body-small text
        let tokens = try await loadTokens(
            typography: TypographyOverrides(brand: brandFamily, bodySmall: .init(weight: .bold))
        )

        // When
        let badge = PrimerFont.uiFontSmallBadge(tokens: tokens)

        // Then the badge resolves the same face as body small, at its own fixed size
        XCTAssertEqual(badge.fontName, PrimerFont.uiFontBodySmall(tokens: tokens).fontName)
        XCTAssertEqual(badge.familyName, brandFamily)
    }

    func test_iconStyles_followTheBrandFont() async throws {
        // Given
        let tokens = try await loadTokens(typography: TypographyOverrides(brand: brandFamily))

        // Then
        XCTAssertEqual(PrimerFont.uiFontLargeIcon(tokens: tokens).familyName, brandFamily)
        XCTAssertEqual(PrimerFont.uiFontExtraLargeIcon(tokens: tokens).familyName, brandFamily)
    }

    // MARK: - Helpers

    private func loadTokens(typography: TypographyOverrides? = nil) async throws -> DesignTokens {
        let manager = DesignTokensManager()
        if let typography {
            manager.applyTheme(PrimerCheckoutTheme(typography: typography))
        }
        try await manager.fetchTokens(for: .light)
        return try XCTUnwrap(manager.tokens)
    }
}
