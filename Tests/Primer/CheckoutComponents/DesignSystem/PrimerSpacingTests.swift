//
//  PrimerSpacingTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
class PrimerSpacingTests: XCTestCase {

    // MARK: - Tests with Tokens

    func testXxsmallSpacingWithTokens() {
        let tokens = MockDesignTokens(primerSpaceXxsmall: 5)
        XCTAssertEqual(PrimerSpacing.xxsmall(tokens: tokens), 5)
    }

    func testXsmallSpacingWithTokens() {
        let tokens = MockDesignTokens(primerSpaceXsmall: 10)
        XCTAssertEqual(PrimerSpacing.xsmall(tokens: tokens), 10)
    }

    func testSmallSpacingWithTokens() {
        let tokens = MockDesignTokens(primerSpaceSmall: 20)
        XCTAssertEqual(PrimerSpacing.small(tokens: tokens), 20)
    }

    func testMediumSpacingWithTokens() {
        let tokens = MockDesignTokens(primerSpaceMedium: 30)
        XCTAssertEqual(PrimerSpacing.medium(tokens: tokens), 30)
    }

    func testLargeSpacingWithTokens() {
        let tokens = MockDesignTokens(primerSpaceLarge: 40)
        XCTAssertEqual(PrimerSpacing.large(tokens: tokens), 40)
    }

    func testXlargeSpacingWithTokens() {
        let tokens = MockDesignTokens(primerSpaceXlarge: 50)
        XCTAssertEqual(PrimerSpacing.xlarge(tokens: tokens), 50)
    }

    func testXxlargeSpacingWithTokens() {
        let tokens = MockDesignTokens(primerSpaceXxlarge: 60)
        XCTAssertEqual(PrimerSpacing.xxlarge(tokens: tokens), 60)
    }

    // MARK: - Tests without Tokens (Fallback Values)

    func testXxsmallSpacingWithoutTokens() {
        XCTAssertEqual(PrimerSpacing.xxsmall(tokens: nil), 2)
    }

    func testXsmallSpacingWithoutTokens() {
        XCTAssertEqual(PrimerSpacing.xsmall(tokens: nil), 4)
    }

    func testSmallSpacingWithoutTokens() {
        XCTAssertEqual(PrimerSpacing.small(tokens: nil), 8)
    }

    func testMediumSpacingWithoutTokens() {
        XCTAssertEqual(PrimerSpacing.medium(tokens: nil), 12)
    }

    func testLargeSpacingWithoutTokens() {
        XCTAssertEqual(PrimerSpacing.large(tokens: nil), 16)
    }

    func testXlargeSpacingWithoutTokens() {
        XCTAssertEqual(PrimerSpacing.xlarge(tokens: nil), 20)
    }

    func testXxlargeSpacingWithoutTokens() {
        XCTAssertEqual(PrimerSpacing.xxlarge(tokens: nil), 24)
    }

    // MARK: - Tests with Nil Token Values (Should Use Fallbacks)

    func testXsmallSpacingWithNilTokenValue() {
        let tokens = MockDesignTokens(primerSpaceXsmall: .some(nil))
        XCTAssertEqual(PrimerSpacing.xsmall(tokens: tokens), 4)
    }

    func testMediumSpacingWithNilTokenValue() {
        let tokens = MockDesignTokens(primerSpaceMedium: .some(nil))
        XCTAssertEqual(PrimerSpacing.medium(tokens: tokens), 12)
    }
}

// MARK: - Mock Design Tokens

private func MockDesignTokens(
    primerSpaceXxsmall: CGFloat?? = .none,
    primerSpaceXsmall: CGFloat?? = .none,
    primerSpaceSmall: CGFloat?? = .none,
    primerSpaceMedium: CGFloat?? = .none,
    primerSpaceLarge: CGFloat?? = .none,
    primerSpaceXlarge: CGFloat?? = .none,
    primerSpaceXxlarge: CGFloat?? = .none
) -> DesignTokens {
    // Create base DesignTokens from empty JSON
    let jsonData = "{}".data(using: .utf8)!
    let tokens = try! JSONDecoder().decode(DesignTokens.self, from: jsonData)

    // Set test values (double optional pattern to allow explicit nil)
    if let value = primerSpaceXxsmall { tokens.primerSpaceXxsmall = value }
    if let value = primerSpaceXsmall { tokens.primerSpaceXsmall = value }
    if let value = primerSpaceSmall { tokens.primerSpaceSmall = value }
    if let value = primerSpaceMedium { tokens.primerSpaceMedium = value }
    if let value = primerSpaceLarge { tokens.primerSpaceLarge = value }
    if let value = primerSpaceXlarge { tokens.primerSpaceXlarge = value }
    if let value = primerSpaceXxlarge { tokens.primerSpaceXxlarge = value }

    return tokens
}
