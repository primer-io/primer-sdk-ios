//
//  ThemeOverrideMappingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

/// Each public override has to land on its own token, or setting it changes nothing.
@available(iOS 15.0, *)
@MainActor
final class ThemeOverrideMappingTests: XCTestCase {

    private var sut: DesignTokensManager!

    override func setUp() async throws {
        try await super.setUp()
        sut = DesignTokensManager()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    func test_backgroundOverrides_eachReachItsOwnToken() async throws {
        let colors = (1 ... 13).map { Color(red: Double($0) / 20, green: 0.5, blue: 0.5) }
        sut.applyTheme(PrimerCheckoutTheme(colors: ColorOverrides(
            primerColorBackgroundPrimary: colors[0],
            primerColorBackgroundSecondary: colors[1],
            primerColorBackgroundOutlinedDefault: colors[2],
            primerColorBackgroundOutlinedActive: colors[3],
            primerColorBackgroundOutlinedDisabled: colors[4],
            primerColorBackgroundOutlinedLoading: colors[5],
            primerColorBackgroundOutlinedSelected: colors[6],
            primerColorBackgroundOutlinedError: colors[7],
            primerColorBackgroundTransparentDefault: colors[8],
            primerColorBackgroundTransparentActive: colors[9],
            primerColorBackgroundTransparentDisabled: colors[10],
            primerColorBackgroundTransparentLoading: colors[11],
            primerColorBackgroundTransparentSelected: colors[12]
        )))

        try await sut.fetchTokens(for: .light)

        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(
            [
                tokens.primerColorBackgroundPrimary,
                tokens.primerColorBackgroundSecondary,
                tokens.primerColorBackgroundOutlinedDefault,
                tokens.primerColorBackgroundOutlinedActive,
                tokens.primerColorBackgroundOutlinedDisabled,
                tokens.primerColorBackgroundOutlinedLoading,
                tokens.primerColorBackgroundOutlinedSelected,
                tokens.primerColorBackgroundOutlinedError,
                tokens.primerColorBackgroundTransparentDefault,
                tokens.primerColorBackgroundTransparentActive,
                tokens.primerColorBackgroundTransparentDisabled,
                tokens.primerColorBackgroundTransparentLoading,
                tokens.primerColorBackgroundTransparentSelected
            ].map { rgba($0) },
            colors.map { rgba($0) }
        )
    }

    func test_errorTypographyOverride_movesEveryErrorToken() async throws {
        sut.applyTheme(PrimerCheckoutTheme(typography: TypographyOverrides(
            error: .init(font: "Courier New", letterSpacing: 1.2, weight: .bold, size: 13, lineHeight: 19))))

        try await sut.fetchTokens(for: .light)

        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(tokens.primerTypographyErrorFont, "Courier New")
        XCTAssertEqual(tokens.primerTypographyErrorWeight, 700)
        XCTAssertEqual(tokens.primerTypographyErrorSize, 13)
        XCTAssertEqual(tokens.primerTypographyErrorLetterSpacing, 1.2)
        XCTAssertEqual(tokens.primerTypographyErrorLineHeight, 19)
    }

    // MARK: - Focus

    /// Both focus borders alias focus, as on Android, so the focus override moves the focused field border.
    func test_focusOverride_movesBothFocusBorders() async throws {
        sut.applyTheme(PrimerCheckoutTheme(colors: ColorOverrides(primerColorFocus: .orange)))

        try await sut.fetchTokens(for: .light)

        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(rgba(tokens.primerColorBorderOutlinedFocus), rgba(.orange))
        XCTAssertEqual(rgba(tokens.primerColorBorderTransparentFocus), rgba(.orange))
        XCTAssertEqual(rgba(CheckoutColors.borderFocus(tokens: tokens)), rgba(.orange))
    }

    func test_focusOverride_leavesAFocusBorderTheMerchantNamed() async throws {
        sut.applyTheme(PrimerCheckoutTheme(colors: ColorOverrides(
            primerColorBorderOutlinedFocus: .purple,
            primerColorFocus: .orange
        )))

        try await sut.fetchTokens(for: .light)

        XCTAssertEqual(rgba(sut.tokens?.primerColorBorderOutlinedFocus), rgba(.purple))
    }

    // MARK: - Keyboard and AutoFill per field

    func test_fieldConfiguration_offersTheMatchingAutoFill() {
        let expected: [PrimerInputElementType: UITextContentType] = [
            .phoneNumber: .telephoneNumber,
            .firstName: .givenName,
            .lastName: .familyName,
            .addressLine1: .streetAddressLine1,
            .addressLine2: .streetAddressLine2
        ]

        for (type, contentType) in expected {
            XCTAssertEqual(type.fieldConfiguration.textContentType, contentType, "\(type)")
        }
    }

    func test_fieldConfiguration_givesThePhoneThePhonePad() {
        XCTAssertEqual(PrimerInputElementType.phoneNumber.fieldConfiguration.keyboardType, .phonePad)
        XCTAssertEqual(PrimerInputElementType.firstName.fieldConfiguration.keyboardType, .default)
    }

    /// Overrides are pinned to the loaded scheme, so they compare by value, not by identity.
    private func rgba(_ color: Color?) -> [Int] {
        guard let color else { return [] }
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            .getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return [red, green, blue, alpha].map { Int(($0 * 255).rounded()) }
    }
}
