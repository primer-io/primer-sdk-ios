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
}
