//
//  DesignTokensManagerOverrideSafetyTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import UIKit
import XCTest

@available(iOS 15.0, *)
@MainActor
final class DesignTokensManagerOverrideSafetyTests: XCTestCase {

    private var sut: DesignTokensManager!

    override func setUp() async throws {
        try await super.setUp()
        sut = DesignTokensManager()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Non-finite typography

    /// Body small is serialized before decoding, and `JSONSerialization` aborts the app on NaN or infinity.
    func test_nonFiniteBodySmallValues_areIgnoredInsteadOfCrashing() async throws {
        sut.applyTheme(PrimerCheckoutTheme(typography: TypographyOverrides(
            bodySmall: .init(letterSpacing: -.infinity, size: .nan, lineHeight: .infinity))))

        try await sut.fetchTokens(for: .light)

        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerTypographyBodySmallSize, 12)
        XCTAssertEqual(tokens.primerTypographyBodySmallLineHeight, 16)
        XCTAssertEqual(tokens.primerTypographyBodySmallLetterSpacing, 0)
    }

    func test_nonFiniteValueInAnotherStyle_keepsTheDefault() async throws {
        sut.applyTheme(PrimerCheckoutTheme(typography: TypographyOverrides(bodyLarge: .init(size: .nan))))

        try await sut.fetchTokens(for: .light)

        XCTAssertEqual(sut.tokens?.primerTypographyBodyLargeSize, 16)
    }

    func test_finiteValuesNextToANonFiniteOne_stillApply() async throws {
        sut.applyTheme(PrimerCheckoutTheme(typography: TypographyOverrides(
            bodySmall: .init(size: 14, lineHeight: .nan))))

        try await sut.fetchTokens(for: .light)

        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerTypographyBodySmallSize, 14)
        XCTAssertEqual(tokens.primerTypographyBodySmallLineHeight, 16)
        XCTAssertEqual(tokens.primerTypographyErrorSize, 14, "error still inherits the finite body small size")
    }

    /// The inline modifier keys a task on the theme, and NaN never equals itself, so the task would restart forever.
    func test_nonFiniteOverrides_leaveTheThemeEqualToItself() {
        let theme = PrimerCheckoutTheme(
            radius: RadiusOverrides(primerRadiusSmall: .nan),
            spacing: SpacingOverrides(primerSpaceSmall: .infinity),
            sizes: SizeOverrides(primerSizeSmall: -.infinity),
            typography: TypographyOverrides(bodySmall: .init(size: .nan)),
            width: WidthOverrides(primerWidthDefault: .nan)
        )

        XCTAssertEqual(theme, theme)
        XCTAssertNil(theme.typography?.bodySmall?.size)
        XCTAssertNil(theme.radius?.primerRadiusSmall)
    }

    // MARK: - Dynamic brand color

    func test_dynamicBrand_resolvesAliasesForTheLoadedScheme_notTheCurrentTrait() async throws {
        let brand = Color(UIColor { $0.userInterfaceStyle == .dark ? .green : .red })
        sut.applyTheme(PrimerCheckoutTheme(
            colors: ColorOverrides(primerColorBrand: brand),
            darkColors: ColorOverrides(primerColorBrand: brand)))
        let previous = UITraitCollection.current
        defer { UITraitCollection.current = previous }

        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .light)
        try await sut.fetchTokens(for: .dark)
        let darkFocus = try XCTUnwrap(sut.tokens?.primerColorFocus)

        UITraitCollection.current = UITraitCollection(userInterfaceStyle: .dark)
        try await sut.fetchTokens(for: .light)
        let lightFocus = try XCTUnwrap(sut.tokens?.primerColorFocus)

        XCTAssertEqual(components(of: darkFocus), components(of: UIColor.green))
        XCTAssertEqual(components(of: lightFocus), components(of: UIColor.red))
    }

    private func components(of color: Color) -> [CGFloat] {
        components(of: UIColor(color))
    }

    private func components(of color: UIColor) -> [CGFloat] {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return [red, green, blue, alpha].map { ($0 * 255).rounded() }
    }
}
