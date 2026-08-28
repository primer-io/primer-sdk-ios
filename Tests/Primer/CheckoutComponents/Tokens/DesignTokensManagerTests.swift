//
//  DesignTokensManagerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
@MainActor
final class DesignTokensManagerTests: XCTestCase {

    private var sut: DesignTokensManager!

    override func setUp() {
        super.setUp()
        sut = DesignTokensManager()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func test_init_tokensAreNil() {
        XCTAssertNil(sut.tokens)
    }

    // MARK: - fetchTokens (Light Mode)

    func test_fetchTokens_lightMode_loadsTokensSuccessfully() async throws {
        // When
        try await sut.fetchTokens(for: .light)

        // Then
        XCTAssertNotNil(sut.tokens)
    }

    func test_fetchTokens_lightMode_populatesAllTokenCategories() async throws {
        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertNotNil(tokens.primerColorBackgroundPrimary)
        XCTAssertNotNil(tokens.primerColorTextPrimary)
        XCTAssertNotNil(tokens.primerRadiusMedium)
        XCTAssertNotNil(tokens.primerSpaceMedium)
        XCTAssertNotNil(tokens.primerSizeMedium)
        XCTAssertNotNil(tokens.primerTypographyBodyMediumFont)
        XCTAssertNotNil(tokens.primerColorBorderOutlinedDefault)
        XCTAssertNotNil(tokens.primerColorBorderTransparentDefault)
        XCTAssertNotNil(tokens.primerColorIconPrimary)
        XCTAssertNotNil(tokens.primerColorGray000)
        XCTAssertNotNil(tokens.primerColorBlue500)
    }

    // MARK: - fetchTokens (Dark Mode)

    func test_fetchTokens_darkMode_loadsTokensSuccessfully() async throws {
        // When
        try await sut.fetchTokens(for: .dark)

        // Then
        XCTAssertNotNil(sut.tokens)
    }

    func test_fetchTokens_darkMode_populatesAllTokenCategories() async throws {
        // When
        try await sut.fetchTokens(for: .dark)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertNotNil(tokens.primerColorBackgroundPrimary)
        XCTAssertNotNil(tokens.primerColorTextPrimary)
        XCTAssertNotNil(tokens.primerRadiusMedium)
        XCTAssertNotNil(tokens.primerSpaceMedium)
        XCTAssertNotNil(tokens.primerSizeMedium)
        XCTAssertNotNil(tokens.primerTypographyBodyMediumFont)
    }

    // MARK: - applyTheme

    func test_applyTheme_noOverrides_tokensUnchanged() async throws {
        // Given
        let theme = PrimerCheckoutTheme()
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertNotNil(tokens.primerColorBackgroundPrimary)
        XCTAssertNotNil(tokens.primerRadiusMedium)
        XCTAssertNotNil(tokens.primerSpaceMedium)
        XCTAssertNotNil(tokens.primerSizeMedium)
    }

    // MARK: - Color Overrides

    func test_applyTheme_brandColorOverride_appliedToTokens() async throws {
        // Given
        let customBrand = Color.purple
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides(primerColorBrand: customBrand)
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerColorBrand, customBrand)
    }

    func test_applyTheme_grayColorOverrides_appliedToTokens() async throws {
        // Given
        let customGray = Color.gray
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides(
                primerColorGray000: customGray,
                primerColorGray100: customGray,
                primerColorGray200: customGray,
                primerColorGray300: customGray,
                primerColorGray400: customGray,
                primerColorGray500: customGray,
                primerColorGray600: customGray,
                primerColorGray900: customGray
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerColorGray000, customGray)
        XCTAssertEqual(tokens.primerColorGray100, customGray)
        XCTAssertEqual(tokens.primerColorGray200, customGray)
        XCTAssertEqual(tokens.primerColorGray300, customGray)
        XCTAssertEqual(tokens.primerColorGray400, customGray)
        XCTAssertEqual(tokens.primerColorGray500, customGray)
        XCTAssertEqual(tokens.primerColorGray600, customGray)
        XCTAssertEqual(tokens.primerColorGray900, customGray)
    }

    func test_applyTheme_semanticColorOverrides_appliedToTokens() async throws {
        // Given
        let customGreen = Color.green
        let customRed = Color.red
        let customBlue = Color.blue
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides(
                primerColorGreen500: customGreen,
                primerColorRed100: customRed,
                primerColorRed500: customRed,
                primerColorRed900: customRed,
                primerColorBlue500: customBlue,
                primerColorBlue900: customBlue,
                primerColorBackgroundPrimary: .white
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerColorGreen500, customGreen)
        XCTAssertEqual(tokens.primerColorRed100, customRed)
        XCTAssertEqual(tokens.primerColorRed500, customRed)
        XCTAssertEqual(tokens.primerColorRed900, customRed)
        XCTAssertEqual(tokens.primerColorBlue500, customBlue)
        XCTAssertEqual(tokens.primerColorBlue900, customBlue)
        XCTAssertEqual(tokens.primerColorBackgroundPrimary, .white)
    }

    func test_applyTheme_textColorOverrides_appliedToTokens() async throws {
        // Given
        let customColor = Color.orange
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides(
                primerColorTextPrimary: customColor,
                primerColorTextSecondary: customColor,
                primerColorTextPlaceholder: customColor,
                primerColorTextDisabled: customColor,
                primerColorTextNegative: customColor,
                primerColorTextLink: customColor
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerColorTextPrimary, customColor)
        XCTAssertEqual(tokens.primerColorTextSecondary, customColor)
        XCTAssertEqual(tokens.primerColorTextPlaceholder, customColor)
        XCTAssertEqual(tokens.primerColorTextDisabled, customColor)
        XCTAssertEqual(tokens.primerColorTextNegative, customColor)
        XCTAssertEqual(tokens.primerColorTextLink, customColor)
    }

    func test_applyTheme_outlinedBorderColorOverrides_appliedToTokens() async throws {
        // Given
        let customColor = Color.cyan
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides(
                primerColorBorderOutlinedDefault: customColor,
                primerColorBorderOutlinedHover: customColor,
                primerColorBorderOutlinedActive: customColor,
                primerColorBorderOutlinedFocus: customColor,
                primerColorBorderOutlinedDisabled: customColor,
                primerColorBorderOutlinedError: customColor,
                primerColorBorderOutlinedSelected: customColor,
                primerColorBorderOutlinedLoading: customColor
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerColorBorderOutlinedDefault, customColor)
        XCTAssertEqual(tokens.primerColorBorderOutlinedHover, customColor)
        XCTAssertEqual(tokens.primerColorBorderOutlinedActive, customColor)
        XCTAssertEqual(tokens.primerColorBorderOutlinedFocus, customColor)
        XCTAssertEqual(tokens.primerColorBorderOutlinedDisabled, customColor)
        XCTAssertEqual(tokens.primerColorBorderOutlinedError, customColor)
        XCTAssertEqual(tokens.primerColorBorderOutlinedSelected, customColor)
        XCTAssertEqual(tokens.primerColorBorderOutlinedLoading, customColor)
    }

    func test_applyTheme_transparentBorderColorOverrides_appliedToTokens() async throws {
        // Given
        let customColor = Color.mint
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides(
                primerColorBorderTransparentDefault: customColor,
                primerColorBorderTransparentHover: customColor,
                primerColorBorderTransparentActive: customColor,
                primerColorBorderTransparentFocus: customColor,
                primerColorBorderTransparentDisabled: customColor,
                primerColorBorderTransparentSelected: customColor
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerColorBorderTransparentDefault, customColor)
        XCTAssertEqual(tokens.primerColorBorderTransparentHover, customColor)
        XCTAssertEqual(tokens.primerColorBorderTransparentActive, customColor)
        XCTAssertEqual(tokens.primerColorBorderTransparentFocus, customColor)
        XCTAssertEqual(tokens.primerColorBorderTransparentDisabled, customColor)
        XCTAssertEqual(tokens.primerColorBorderTransparentSelected, customColor)
    }

    func test_applyTheme_iconAndOtherColorOverrides_appliedToTokens() async throws {
        // Given
        let customColor = Color.yellow
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides(
                primerColorIconPrimary: customColor,
                primerColorIconDisabled: customColor,
                primerColorIconNegative: customColor,
                primerColorIconPositive: customColor,
                primerColorFocus: customColor,
                primerColorLoader: customColor
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerColorIconPrimary, customColor)
        XCTAssertEqual(tokens.primerColorIconDisabled, customColor)
        XCTAssertEqual(tokens.primerColorIconNegative, customColor)
        XCTAssertEqual(tokens.primerColorIconPositive, customColor)
        XCTAssertEqual(tokens.primerColorFocus, customColor)
        XCTAssertEqual(tokens.primerColorLoader, customColor)
    }

    // MARK: - Radius Overrides

    func test_applyTheme_radiusOverrides_appliedToTokens() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            radius: RadiusOverrides(
                primerRadiusXsmall: 10,
                primerRadiusSmall: 20,
                primerRadiusMedium: 30,
                primerRadiusLarge: 40,
                primerRadiusBase: 50
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerRadiusXsmall, 10)
        XCTAssertEqual(tokens.primerRadiusSmall, 20)
        XCTAssertEqual(tokens.primerRadiusMedium, 30)
        XCTAssertEqual(tokens.primerRadiusLarge, 40)
        XCTAssertEqual(tokens.primerRadiusBase, 50)
    }

    func test_applyTheme_partialRadiusOverride_onlyOverriddenTokensChanged() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            radius: RadiusOverrides(primerRadiusMedium: 99)
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerRadiusMedium, 99)
        XCTAssertNotNil(tokens.primerRadiusSmall)
        XCTAssertNotEqual(tokens.primerRadiusSmall, 99)
    }

    // MARK: - Spacing Overrides

    func test_applyTheme_spacingOverrides_appliedToTokens() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            spacing: SpacingOverrides(
                primerSpaceXxsmall: 1,
                primerSpaceXsmall: 2,
                primerSpaceSmall: 3,
                primerSpaceMedium: 4,
                primerSpaceLarge: 5,
                primerSpaceXlarge: 6,
                primerSpaceXxlarge: 7,
                primerSpaceBase: 8
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerSpaceXxsmall, 1)
        XCTAssertEqual(tokens.primerSpaceXsmall, 2)
        XCTAssertEqual(tokens.primerSpaceSmall, 3)
        XCTAssertEqual(tokens.primerSpaceMedium, 4)
        XCTAssertEqual(tokens.primerSpaceLarge, 5)
        XCTAssertEqual(tokens.primerSpaceXlarge, 6)
        XCTAssertEqual(tokens.primerSpaceXxlarge, 7)
        XCTAssertEqual(tokens.primerSpaceBase, 8)
    }

    // MARK: - Size Overrides

    func test_applyTheme_sizeOverrides_appliedToTokens() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            sizes: SizeOverrides(
                primerSizeSmall: 10,
                primerSizeMedium: 20,
                primerSizeLarge: 30,
                primerSizeXlarge: 40,
                primerSizeXxlarge: 50,
                primerSizeXxxlarge: 60,
                primerSizeBase: 70
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerSizeSmall, 10)
        XCTAssertEqual(tokens.primerSizeMedium, 20)
        XCTAssertEqual(tokens.primerSizeLarge, 30)
        XCTAssertEqual(tokens.primerSizeXlarge, 40)
        XCTAssertEqual(tokens.primerSizeXxlarge, 50)
        XCTAssertEqual(tokens.primerSizeXxxlarge, 60)
        XCTAssertEqual(tokens.primerSizeBase, 70)
    }

    // MARK: - Typography Overrides

    func test_applyTheme_titleXlargeTypographyOverride_appliedToTokens() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            typography: TypographyOverrides(
                titleXlarge: .init(
                    font: "Helvetica",
                    letterSpacing: -1.0,
                    weight: .bold,
                    size: 32,
                    lineHeight: 40
                )
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerTypographyTitleXlargeFont, "Helvetica")
        XCTAssertEqual(tokens.primerTypographyTitleXlargeLetterSpacing, -1.0)
        XCTAssertEqual(tokens.primerTypographyTitleXlargeWeight, 700)
        XCTAssertEqual(tokens.primerTypographyTitleXlargeSize, 32)
        XCTAssertEqual(tokens.primerTypographyTitleXlargeLineHeight, 40)
    }

    func test_applyTheme_titleLargeTypographyOverride_appliedToTokens() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            typography: TypographyOverrides(
                titleLarge: .init(
                    font: "Menlo",
                    letterSpacing: 0.5,
                    weight: .semibold,
                    size: 20,
                    lineHeight: 28
                )
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerTypographyTitleLargeFont, "Menlo")
        XCTAssertEqual(tokens.primerTypographyTitleLargeLetterSpacing, 0.5)
        XCTAssertEqual(tokens.primerTypographyTitleLargeWeight, 600)
        XCTAssertEqual(tokens.primerTypographyTitleLargeSize, 20)
        XCTAssertEqual(tokens.primerTypographyTitleLargeLineHeight, 28)
    }

    func test_applyTheme_bodyLargeTypographyOverride_appliedToTokens() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            typography: TypographyOverrides(
                bodyLarge: .init(
                    font: "Georgia",
                    letterSpacing: 0,
                    weight: .regular,
                    size: 18,
                    lineHeight: 24
                )
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerTypographyBodyLargeFont, "Georgia")
        XCTAssertEqual(tokens.primerTypographyBodyLargeLetterSpacing, 0)
        XCTAssertEqual(tokens.primerTypographyBodyLargeWeight, 400)
        XCTAssertEqual(tokens.primerTypographyBodyLargeSize, 18)
        XCTAssertEqual(tokens.primerTypographyBodyLargeLineHeight, 24)
    }

    func test_applyTheme_bodyMediumTypographyOverride_appliedToTokens() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            typography: TypographyOverrides(
                bodyMedium: .init(
                    font: "Courier",
                    letterSpacing: 0.2,
                    weight: .medium,
                    size: 15,
                    lineHeight: 22
                )
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerTypographyBodyMediumFont, "Courier")
        XCTAssertEqual(tokens.primerTypographyBodyMediumLetterSpacing, 0.2)
        XCTAssertEqual(tokens.primerTypographyBodyMediumWeight, 500)
        XCTAssertEqual(tokens.primerTypographyBodyMediumSize, 15)
        XCTAssertEqual(tokens.primerTypographyBodyMediumLineHeight, 22)
    }

    func test_applyTheme_bodySmallTypographyOverride_appliedToTokens() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            typography: TypographyOverrides(
                bodySmall: .init(
                    font: "Arial",
                    letterSpacing: 0.1,
                    weight: .light,
                    size: 11,
                    lineHeight: 14
                )
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerTypographyBodySmallFont, "Arial")
        XCTAssertEqual(tokens.primerTypographyBodySmallLetterSpacing, 0.1)
        XCTAssertEqual(tokens.primerTypographyBodySmallWeight, 300)
        XCTAssertEqual(tokens.primerTypographyBodySmallSize, 11)
        XCTAssertEqual(tokens.primerTypographyBodySmallLineHeight, 14)
    }

    func test_applyTheme_partialTypographyOverride_onlySpecifiedFieldsChanged() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            typography: TypographyOverrides(
                titleXlarge: .init(font: "Custom", size: 50)
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerTypographyTitleXlargeFont, "Custom")
        XCTAssertEqual(tokens.primerTypographyTitleXlargeSize, 50)
        // Other typography fields should retain their loaded values
        XCTAssertNotNil(tokens.primerTypographyTitleXlargeWeight)
        XCTAssertNotNil(tokens.primerTypographyTitleXlargeLetterSpacing)
        XCTAssertNotNil(tokens.primerTypographyTitleXlargeLineHeight)
    }

    // MARK: - Font Weight Conversion

    func test_applyTheme_allFontWeights_convertedCorrectly() async throws {
        // Given
        let weights: [(Font.Weight, CGFloat)] = [
            (.ultraLight, 100),
            (.thin, 200),
            (.light, 300),
            (.regular, 400),
            (.medium, 500),
            (.semibold, 600),
            (.bold, 700),
            (.heavy, 800),
            (.black, 900),
        ]

        for (weight, expectedCGFloat) in weights {
            let manager = DesignTokensManager()
            let theme = PrimerCheckoutTheme(
                typography: TypographyOverrides(
                    titleXlarge: .init(weight: weight)
                )
            )
            manager.applyTheme(theme)

            // When
            try await manager.fetchTokens(for: .light)

            // Then
            let tokens = try XCTUnwrap(manager.tokens)
            XCTAssertEqual(
                tokens.primerTypographyTitleXlargeWeight, expectedCGFloat,
                "Weight \(weight) should convert to \(expectedCGFloat)"
            )
        }
    }

    // MARK: - Combined Overrides

    func test_applyTheme_allOverrideCategories_appliedTogether() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides(primerColorBrand: .red),
            radius: RadiusOverrides(primerRadiusMedium: 16),
            spacing: SpacingOverrides(primerSpaceLarge: 24),
            sizes: SizeOverrides(primerSizeXlarge: 48),
            typography: TypographyOverrides(
                bodySmall: .init(font: "Verdana", size: 10)
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerColorBrand, .red)
        XCTAssertEqual(tokens.primerRadiusMedium, 16)
        XCTAssertEqual(tokens.primerSpaceLarge, 24)
        XCTAssertEqual(tokens.primerSizeXlarge, 48)
        XCTAssertEqual(tokens.primerTypographyBodySmallFont, "Verdana")
        XCTAssertEqual(tokens.primerTypographyBodySmallSize, 10)
    }

    // MARK: - Theme Applied Before and After Fetch

    func test_applyTheme_appliedBeforeFetch_overridesApplied() async throws {
        // Given
        sut.applyTheme(PrimerCheckoutTheme(
            radius: RadiusOverrides(primerRadiusLarge: 100)
        ))

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        XCTAssertEqual(sut.tokens?.primerRadiusLarge, 100)
    }

    func test_applyTheme_appliedThenFetchedMultipleTimes_overridesPersist() async throws {
        // Given
        sut.applyTheme(PrimerCheckoutTheme(
            spacing: SpacingOverrides(primerSpaceBase: 10)
        ))

        // When
        try await sut.fetchTokens(for: .light)
        let firstLoad = sut.tokens?.primerSpaceBase

        try await sut.fetchTokens(for: .dark)
        let secondLoad = sut.tokens?.primerSpaceBase

        // Then
        XCTAssertEqual(firstLoad, 10)
        XCTAssertEqual(secondLoad, 10)
    }

    // MARK: - Theme Replacement

    func test_applyTheme_calledTwice_secondThemeOverwritesFirst() async throws {
        // Given
        sut.applyTheme(PrimerCheckoutTheme(
            radius: RadiusOverrides(primerRadiusMedium: 50)
        ))
        sut.applyTheme(PrimerCheckoutTheme(
            radius: RadiusOverrides(primerRadiusMedium: 75)
        ))

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        XCTAssertEqual(sut.tokens?.primerRadiusMedium, 75)
    }

    // MARK: - Nil Overrides Do Not Affect Tokens

    func test_applyTheme_nilColorOverrides_tokensRetainLoadedValues() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides()
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertNotNil(tokens.primerColorBrand)
        XCTAssertNotNil(tokens.primerColorBackgroundPrimary)
        XCTAssertNotNil(tokens.primerColorTextPrimary)
    }

    func test_applyTheme_nilRadiusOverrides_tokensRetainLoadedValues() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            radius: RadiusOverrides()
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertNotNil(tokens.primerRadiusMedium)
        XCTAssertNotNil(tokens.primerRadiusSmall)
    }

    // MARK: - Dark Mode with Overrides

    func test_applyTheme_darkModeWithOverrides_overridesAppliedOnDarkBase() async throws {
        // Given
        let customColor = Color.pink
        let theme = PrimerCheckoutTheme(
            colors: ColorOverrides(primerColorBrand: customColor)
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .dark)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerColorBrand, customColor)
    }

    // MARK: - Palette Override Cascade

    func test_fetchTokens_paletteOverride_cascadesIntoTokensThatAliasIt() async throws {
        // Given border.outlined.default aliases gray.300 in the token JSON
        let baseline = try await tokens(for: .light)
        let unthemedBorder = try XCTUnwrap(baseline.primerColorBorderOutlinedDefault)

        // Components chosen to survive the getRed round-trip exactly.
        let override = Color(red: 0.25, green: 0.5, blue: 0.75)
        sut.applyTheme(PrimerCheckoutTheme(colors: ColorOverrides(primerColorGray300: override)))

        // When
        try await sut.fetchTokens(for: .light)

        // Then the border holds the overridden value, not merely a different one.
        let themed = try XCTUnwrap(sut.tokens)
        XCTAssertNotEqual(themed.primerColorBorderOutlinedDefault, unthemedBorder)
        XCTAssertEqual(
            themed.primerColorBorderOutlinedDefault,
            Color(red: 0.25, green: 0.5, blue: 0.75, opacity: 1))
    }

    func test_fetchTokens_semanticOverride_winsOverPaletteOverride() async throws {
        // Given both the palette entry and the token that aliases it are overridden
        sut.applyTheme(
            PrimerCheckoutTheme(
                colors: ColorOverrides(
                    primerColorGray300: .pink,
                    primerColorBorderOutlinedDefault: .green
                )
            )
        )

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerColorBorderOutlinedDefault, .green)
        XCTAssertEqual(tokens.primerColorGray300, .pink)
    }

    func test_fetchTokens_noOverrides_paletteInjectionIsANoOp() async throws {
        // Given
        let withoutTheme = try await tokens(for: .light)

        // When
        sut.applyTheme(PrimerCheckoutTheme())
        try await sut.fetchTokens(for: .light)

        // Then
        let withEmptyTheme = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(withEmptyTheme.primerColorBorderOutlinedDefault, withoutTheme.primerColorBorderOutlinedDefault)
        XCTAssertEqual(withEmptyTheme.primerColorBackgroundPrimary, withoutTheme.primerColorBackgroundPrimary)
        XCTAssertEqual(withEmptyTheme.primerColorGray300, withoutTheme.primerColorGray300)
    }

    func test_fetchTokens_paletteOverride_cascadesInDarkMode() async throws {
        // Given
        let baseline = try await tokens(for: .dark)
        let unthemedBorder = try XCTUnwrap(baseline.primerColorBorderOutlinedDefault)

        let override = Color(red: 0.25, green: 0.5, blue: 0.75)
        sut.applyTheme(PrimerCheckoutTheme(colors: ColorOverrides(primerColorGray300: override)))

        // When
        try await sut.fetchTokens(for: .dark)

        // Then
        let themed = try XCTUnwrap(sut.tokens)
        XCTAssertNotEqual(themed.primerColorBorderOutlinedDefault, unthemedBorder)
        XCTAssertEqual(
            themed.primerColorBorderOutlinedDefault,
            Color(red: 0.25, green: 0.5, blue: 0.75, opacity: 1))
    }

    // MARK: - Width overrides

    func test_applyTheme_widthOverrides_appliedToTokens() async throws {
        // Given
        let theme = PrimerCheckoutTheme(
            width: WidthOverrides(
                primerWidthDefault: 3,
                primerWidthFocus: 5,
                primerWidthError: 7
            )
        )
        sut.applyTheme(theme)

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerWidthDefault, 3)
        XCTAssertEqual(tokens.primerWidthFocus, 5)
        XCTAssertEqual(tokens.primerWidthError, 7)
    }

    func test_widthTokens_defaultToDesignValues() async throws {
        // When no override is applied
        let tokens = try await tokens(for: .light)

        // Then the values match the design tokens: 1 at rest, 2 for focus and error
        XCTAssertEqual(tokens.primerWidthDefault, 1)
        XCTAssertEqual(tokens.primerWidthFocus, 2)
        XCTAssertEqual(tokens.primerWidthSelected, 2)
        XCTAssertEqual(tokens.primerWidthError, 2)
    }

    func test_borderWidthHelper_readsTheMatchingToken() async throws {
        // Given each width token is overridden with a distinct value
        sut.applyTheme(
            PrimerCheckoutTheme(
                width: WidthOverrides(
                    primerWidthDefault: 3,
                    primerWidthFocus: 5,
                    primerWidthError: 7,
                    primerWidthSelected: 9)))

        // When
        try await sut.fetchTokens(for: .light)

        // Then the helper each renderer calls resolves to its own token
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(PrimerBorderWidth.standard(tokens: tokens), 3)
        XCTAssertEqual(PrimerBorderWidth.focused(tokens: tokens), 5)
        XCTAssertEqual(PrimerBorderWidth.error(tokens: tokens), 7)
        XCTAssertEqual(PrimerBorderWidth.selected(tokens: tokens), 9)
    }

    // MARK: - Error typography

    func test_applyTheme_errorTypographyOverride_doesNotMoveBodySmall() async throws {
        // Given only the error style is overridden
        sut.applyTheme(
            PrimerCheckoutTheme(
                typography: TypographyOverrides(error: .init(size: 20))))

        // When
        try await sut.fetchTokens(for: .light)

        // Then error moves and the body-small label it used to share stays put
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerTypographyErrorSize, 20)
        XCTAssertEqual(tokens.primerTypographyBodySmallSize, 12)
    }

    func test_errorTypography_defaultsToBodySmall() async throws {
        // When nothing is overridden
        let tokens = try await tokens(for: .light)

        // Then error carries the body-small values, so nothing looks different out of the box
        XCTAssertEqual(tokens.primerTypographyErrorSize, tokens.primerTypographyBodySmallSize)
        XCTAssertEqual(tokens.primerTypographyErrorWeight, tokens.primerTypographyBodySmallWeight)
        XCTAssertEqual(tokens.primerTypographyErrorLineHeight, tokens.primerTypographyBodySmallLineHeight)
    }

    // MARK: - Token file coverage

    func test_baseTokenFile_everyColourLeafHasAMatchingTokenProperty() throws {
        // Given the shipped light token file, loaded the way production loads it
        let dict = try DesignTokensManager.loadJSON(named: "base")

        // When it is flattened the way production does
        let flat = DesignTokensProcessor.flattenTokenDictionary(
            DesignTokensProcessor.convertHexColors(in: dict))

        // Then every colour leaf has somewhere to land, so none is silently dropped
        let declared = Set(Mirror(reflecting: DesignTokens()).children.compactMap(\.label))
        let missing = flat.keys.filter { $0.hasPrefix("primerColor") && !declared.contains($0) }.sorted()
        XCTAssertTrue(missing.isEmpty, "base.json colour tokens with no DesignTokens property: \(missing)")
    }

    private func tokens(for colorScheme: ColorScheme) async throws -> DesignTokens {
        let manager = DesignTokensManager()
        try await manager.fetchTokens(for: colorScheme)
        return try XCTUnwrap(manager.tokens)
    }

    // MARK: - Input Token Inheritance

    func test_applyTheme_backgroundOverrideAlone_carriesIntoTheInputFill() async throws {
        // Given only the sheet colour is overridden
        sut.applyTheme(PrimerCheckoutTheme(colors: ColorOverrides(primerColorBackgroundPrimary: .pink)))

        // When
        try await sut.fetchTokens(for: .light)

        // Then the input fill follows it, as it did before the tokens were split
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerColorBackgroundPrimary, .pink)
        XCTAssertEqual(tokens.primerColorBackgroundOutlinedDefault, .pink)
    }

    func test_applyTheme_textOverrideAlone_carriesIntoTheInputText() async throws {
        // Given
        sut.applyTheme(PrimerCheckoutTheme(colors: ColorOverrides(primerColorTextPrimary: .pink)))

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerColorTextOutlinedDefault, .pink)
    }

    func test_applyTheme_explicitInputColour_winsOverTheInheritedOne() async throws {
        // Given both are named
        sut.applyTheme(
            PrimerCheckoutTheme(
                colors: ColorOverrides(
                    primerColorBackgroundPrimary: .pink,
                    primerColorBackgroundOutlinedDefault: .green
                )
            )
        )

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerColorBackgroundPrimary, .pink)
        XCTAssertEqual(tokens.primerColorBackgroundOutlinedDefault, .green)
    }

    // MARK: - ObservableObject Conformance

    func test_tokensProperty_isPublished() async throws {
        // Given
        let expectation = XCTestExpectation(description: "tokens published")
        let cancellable = sut.$tokens
            .dropFirst()
            .sink { _ in expectation.fulfill() }

        // When
        try await sut.fetchTokens(for: .light)

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        cancellable.cancel()
    }
}
