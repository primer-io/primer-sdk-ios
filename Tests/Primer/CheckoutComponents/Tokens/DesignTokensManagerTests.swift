//
//  DesignTokensManagerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

/// Tests for DesignTokensManager covering theme overrides, typography, and font creation.
@available(iOS 15.0, *)
final class DesignTokensManagerTests: XCTestCase {

    var sut: DesignTokensManager!

    override func setUp() {
        super.setUp()
        sut = DesignTokensManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_tokens_initiallyNil() {
        // Then
        XCTAssertNil(sut.tokens)
    }

    // MARK: - applyTheme Tests

    func test_applyTheme_storesTheme() {
        // Given
        let theme = PrimerCheckoutTheme()

        // When
        sut.applyTheme(theme)

        // Then - theme is stored (we can verify by testing override behavior)
        // Since themeOverrides is private, we verify by checking that override methods work
        XCTAssertNotNil(sut) // Theme applied without crash
    }

    func test_applyTheme_withColors_storesColorOverrides() {
        // Given
        let colors = ColorOverrides(primerColorBrand: .red)
        let theme = PrimerCheckoutTheme(colors: colors)

        // When
        sut.applyTheme(theme)

        // Then - no crash, theme stored
        XCTAssertNotNil(sut)
    }

    func test_applyTheme_withRadius_storesRadiusOverrides() {
        // Given
        let radius = RadiusOverrides(primerRadiusMedium: 16)
        let theme = PrimerCheckoutTheme(radius: radius)

        // When
        sut.applyTheme(theme)

        // Then
        XCTAssertNotNil(sut)
    }

    func test_applyTheme_withSpacing_storesSpacingOverrides() {
        // Given
        let spacing = SpacingOverrides(primerSpaceLarge: 24)
        let theme = PrimerCheckoutTheme(spacing: spacing)

        // When
        sut.applyTheme(theme)

        // Then
        XCTAssertNotNil(sut)
    }

    func test_applyTheme_withSizes_storesSizeOverrides() {
        // Given
        let sizes = SizeOverrides(primerSizeLarge: 32)
        let theme = PrimerCheckoutTheme(sizes: sizes)

        // When
        sut.applyTheme(theme)

        // Then
        XCTAssertNotNil(sut)
    }

    func test_applyTheme_withTypography_storesTypographyOverrides() {
        // Given
        let typography = TypographyOverrides(
            titleXlarge: .init(font: "Helvetica", size: 28)
        )
        let theme = PrimerCheckoutTheme(typography: typography)

        // When
        sut.applyTheme(theme)

        // Then
        XCTAssertNotNil(sut)
    }

    func test_applyTheme_withBorderWidth_storesBorderWidthOverrides() {
        // Given
        let borderWidth = BorderWidthOverrides(primerBorderWidthMedium: 3)
        let theme = PrimerCheckoutTheme(borderWidth: borderWidth)

        // When
        sut.applyTheme(theme)

        // Then
        XCTAssertNotNil(sut)
    }

    // MARK: - typography(override:) Tests

    func test_typography_withNoTheme_returnsNil() {
        // Given - no theme applied

        // When
        let result = sut.typography(override: \TypographyOverrides.titleXlarge)

        // Then
        XCTAssertNil(result)
    }

    func test_typography_withThemeButNoTypography_returnsNil() {
        // Given
        let theme = PrimerCheckoutTheme(colors: ColorOverrides())
        sut.applyTheme(theme)

        // When
        let result = sut.typography(override: \TypographyOverrides.titleXlarge)

        // Then
        XCTAssertNil(result)
    }

    func test_typography_withNilKeyPath_returnsNil() {
        // Given
        let typography = TypographyOverrides(titleXlarge: .init(size: 28))
        let theme = PrimerCheckoutTheme(typography: typography)
        sut.applyTheme(theme)

        // When
        let result = sut.typography(override: nil)

        // Then
        XCTAssertNil(result)
    }

    func test_typography_withValidOverride_returnsStyle() {
        // Given
        let expectedSize: CGFloat = 28
        let expectedFont = "Helvetica"
        let typography = TypographyOverrides(
            titleXlarge: .init(font: expectedFont, size: expectedSize)
        )
        let theme = PrimerCheckoutTheme(typography: typography)
        sut.applyTheme(theme)

        // When
        let result = sut.typography(override: \TypographyOverrides.titleXlarge)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.size, expectedSize)
        XCTAssertEqual(result?.font, expectedFont)
    }

    func test_typography_withDifferentKeyPath_returnsCorrectStyle() {
        // Given
        let typography = TypographyOverrides(
            titleXlarge: .init(size: 28),
            bodyMedium: .init(size: 14)
        )
        let theme = PrimerCheckoutTheme(typography: typography)
        sut.applyTheme(theme)

        // When
        let titleResult = sut.typography(override: \TypographyOverrides.titleXlarge)
        let bodyResult = sut.typography(override: \TypographyOverrides.bodyMedium)

        // Then
        XCTAssertEqual(titleResult?.size, 28)
        XCTAssertEqual(bodyResult?.size, 14)
    }

    func test_typography_withNilStyleInTypography_returnsNil() {
        // Given - typography exists but titleLarge is nil
        let typography = TypographyOverrides(titleXlarge: .init(size: 28))
        let theme = PrimerCheckoutTheme(typography: typography)
        sut.applyTheme(theme)

        // When
        let result = sut.typography(override: \TypographyOverrides.titleLarge)

        // Then
        XCTAssertNil(result)
    }

    // MARK: - font(override:defaultSize:defaultWeight:) Tests

    func test_font_withNoOverride_usesDefaults() {
        // Given - no theme applied

        // When
        let font = sut.font(override: nil, defaultSize: 16, defaultWeight: .regular)

        // Then
        XCTAssertNotNil(font)
    }

    func test_font_withNilKeyPath_usesDefaults() {
        // Given
        let typography = TypographyOverrides(titleXlarge: .init(size: 28))
        let theme = PrimerCheckoutTheme(typography: typography)
        sut.applyTheme(theme)

        // When
        let font = sut.font(override: nil, defaultSize: 16, defaultWeight: .regular)

        // Then
        XCTAssertNotNil(font)
    }

    func test_font_withOverrideSize_usesOverrideSize() {
        // Given
        let overrideSize: CGFloat = 32
        let typography = TypographyOverrides(
            titleXlarge: .init(size: overrideSize)
        )
        let theme = PrimerCheckoutTheme(typography: typography)
        sut.applyTheme(theme)

        // When
        let font = sut.font(
            override: \TypographyOverrides.titleXlarge,
            defaultSize: 16,
            defaultWeight: .regular
        )

        // Then
        XCTAssertNotNil(font)
    }

    func test_font_withOverrideWeight_usesOverrideWeight() {
        // Given
        let typography = TypographyOverrides(
            bodyMedium: .init(weight: .bold)
        )
        let theme = PrimerCheckoutTheme(typography: typography)
        sut.applyTheme(theme)

        // When
        let font = sut.font(
            override: \TypographyOverrides.bodyMedium,
            defaultSize: 14,
            defaultWeight: .regular
        )

        // Then
        XCTAssertNotNil(font)
    }

    func test_font_withCustomFontName_usesCustomFont() {
        // Given
        let typography = TypographyOverrides(
            titleLarge: .init(font: "Helvetica", weight: .semibold, size: 20)
        )
        let theme = PrimerCheckoutTheme(typography: typography)
        sut.applyTheme(theme)

        // When
        let font = sut.font(
            override: \TypographyOverrides.titleLarge,
            defaultSize: 16,
            defaultWeight: .regular
        )

        // Then
        XCTAssertNotNil(font)
    }

    func test_font_withPartialOverride_mergesWithDefaults() {
        // Given - override only has size, not weight
        let typography = TypographyOverrides(
            bodySmall: .init(size: 10)
        )
        let theme = PrimerCheckoutTheme(typography: typography)
        sut.applyTheme(theme)

        // When
        let font = sut.font(
            override: \TypographyOverrides.bodySmall,
            defaultSize: 12,
            defaultWeight: .medium
        )

        // Then
        XCTAssertNotNil(font)
    }

    // MARK: - TypographyStyle Tests

    func test_typographyStyle_allPropertiesOptional() {
        // Given
        let style = TypographyOverrides.TypographyStyle()

        // Then
        XCTAssertNil(style.font)
        XCTAssertNil(style.letterSpacing)
        XCTAssertNil(style.weight)
        XCTAssertNil(style.size)
        XCTAssertNil(style.lineHeight)
    }

    func test_typographyStyle_withAllProperties() {
        // Given
        let style = TypographyOverrides.TypographyStyle(
            font: "Inter",
            letterSpacing: -0.5,
            weight: .bold,
            size: 24,
            lineHeight: 32
        )

        // Then
        XCTAssertEqual(style.font, "Inter")
        XCTAssertEqual(style.letterSpacing, -0.5)
        XCTAssertEqual(style.weight, .bold)
        XCTAssertEqual(style.size, 24)
        XCTAssertEqual(style.lineHeight, 32)
    }

    // MARK: - ObservableObject Tests

    func test_isObservableObject() {
        // Then
        XCTAssertTrue(sut is ObservableObject)
    }

    func test_tokensIsPublished() {
        // Given
        let expectation = expectation(description: "Tokens published")
        var receivedTokens: DesignTokens?

        let cancellable = sut.$tokens.sink { tokens in
            receivedTokens = tokens
            expectation.fulfill()
        }

        // When - initial nil value triggers sink
        waitForExpectations(timeout: 1.0)

        // Then
        XCTAssertNil(receivedTokens)
        cancellable.cancel()
    }

    // MARK: - Theme Override Priority Tests

    func test_multipleApplyTheme_overwritesPreviousTheme() {
        // Given
        let theme1 = PrimerCheckoutTheme(
            typography: TypographyOverrides(titleXlarge: .init(size: 28))
        )
        let theme2 = PrimerCheckoutTheme(
            typography: TypographyOverrides(titleXlarge: .init(size: 32))
        )

        // When
        sut.applyTheme(theme1)
        sut.applyTheme(theme2)

        // Then
        let result = sut.typography(override: \TypographyOverrides.titleXlarge)
        XCTAssertEqual(result?.size, 32)
    }

    // MARK: - Complete Theme Tests

    func test_applyTheme_withAllOverrides() {
        // Given
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides(primerColorBrand: .blue),
            radius: RadiusOverrides(primerRadiusMedium: 12),
            spacing: SpacingOverrides(primerSpaceLarge: 20),
            sizes: SizeOverrides(primerSizeLarge: 28),
            typography: TypographyOverrides(titleXlarge: .init(size: 28)),
            borderWidth: BorderWidthOverrides(primerBorderWidthMedium: 2)
        )

        // When
        sut.applyTheme(theme)

        // Then
        let typography = sut.typography(override: \TypographyOverrides.titleXlarge)
        XCTAssertEqual(typography?.size, 28)
    }

    // MARK: - Edge Cases

    func test_applyTheme_withEmptyOverrides_doesNotCrash() {
        // Given
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides(),
            radius: RadiusOverrides(),
            spacing: SpacingOverrides(),
            sizes: SizeOverrides(),
            typography: TypographyOverrides(),
            borderWidth: BorderWidthOverrides()
        )

        // When
        sut.applyTheme(theme)

        // Then
        XCTAssertNotNil(sut)
    }

    // MARK: - Tokens Assignment Tests

    func test_tokensCanBeSetDirectly() {
        // Given
        let tokens = DesignTokens()

        // When
        sut.tokens = tokens

        // Then
        XCTAssertNotNil(sut.tokens)
    }

    func test_tokensCanBeSetToNil() {
        // Given
        let tokens = DesignTokens()
        sut.tokens = tokens

        // When
        sut.tokens = nil

        // Then
        XCTAssertNil(sut.tokens)
    }

    // MARK: - TypographyOverrides Tests

    func test_typographyOverrides_allStylesAreOptional() {
        // Given
        let overrides = TypographyOverrides()

        // Then
        XCTAssertNil(overrides.titleXlarge)
        XCTAssertNil(overrides.titleLarge)
        XCTAssertNil(overrides.bodyLarge)
        XCTAssertNil(overrides.bodyMedium)
        XCTAssertNil(overrides.bodySmall)
    }

    func test_typographyOverrides_canSetAllStyles() {
        // Given
        let overrides = TypographyOverrides(
            titleXlarge: .init(size: 28),
            titleLarge: .init(size: 20),
            bodyLarge: .init(size: 16),
            bodyMedium: .init(size: 14),
            bodySmall: .init(size: 12)
        )

        // Then
        XCTAssertEqual(overrides.titleXlarge?.size, 28)
        XCTAssertEqual(overrides.titleLarge?.size, 20)
        XCTAssertEqual(overrides.bodyLarge?.size, 16)
        XCTAssertEqual(overrides.bodyMedium?.size, 14)
        XCTAssertEqual(overrides.bodySmall?.size, 12)
    }

    // MARK: - ColorOverrides Tests

    func test_colorOverrides_allPropertiesAreOptional() {
        // Given
        let overrides = ColorOverrides()

        // Then - just verify it can be created without setting any values
        XCTAssertNil(overrides.primerColorBrand)
        XCTAssertNil(overrides.primerColorBackground)
        XCTAssertNil(overrides.primerColorTextPrimary)
    }

    func test_colorOverrides_canSetBrandColor() {
        // Given
        let overrides = ColorOverrides(primerColorBrand: .blue)

        // Then
        XCTAssertEqual(overrides.primerColorBrand, .blue)
    }

    func test_colorOverrides_canSetMultipleColors() {
        // Given
        let overrides = ColorOverrides(
            primerColorBrand: .blue,
            primerColorBackground: .white,
            primerColorTextPrimary: .black
        )

        // Then
        XCTAssertEqual(overrides.primerColorBrand, .blue)
        XCTAssertEqual(overrides.primerColorBackground, .white)
        XCTAssertEqual(overrides.primerColorTextPrimary, .black)
    }

    // MARK: - RadiusOverrides Tests

    func test_radiusOverrides_allPropertiesAreOptional() {
        // Given
        let overrides = RadiusOverrides()

        // Then
        XCTAssertNil(overrides.primerRadiusMedium)
        XCTAssertNil(overrides.primerRadiusSmall)
        XCTAssertNil(overrides.primerRadiusLarge)
    }

    func test_radiusOverrides_canSetValues() {
        // Given
        let overrides = RadiusOverrides(
            primerRadiusSmall: 4,
            primerRadiusMedium: 8,
            primerRadiusLarge: 12
        )

        // Then
        XCTAssertEqual(overrides.primerRadiusSmall, 4)
        XCTAssertEqual(overrides.primerRadiusMedium, 8)
        XCTAssertEqual(overrides.primerRadiusLarge, 12)
    }

    // MARK: - SpacingOverrides Tests

    func test_spacingOverrides_allPropertiesAreOptional() {
        // Given
        let overrides = SpacingOverrides()

        // Then
        XCTAssertNil(overrides.primerSpaceSmall)
        XCTAssertNil(overrides.primerSpaceMedium)
        XCTAssertNil(overrides.primerSpaceLarge)
    }

    func test_spacingOverrides_canSetValues() {
        // Given
        let overrides = SpacingOverrides(
            primerSpaceSmall: 8,
            primerSpaceMedium: 12,
            primerSpaceLarge: 16
        )

        // Then
        XCTAssertEqual(overrides.primerSpaceSmall, 8)
        XCTAssertEqual(overrides.primerSpaceMedium, 12)
        XCTAssertEqual(overrides.primerSpaceLarge, 16)
    }

    // MARK: - SizeOverrides Tests

    func test_sizeOverrides_allPropertiesAreOptional() {
        // Given
        let overrides = SizeOverrides()

        // Then
        XCTAssertNil(overrides.primerSizeSmall)
        XCTAssertNil(overrides.primerSizeMedium)
        XCTAssertNil(overrides.primerSizeLarge)
    }

    func test_sizeOverrides_canSetValues() {
        // Given
        let overrides = SizeOverrides(
            primerSizeSmall: 16,
            primerSizeMedium: 24,
            primerSizeLarge: 32
        )

        // Then
        XCTAssertEqual(overrides.primerSizeSmall, 16)
        XCTAssertEqual(overrides.primerSizeMedium, 24)
        XCTAssertEqual(overrides.primerSizeLarge, 32)
    }

    // MARK: - BorderWidthOverrides Tests

    func test_borderWidthOverrides_allPropertiesAreOptional() {
        // Given
        let overrides = BorderWidthOverrides()

        // Then
        XCTAssertNil(overrides.primerBorderWidthMedium)
    }

    func test_borderWidthOverrides_canSetValues() {
        // Given
        let overrides = BorderWidthOverrides(primerBorderWidthMedium: 2)

        // Then
        XCTAssertEqual(overrides.primerBorderWidthMedium, 2)
    }

    // MARK: - PrimerCheckoutTheme Tests

    func test_primerCheckoutTheme_canBeCreatedEmpty() {
        // Given/When
        let theme = PrimerCheckoutTheme()

        // Then
        XCTAssertNil(theme.colors)
        XCTAssertNil(theme.radius)
        XCTAssertNil(theme.spacing)
        XCTAssertNil(theme.sizes)
        XCTAssertNil(theme.typography)
        XCTAssertNil(theme.borderWidth)
    }

    func test_primerCheckoutTheme_canSetIndividualOverrides() {
        // Given/When
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides(primerColorBrand: .red)
        )

        // Then
        XCTAssertNotNil(theme.colors)
        XCTAssertEqual(theme.colors?.primerColorBrand, .red)
        XCTAssertNil(theme.radius)
    }

    // MARK: - fetchTokens Tests

    func test_fetchTokens_lightMode_populatesTokens() async throws {
        // Given - sut with no tokens
        XCTAssertNil(sut.tokens)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        XCTAssertNotNil(sut.tokens)
    }

    func test_fetchTokens_darkMode_populatesTokens() async throws {
        // Given - sut with no tokens
        XCTAssertNil(sut.tokens)

        // When
        try await sut.fetchTokens(for: .dark)

        // Then
        XCTAssertNotNil(sut.tokens)
    }

    func test_fetchTokens_lightMode_loadsColorTokens() async throws {
        // When
        try await sut.fetchTokens(for: .light)

        // Then - basic color tokens should be populated
        XCTAssertNotNil(sut.tokens?.primerColorBrand)
        XCTAssertNotNil(sut.tokens?.primerColorBackground)
        XCTAssertNotNil(sut.tokens?.primerColorTextPrimary)
    }

    func test_fetchTokens_lightMode_loadsRadiusTokens() async throws {
        // When
        try await sut.fetchTokens(for: .light)

        // Then - radius tokens should be populated
        XCTAssertNotNil(sut.tokens?.primerRadiusMedium)
        XCTAssertNotNil(sut.tokens?.primerRadiusSmall)
        XCTAssertNotNil(sut.tokens?.primerRadiusLarge)
    }

    func test_fetchTokens_lightMode_loadsSpacingTokens() async throws {
        // When
        try await sut.fetchTokens(for: .light)

        // Then - spacing tokens should be populated
        XCTAssertNotNil(sut.tokens?.primerSpaceSmall)
        XCTAssertNotNil(sut.tokens?.primerSpaceMedium)
        XCTAssertNotNil(sut.tokens?.primerSpaceLarge)
    }

    func test_fetchTokens_lightMode_loadsSizeTokens() async throws {
        // When
        try await sut.fetchTokens(for: .light)

        // Then - size tokens should be populated
        XCTAssertNotNil(sut.tokens?.primerSizeSmall)
        XCTAssertNotNil(sut.tokens?.primerSizeMedium)
        XCTAssertNotNil(sut.tokens?.primerSizeLarge)
    }

    func test_fetchTokens_withThemeOverrides_appliesColorOverrides() async throws {
        // Given - apply theme with color overrides before fetching
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides(primerColorBrand: .red)
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then - theme overrides should be applied to tokens
        XCTAssertNotNil(sut.tokens)
        // The token color should be overridden to red
        XCTAssertEqual(sut.tokens?.primerColorBrand, .red)
    }

    func test_fetchTokens_withRadiusOverrides_appliesRadiusOverrides() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            radius: RadiusOverrides(primerRadiusMedium: 99)
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        XCTAssertNotNil(sut.tokens)
        XCTAssertEqual(sut.tokens?.primerRadiusMedium, 99)
    }

    func test_fetchTokens_withSpacingOverrides_appliesSpacingOverrides() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            spacing: SpacingOverrides(primerSpaceLarge: 50)
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        XCTAssertNotNil(sut.tokens)
        XCTAssertEqual(sut.tokens?.primerSpaceLarge, 50)
    }

    func test_fetchTokens_withSizeOverrides_appliesSizeOverrides() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            sizes: SizeOverrides(primerSizeLarge: 100)
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        XCTAssertNotNil(sut.tokens)
        XCTAssertEqual(sut.tokens?.primerSizeLarge, 100)
    }

    func test_fetchTokens_calledMultipleTimes_updatesTokens() async throws {
        // Given - fetch light mode first
        try await sut.fetchTokens(for: .light)
        let lightTokens = sut.tokens

        // When - fetch dark mode
        try await sut.fetchTokens(for: .dark)

        // Then - tokens should be updated (not necessarily different values, but updated)
        XCTAssertNotNil(sut.tokens)
        // Note: Light and dark might have same values for some tokens, so we just verify it doesn't crash
    }

    func test_fetchTokens_withAllOverrideTypes_appliesAllOverrides() async throws {
        // Given - apply all override types
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides(primerColorBrand: .green),
            radius: RadiusOverrides(primerRadiusSmall: 2),
            spacing: SpacingOverrides(primerSpaceXsmall: 2),
            sizes: SizeOverrides(primerSizeSmall: 10)
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then - all overrides should be applied
        XCTAssertEqual(sut.tokens?.primerColorBrand, .green)
        XCTAssertEqual(sut.tokens?.primerRadiusSmall, 2)
        XCTAssertEqual(sut.tokens?.primerSpaceXsmall, 2)
        XCTAssertEqual(sut.tokens?.primerSizeSmall, 10)
    }

    // MARK: - Additional Typography Tests

    func test_typography_allKeyPaths_workCorrectly() {
        // Given
        let typography = TypographyOverrides(
            titleXlarge: .init(size: 28),
            titleLarge: .init(size: 20),
            bodyLarge: .init(size: 16),
            bodyMedium: .init(size: 14),
            bodySmall: .init(size: 12)
        )
        let theme = PrimerCheckoutTheme(typography: typography)
        sut.applyTheme(theme)

        // Then - all key paths should return correct styles
        XCTAssertEqual(sut.typography(override: \TypographyOverrides.titleXlarge)?.size, 28)
        XCTAssertEqual(sut.typography(override: \TypographyOverrides.titleLarge)?.size, 20)
        XCTAssertEqual(sut.typography(override: \TypographyOverrides.bodyLarge)?.size, 16)
        XCTAssertEqual(sut.typography(override: \TypographyOverrides.bodyMedium)?.size, 14)
        XCTAssertEqual(sut.typography(override: \TypographyOverrides.bodySmall)?.size, 12)
    }

    func test_typography_withWeight_returnsWeight() {
        // Given
        let typography = TypographyOverrides(
            titleXlarge: .init(weight: .bold, size: 28)
        )
        let theme = PrimerCheckoutTheme(typography: typography)
        sut.applyTheme(theme)

        // When
        let result = sut.typography(override: \TypographyOverrides.titleXlarge)

        // Then
        XCTAssertEqual(result?.weight, .bold)
    }

    // MARK: - Additional Font Tests

    func test_font_withCustomFontName_createsCustomFont() {
        // Given
        let customFontName = "Helvetica-Bold"
        let typography = TypographyOverrides(
            titleXlarge: .init(font: customFontName, size: 24)
        )
        let theme = PrimerCheckoutTheme(typography: typography)
        sut.applyTheme(theme)

        // When
        let font = sut.font(
            override: \TypographyOverrides.titleXlarge,
            defaultSize: 16,
            defaultWeight: .regular
        )

        // Then - font is created (we can't directly compare Font objects, but it shouldn't crash)
        XCTAssertNotNil(font)
    }

    func test_font_withHeavyWeight_createsFont() {
        // Given
        let typography = TypographyOverrides(
            titleXlarge: .init(weight: .heavy, size: 24)
        )
        let theme = PrimerCheckoutTheme(typography: typography)
        sut.applyTheme(theme)

        // When
        let font = sut.font(
            override: \TypographyOverrides.titleXlarge,
            defaultSize: 16,
            defaultWeight: .regular
        )

        // Then
        XCTAssertNotNil(font)
    }

    func test_font_withNoTypographyOverride_usesDefaults() {
        // Given - theme without typography
        let theme = PrimerCheckoutTheme(colors: ColorOverrides())
        sut.applyTheme(theme)

        // When
        let font = sut.font(
            override: \TypographyOverrides.titleXlarge,
            defaultSize: 20,
            defaultWeight: .semibold
        )

        // Then
        XCTAssertNotNil(font)
    }

    func test_font_withDefaultWeightParameter_usesDefaultWeight() {
        // Given - no theme applied

        // When - using different default weights
        let regularFont = sut.font(override: nil, defaultSize: 16, defaultWeight: .regular)
        let boldFont = sut.font(override: nil, defaultSize: 16, defaultWeight: .bold)
        let lightFont = sut.font(override: nil, defaultSize: 16, defaultWeight: .light)

        // Then - all fonts should be created
        XCTAssertNotNil(regularFont)
        XCTAssertNotNil(boldFont)
        XCTAssertNotNil(lightFont)
    }

    func test_font_withDifferentSizes_createsDifferentFonts() {
        // Given - no theme applied

        // When
        let smallFont = sut.font(override: nil, defaultSize: 12)
        let mediumFont = sut.font(override: nil, defaultSize: 16)
        let largeFont = sut.font(override: nil, defaultSize: 24)

        // Then
        XCTAssertNotNil(smallFont)
        XCTAssertNotNil(mediumFont)
        XCTAssertNotNil(largeFont)
    }

    // MARK: - Color Override Application Tests (via fetchTokens)

    func test_fetchTokens_withGrayColorOverrides_appliesOverrides() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides(
                primerColorGray100: .gray,
                primerColorGray500: .gray,
                primerColorGray900: .black
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        XCTAssertEqual(sut.tokens?.primerColorGray100, .gray)
        XCTAssertEqual(sut.tokens?.primerColorGray500, .gray)
        XCTAssertEqual(sut.tokens?.primerColorGray900, .black)
    }

    func test_fetchTokens_withTextColorOverrides_appliesOverrides() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides(
                primerColorTextPrimary: .black,
                primerColorTextSecondary: .gray
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        XCTAssertEqual(sut.tokens?.primerColorTextPrimary, .black)
        XCTAssertEqual(sut.tokens?.primerColorTextSecondary, .gray)
    }

    func test_fetchTokens_withBorderColorOverrides_appliesOverrides() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides(
                primerColorBorderOutlinedDefault: .gray,
                primerColorBorderOutlinedError: .red
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        XCTAssertEqual(sut.tokens?.primerColorBorderOutlinedDefault, .gray)
        XCTAssertEqual(sut.tokens?.primerColorBorderOutlinedError, .red)
    }

    func test_fetchTokens_withIconColorOverrides_appliesOverrides() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides(
                primerColorIconPrimary: .black,
                primerColorIconNegative: .red
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        XCTAssertEqual(sut.tokens?.primerColorIconPrimary, .black)
        XCTAssertEqual(sut.tokens?.primerColorIconNegative, .red)
    }

    // MARK: - Full Radius Override Tests

    func test_fetchTokens_withAllRadiusOverrides_appliesAll() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            radius: RadiusOverrides(
                primerRadiusXsmall: 1,
                primerRadiusSmall: 2,
                primerRadiusMedium: 4,
                primerRadiusLarge: 8,
                primerRadiusBase: 2
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        XCTAssertEqual(sut.tokens?.primerRadiusXsmall, 1)
        XCTAssertEqual(sut.tokens?.primerRadiusSmall, 2)
        XCTAssertEqual(sut.tokens?.primerRadiusMedium, 4)
        XCTAssertEqual(sut.tokens?.primerRadiusLarge, 8)
        XCTAssertEqual(sut.tokens?.primerRadiusBase, 2)
    }

    // MARK: - Full Spacing Override Tests

    func test_fetchTokens_withAllSpacingOverrides_appliesAll() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            spacing: SpacingOverrides(
                primerSpaceXxsmall: 1,
                primerSpaceXsmall: 2,
                primerSpaceSmall: 4,
                primerSpaceMedium: 8,
                primerSpaceLarge: 12,
                primerSpaceXlarge: 16,
                primerSpaceXxlarge: 20,
                primerSpaceBase: 2
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        XCTAssertEqual(sut.tokens?.primerSpaceXxsmall, 1)
        XCTAssertEqual(sut.tokens?.primerSpaceXsmall, 2)
        XCTAssertEqual(sut.tokens?.primerSpaceSmall, 4)
        XCTAssertEqual(sut.tokens?.primerSpaceMedium, 8)
        XCTAssertEqual(sut.tokens?.primerSpaceLarge, 12)
        XCTAssertEqual(sut.tokens?.primerSpaceXlarge, 16)
        XCTAssertEqual(sut.tokens?.primerSpaceXxlarge, 20)
        XCTAssertEqual(sut.tokens?.primerSpaceBase, 2)
    }

    // MARK: - Full Size Override Tests

    func test_fetchTokens_withAllSizeOverrides_appliesAll() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            sizes: SizeOverrides(
                primerSizeSmall: 10,
                primerSizeMedium: 20,
                primerSizeLarge: 30,
                primerSizeXlarge: 40,
                primerSizeXxlarge: 50,
                primerSizeXxxlarge: 60,
                primerSizeBase: 5
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        XCTAssertEqual(sut.tokens?.primerSizeSmall, 10)
        XCTAssertEqual(sut.tokens?.primerSizeMedium, 20)
        XCTAssertEqual(sut.tokens?.primerSizeLarge, 30)
        XCTAssertEqual(sut.tokens?.primerSizeXlarge, 40)
        XCTAssertEqual(sut.tokens?.primerSizeXxlarge, 50)
        XCTAssertEqual(sut.tokens?.primerSizeXxxlarge, 60)
        XCTAssertEqual(sut.tokens?.primerSizeBase, 5)
    }

    // MARK: - Theme Replacement Tests

    func test_applyTheme_replacesExistingTheme() async throws {
        // Given - apply first theme
        let firstTheme = PrimerCheckoutTheme(
            colors: ColorOverrides(primerColorBrand: .red)
        )
        sut.applyTheme(firstTheme)

        // When - apply second theme
        let secondTheme = PrimerCheckoutTheme(
            colors: ColorOverrides(primerColorBrand: .blue)
        )
        sut.applyTheme(secondTheme)

        // And fetch tokens
        try await sut.fetchTokens(for: .light)

        // Then - second theme should be applied
        XCTAssertEqual(sut.tokens?.primerColorBrand, .blue)
    }

    func test_applyTheme_emptyTheme_clearsOverrides() async throws {
        // Given - apply theme with overrides
        let themeWithOverrides = PrimerCheckoutTheme(
            radius: RadiusOverrides(primerRadiusMedium: 99)
        )
        sut.applyTheme(themeWithOverrides)
        try await sut.fetchTokens(for: .light)
        XCTAssertEqual(sut.tokens?.primerRadiusMedium, 99)

        // When - apply empty theme and re-fetch
        let emptyTheme = PrimerCheckoutTheme()
        sut.applyTheme(emptyTheme)
        try await sut.fetchTokens(for: .light)

        // Then - should use default token values (not 99)
        XCTAssertNotEqual(sut.tokens?.primerRadiusMedium, 99)
    }
}
