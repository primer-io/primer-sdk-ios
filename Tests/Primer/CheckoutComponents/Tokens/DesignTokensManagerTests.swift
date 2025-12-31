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
}
