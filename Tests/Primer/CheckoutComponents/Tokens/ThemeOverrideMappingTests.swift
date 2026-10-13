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
        let colors = (1 ... 4).map { Color(red: Double($0) / 20, green: 0.5, blue: 0.5) }
        sut.applyTheme(PrimerCheckoutTheme(colors: ColorOverrides(
            primerColorBackgroundPrimary: colors[0],
            primerColorBackgroundSecondary: colors[1],
            primerColorBackgroundOutlinedDefault: colors[2],
            primerColorBackgroundOutlinedDisabled: colors[3]
        )))

        try await sut.fetchTokens(for: .light)

        let tokens = try XCTUnwrap(sut.tokens)
        XCTAssertEqual(
            [
                tokens.primerColorBackgroundPrimary,
                tokens.primerColorBackgroundSecondary,
                tokens.primerColorBackgroundOutlinedDefault,
                tokens.primerColorBackgroundOutlinedDisabled
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
}
