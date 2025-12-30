//
//  CheckoutComponentsThemeTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import XCTest
@testable import PrimerSDK

/// Tests for CheckoutComponentsTheme and related override structures.
@available(iOS 15.0, *)
final class CheckoutComponentsThemeTests: XCTestCase {

    // MARK: - PrimerCheckoutTheme Tests

    func test_primerCheckoutTheme_defaultInit_allPropertiesNil() {
        // When
        let theme = PrimerCheckoutTheme()

        // Then
        XCTAssertNil(theme.colors)
        XCTAssertNil(theme.radius)
        XCTAssertNil(theme.spacing)
        XCTAssertNil(theme.sizes)
        XCTAssertNil(theme.typography)
        XCTAssertNil(theme.borderWidth)
    }

    func test_primerCheckoutTheme_withColors_setsColors() {
        // Given
        let colors = ColorOverrides(primerColorBrand: .blue)

        // When
        let theme = PrimerCheckoutTheme(colors: colors)

        // Then
        XCTAssertNotNil(theme.colors)
        XCTAssertEqual(theme.colors?.primerColorBrand, .blue)
    }

    func test_primerCheckoutTheme_withAllOverrides_setsAllProperties() {
        // Given
        let colors = ColorOverrides(primerColorBrand: .red)
        let radius = RadiusOverrides(primerRadiusBase: 8)
        let spacing = SpacingOverrides(primerSpaceBase: 4)
        let sizes = SizeOverrides(primerSizeBase: 2)
        let typography = TypographyOverrides(bodyMedium: .init(size: 14))
        let borderWidth = BorderWidthOverrides(primerBorderWidthThin: 1)

        // When
        let theme = PrimerCheckoutTheme(
            colors: colors,
            radius: radius,
            spacing: spacing,
            sizes: sizes,
            typography: typography,
            borderWidth: borderWidth
        )

        // Then
        XCTAssertNotNil(theme.colors)
        XCTAssertNotNil(theme.radius)
        XCTAssertNotNil(theme.spacing)
        XCTAssertNotNil(theme.sizes)
        XCTAssertNotNil(theme.typography)
        XCTAssertNotNil(theme.borderWidth)
    }

    // MARK: - ColorOverrides Tests

    func test_colorOverrides_defaultInit_allPropertiesNil() {
        // When
        let colors = ColorOverrides()

        // Then
        XCTAssertNil(colors.primerColorBrand)
        XCTAssertNil(colors.primerColorGray000)
        XCTAssertNil(colors.primerColorBackground)
        XCTAssertNil(colors.primerColorTextPrimary)
    }

    func test_colorOverrides_withBrandColor_setsBrandColor() {
        // When
        let colors = ColorOverrides(primerColorBrand: .purple)

        // Then
        XCTAssertEqual(colors.primerColorBrand, .purple)
    }

    func test_colorOverrides_withGrayColors_setsGrayColors() {
        // When
        let colors = ColorOverrides(
            primerColorGray000: .white,
            primerColorGray100: .gray,
            primerColorGray900: .black
        )

        // Then
        XCTAssertEqual(colors.primerColorGray000, .white)
        XCTAssertEqual(colors.primerColorGray100, .gray)
        XCTAssertEqual(colors.primerColorGray900, .black)
    }

    func test_colorOverrides_withSemanticColors_setsSemanticColors() {
        // When
        let colors = ColorOverrides(
            primerColorGreen500: .green,
            primerColorRed500: .red,
            primerColorBlue500: .blue
        )

        // Then
        XCTAssertEqual(colors.primerColorGreen500, .green)
        XCTAssertEqual(colors.primerColorRed500, .red)
        XCTAssertEqual(colors.primerColorBlue500, .blue)
    }

    func test_colorOverrides_withTextColors_setsTextColors() {
        // When
        let colors = ColorOverrides(
            primerColorTextPrimary: .black,
            primerColorTextSecondary: .gray,
            primerColorTextPlaceholder: .gray.opacity(0.5),
            primerColorTextDisabled: .gray.opacity(0.3)
        )

        // Then
        XCTAssertNotNil(colors.primerColorTextPrimary)
        XCTAssertNotNil(colors.primerColorTextSecondary)
        XCTAssertNotNil(colors.primerColorTextPlaceholder)
        XCTAssertNotNil(colors.primerColorTextDisabled)
    }

    func test_colorOverrides_withBorderColors_setsBorderColors() {
        // When
        let colors = ColorOverrides(
            primerColorBorderOutlinedDefault: .gray,
            primerColorBorderOutlinedFocus: .blue,
            primerColorBorderOutlinedError: .red
        )

        // Then
        XCTAssertNotNil(colors.primerColorBorderOutlinedDefault)
        XCTAssertNotNil(colors.primerColorBorderOutlinedError)
        XCTAssertNotNil(colors.primerColorBorderOutlinedFocus)
    }

    func test_colorOverrides_withIconColors_setsIconColors() {
        // When
        let colors = ColorOverrides(
            primerColorIconPrimary: .black,
            primerColorIconDisabled: .gray,
            primerColorIconNegative: .red,
            primerColorIconPositive: .green
        )

        // Then
        XCTAssertEqual(colors.primerColorIconPrimary, .black)
        XCTAssertEqual(colors.primerColorIconDisabled, .gray)
        XCTAssertEqual(colors.primerColorIconNegative, .red)
        XCTAssertEqual(colors.primerColorIconPositive, .green)
    }

    // MARK: - RadiusOverrides Tests

    func test_radiusOverrides_defaultInit_allPropertiesNil() {
        // When
        let radius = RadiusOverrides()

        // Then
        XCTAssertNil(radius.primerRadiusXsmall)
        XCTAssertNil(radius.primerRadiusSmall)
        XCTAssertNil(radius.primerRadiusMedium)
        XCTAssertNil(radius.primerRadiusLarge)
        XCTAssertNil(radius.primerRadiusBase)
    }

    func test_radiusOverrides_withValues_setsValues() {
        // When
        let radius = RadiusOverrides(
            primerRadiusXsmall: 2,
            primerRadiusSmall: 4,
            primerRadiusMedium: 8,
            primerRadiusLarge: 12,
            primerRadiusBase: 4
        )

        // Then
        XCTAssertEqual(radius.primerRadiusXsmall, 2)
        XCTAssertEqual(radius.primerRadiusSmall, 4)
        XCTAssertEqual(radius.primerRadiusMedium, 8)
        XCTAssertEqual(radius.primerRadiusLarge, 12)
        XCTAssertEqual(radius.primerRadiusBase, 4)
    }

    // MARK: - SpacingOverrides Tests

    func test_spacingOverrides_defaultInit_allPropertiesNil() {
        // When
        let spacing = SpacingOverrides()

        // Then
        XCTAssertNil(spacing.primerSpaceXxsmall)
        XCTAssertNil(spacing.primerSpaceXsmall)
        XCTAssertNil(spacing.primerSpaceSmall)
        XCTAssertNil(spacing.primerSpaceMedium)
        XCTAssertNil(spacing.primerSpaceLarge)
        XCTAssertNil(spacing.primerSpaceXlarge)
        XCTAssertNil(spacing.primerSpaceXxlarge)
        XCTAssertNil(spacing.primerSpaceBase)
    }

    func test_spacingOverrides_withValues_setsValues() {
        // When
        let spacing = SpacingOverrides(
            primerSpaceXxsmall: 2,
            primerSpaceXsmall: 4,
            primerSpaceSmall: 8,
            primerSpaceMedium: 12,
            primerSpaceLarge: 16,
            primerSpaceXlarge: 20,
            primerSpaceXxlarge: 24,
            primerSpaceBase: 4
        )

        // Then
        XCTAssertEqual(spacing.primerSpaceXxsmall, 2)
        XCTAssertEqual(spacing.primerSpaceXsmall, 4)
        XCTAssertEqual(spacing.primerSpaceSmall, 8)
        XCTAssertEqual(spacing.primerSpaceMedium, 12)
        XCTAssertEqual(spacing.primerSpaceLarge, 16)
        XCTAssertEqual(spacing.primerSpaceXlarge, 20)
        XCTAssertEqual(spacing.primerSpaceXxlarge, 24)
        XCTAssertEqual(spacing.primerSpaceBase, 4)
    }

    // MARK: - SizeOverrides Tests

    func test_sizeOverrides_defaultInit_allPropertiesNil() {
        // When
        let sizes = SizeOverrides()

        // Then
        XCTAssertNil(sizes.primerSizeSmall)
        XCTAssertNil(sizes.primerSizeMedium)
        XCTAssertNil(sizes.primerSizeLarge)
        XCTAssertNil(sizes.primerSizeXlarge)
        XCTAssertNil(sizes.primerSizeXxlarge)
        XCTAssertNil(sizes.primerSizeXxxlarge)
        XCTAssertNil(sizes.primerSizeBase)
    }

    func test_sizeOverrides_withValues_setsValues() {
        // When
        let sizes = SizeOverrides(
            primerSizeSmall: 16,
            primerSizeMedium: 20,
            primerSizeLarge: 24,
            primerSizeXlarge: 32,
            primerSizeXxlarge: 44,
            primerSizeXxxlarge: 56,
            primerSizeBase: 4
        )

        // Then
        XCTAssertEqual(sizes.primerSizeSmall, 16)
        XCTAssertEqual(sizes.primerSizeMedium, 20)
        XCTAssertEqual(sizes.primerSizeLarge, 24)
        XCTAssertEqual(sizes.primerSizeXlarge, 32)
        XCTAssertEqual(sizes.primerSizeXxlarge, 44)
        XCTAssertEqual(sizes.primerSizeXxxlarge, 56)
        XCTAssertEqual(sizes.primerSizeBase, 4)
    }

    // MARK: - TypographyOverrides Tests

    func test_typographyOverrides_defaultInit_allPropertiesNil() {
        // When
        let typography = TypographyOverrides()

        // Then
        XCTAssertNil(typography.titleXlarge)
        XCTAssertNil(typography.titleLarge)
        XCTAssertNil(typography.bodyLarge)
        XCTAssertNil(typography.bodyMedium)
        XCTAssertNil(typography.bodySmall)
    }

    func test_typographyOverrides_withStyles_setsStyles() {
        // Given
        let titleStyle = TypographyOverrides.TypographyStyle(
            font: "Inter",
            letterSpacing: -0.6,
            weight: .semibold,
            size: 24,
            lineHeight: 32
        )
        let bodyStyle = TypographyOverrides.TypographyStyle(
            font: "Inter",
            letterSpacing: 0,
            weight: .regular,
            size: 14,
            lineHeight: 20
        )

        // When
        let typography = TypographyOverrides(
            titleXlarge: titleStyle,
            bodyMedium: bodyStyle
        )

        // Then
        XCTAssertNotNil(typography.titleXlarge)
        XCTAssertEqual(typography.titleXlarge?.font, "Inter")
        XCTAssertEqual(typography.titleXlarge?.size, 24)
        XCTAssertEqual(typography.titleXlarge?.lineHeight, 32)

        XCTAssertNotNil(typography.bodyMedium)
        XCTAssertEqual(typography.bodyMedium?.size, 14)
    }

    // MARK: - TypographyStyle Tests

    func test_typographyStyle_defaultInit_allPropertiesNil() {
        // When
        let style = TypographyOverrides.TypographyStyle()

        // Then
        XCTAssertNil(style.font)
        XCTAssertNil(style.letterSpacing)
        XCTAssertNil(style.weight)
        XCTAssertNil(style.size)
        XCTAssertNil(style.lineHeight)
    }

    func test_typographyStyle_withAllProperties_setsAllProperties() {
        // When
        let style = TypographyOverrides.TypographyStyle(
            font: "Helvetica",
            letterSpacing: 0.5,
            weight: .bold,
            size: 18,
            lineHeight: 24
        )

        // Then
        XCTAssertEqual(style.font, "Helvetica")
        XCTAssertEqual(style.letterSpacing, 0.5)
        XCTAssertEqual(style.weight, .bold)
        XCTAssertEqual(style.size, 18)
        XCTAssertEqual(style.lineHeight, 24)
    }

    func test_typographyStyle_withPartialProperties_setsOnlyProvided() {
        // When
        let style = TypographyOverrides.TypographyStyle(
            weight: .medium,
            size: 16
        )

        // Then
        XCTAssertNil(style.font)
        XCTAssertNil(style.letterSpacing)
        XCTAssertNotNil(style.weight)
        XCTAssertEqual(style.size, 16)
        XCTAssertNil(style.lineHeight)
    }

    // MARK: - BorderWidthOverrides Tests

    func test_borderWidthOverrides_defaultInit_allPropertiesNil() {
        // When
        let borderWidth = BorderWidthOverrides()

        // Then
        XCTAssertNil(borderWidth.primerBorderWidthThin)
        XCTAssertNil(borderWidth.primerBorderWidthMedium)
        XCTAssertNil(borderWidth.primerBorderWidthThick)
    }

    func test_borderWidthOverrides_withValues_setsValues() {
        // When
        let borderWidth = BorderWidthOverrides(
            primerBorderWidthThin: 1,
            primerBorderWidthMedium: 2,
            primerBorderWidthThick: 3
        )

        // Then
        XCTAssertEqual(borderWidth.primerBorderWidthThin, 1)
        XCTAssertEqual(borderWidth.primerBorderWidthMedium, 2)
        XCTAssertEqual(borderWidth.primerBorderWidthThick, 3)
    }

    func test_borderWidthOverrides_withCustomValues_setsCustomValues() {
        // When
        let borderWidth = BorderWidthOverrides(
            primerBorderWidthThin: 0.5,
            primerBorderWidthThick: 5
        )

        // Then
        XCTAssertEqual(borderWidth.primerBorderWidthThin, 0.5)
        XCTAssertNil(borderWidth.primerBorderWidthMedium)
        XCTAssertEqual(borderWidth.primerBorderWidthThick, 5)
    }

    // MARK: - Integration Tests

    func test_fullThemeConfiguration_createsCompleteTheme() {
        // Given
        let colors = ColorOverrides(
            primerColorBrand: .blue,
            primerColorBackground: .white,
            primerColorTextPrimary: .black,
            primerColorBorderOutlinedDefault: .gray
        )

        let radius = RadiusOverrides(
            primerRadiusSmall: 4,
            primerRadiusMedium: 8,
            primerRadiusLarge: 16
        )

        let spacing = SpacingOverrides(
            primerSpaceSmall: 8,
            primerSpaceMedium: 16,
            primerSpaceLarge: 24
        )

        let sizes = SizeOverrides(
            primerSizeMedium: 24,
            primerSizeLarge: 32
        )

        let typography = TypographyOverrides(
            titleLarge: .init(font: "Inter", weight: .bold, size: 20),
            bodyMedium: .init(font: "Inter", weight: .regular, size: 14)
        )

        let borderWidth = BorderWidthOverrides(
            primerBorderWidthThin: 1,
            primerBorderWidthMedium: 2
        )

        // When
        let theme = PrimerCheckoutTheme(
            colors: colors,
            radius: radius,
            spacing: spacing,
            sizes: sizes,
            typography: typography,
            borderWidth: borderWidth
        )

        // Then - verify all components are properly set
        XCTAssertEqual(theme.colors?.primerColorBrand, .blue)
        XCTAssertEqual(theme.radius?.primerRadiusMedium, 8)
        XCTAssertEqual(theme.spacing?.primerSpaceMedium, 16)
        XCTAssertEqual(theme.sizes?.primerSizeMedium, 24)
        XCTAssertEqual(theme.typography?.titleLarge?.font, "Inter")
        XCTAssertEqual(theme.borderWidth?.primerBorderWidthThin, 1)
    }
}
