//
//  PrimerFontTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import UIKit
import XCTest

@available(iOS 15.0, *)
@MainActor
final class PrimerFontTests: XCTestCase {

    /// Ships several weights on every iOS version, so a weight trait resolves visibly different faces.
    private let brandFamily = "Helvetica Neue"

    override func setUp() {
        super.setUp()
        FontRegistration.registerFonts()
    }

    // MARK: - Brand Font Weights

    func test_brandFont_titleAndBodyResolveToDifferentFaces() async throws {
        // Given
        let tokens = try await loadTokens(brand: brandFamily)

        // When
        let title = PrimerFont.uiFontTitleXLarge(tokens: tokens)
        let body = PrimerFont.uiFontBodyMedium(tokens: tokens)

        // Then
        XCTAssertEqual(title.familyName, brandFamily)
        XCTAssertEqual(body.familyName, brandFamily)
        XCTAssertNotEqual(
            title.fontName, body.fontName,
            "weight 550 and weight 400 collapsed onto the same face"
        )
    }

    func test_brandFont_everyTextStyleUsesTheBrandFamily() async throws {
        // Given
        let tokens = try await loadTokens(brand: brandFamily)

        // When
        let fonts = [
            PrimerFont.uiFontTitleXLarge(tokens: tokens),
            PrimerFont.uiFontTitleLarge(tokens: tokens),
            PrimerFont.uiFontBodyLarge(tokens: tokens),
            PrimerFont.uiFontBodyMedium(tokens: tokens),
            PrimerFont.uiFontBodySmall(tokens: tokens),
            PrimerFont.uiFontError(tokens: tokens),
            PrimerFont.uiFontSmallBadge(tokens: tokens)
        ]

        // Then
        for font in fonts {
            XCTAssertEqual(font.familyName, brandFamily)
        }
    }

    func test_brandFont_postScriptFaceName_stillVariesByWeight() async throws {
        // Given a merchant naming a face rather than a family
        let tokens = try await loadTokens(brand: "Georgia-Bold")

        // When
        let title = PrimerFont.uiFontTitleXLarge(tokens: tokens)
        let body = PrimerFont.uiFontBodyMedium(tokens: tokens)

        // Then the face is normalised to its family, so each style keeps its own weight
        XCTAssertEqual(title.familyName, "Georgia")
        XCTAssertEqual(body.familyName, "Georgia")
        XCTAssertNotEqual(title.fontName, body.fontName)
    }

    // MARK: - Default Font

    func test_noBrandFont_everyTextStyleResolvesInter() async throws {
        // Given
        let manager = DesignTokensManager()
        try await manager.fetchTokens(for: .light)
        let tokens = try XCTUnwrap(manager.tokens)

        // When
        let title = PrimerFont.uiFontTitleXLarge(tokens: tokens)
        let body = PrimerFont.uiFontBodyMedium(tokens: tokens)
        let badge = PrimerFont.uiFontSmallBadge(tokens: tokens)

        // Then
        XCTAssertTrue(title.familyName.contains("Inter"), "got \(title.familyName)")
        XCTAssertTrue(body.familyName.contains("Inter"), "got \(body.familyName)")
        XCTAssertTrue(badge.familyName.contains("Inter"), "got \(badge.familyName)")
    }

    // MARK: - Helpers

    private func loadTokens(brand: String) async throws -> DesignTokens {
        let manager = DesignTokensManager()
        manager.applyTheme(PrimerCheckoutTheme(typography: TypographyOverrides(brand: brand)))
        try await manager.fetchTokens(for: .light)
        return try XCTUnwrap(manager.tokens)
    }
}
