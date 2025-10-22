//
//  PrimerLayoutTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
class PrimerLayoutTests: XCTestCase {

    // MARK: - PrimerSize Tests with Tokens

    func testSmallSizeWithTokens() {
        let tokens = MockDesignTokens(primerSizeSmall: 100)
        XCTAssertEqual(PrimerSize.small(tokens: tokens), 100)
    }

    func testMediumSizeWithTokens() {
        let tokens = MockDesignTokens(primerSizeMedium: 200)
        XCTAssertEqual(PrimerSize.medium(tokens: tokens), 200)
    }

    func testLargeSizeWithTokens() {
        let tokens = MockDesignTokens(primerSizeLarge: 300)
        XCTAssertEqual(PrimerSize.large(tokens: tokens), 300)
    }

    func testXlargeSizeWithTokens() {
        let tokens = MockDesignTokens(primerSizeXlarge: 400)
        XCTAssertEqual(PrimerSize.xlarge(tokens: tokens), 400)
    }

    func testXxlargeSizeWithTokens() {
        let tokens = MockDesignTokens(primerSizeXxlarge: 500)
        XCTAssertEqual(PrimerSize.xxlarge(tokens: tokens), 500)
    }

    func testXxxlargeSizeWithTokens() {
        let tokens = MockDesignTokens(primerSizeXxxlarge: 600)
        XCTAssertEqual(PrimerSize.xxxlarge(tokens: tokens), 600)
    }

    // MARK: - PrimerSize Tests without Tokens (Fallback Values)

    func testSmallSizeWithoutTokens() {
        XCTAssertEqual(PrimerSize.small(tokens: nil), 16)
    }

    func testMediumSizeWithoutTokens() {
        XCTAssertEqual(PrimerSize.medium(tokens: nil), 20)
    }

    func testLargeSizeWithoutTokens() {
        XCTAssertEqual(PrimerSize.large(tokens: nil), 24)
    }

    func testXlargeSizeWithoutTokens() {
        XCTAssertEqual(PrimerSize.xlarge(tokens: nil), 32)
    }

    func testXxlargeSizeWithoutTokens() {
        XCTAssertEqual(PrimerSize.xxlarge(tokens: nil), 44)
    }

    func testXxxlargeSizeWithoutTokens() {
        XCTAssertEqual(PrimerSize.xxxlarge(tokens: nil), 56)
    }

    // MARK: - PrimerRadius Tests with Tokens

    func testXsmallRadiusWithTokens() {
        let tokens = MockDesignTokens(primerRadiusXsmall: 10)
        XCTAssertEqual(PrimerRadius.xsmall(tokens: tokens), 10)
    }

    func testSmallRadiusWithTokens() {
        let tokens = MockDesignTokens(primerRadiusSmall: 20)
        XCTAssertEqual(PrimerRadius.small(tokens: tokens), 20)
    }

    func testMediumRadiusWithTokens() {
        let tokens = MockDesignTokens(primerRadiusMedium: 30)
        XCTAssertEqual(PrimerRadius.medium(tokens: tokens), 30)
    }

    func testLargeRadiusWithTokens() {
        let tokens = MockDesignTokens(primerRadiusLarge: 40)
        XCTAssertEqual(PrimerRadius.large(tokens: tokens), 40)
    }

    // MARK: - PrimerRadius Tests without Tokens (Fallback Values)

    func testXsmallRadiusWithoutTokens() {
        XCTAssertEqual(PrimerRadius.xsmall(tokens: nil), 2)
    }

    func testSmallRadiusWithoutTokens() {
        XCTAssertEqual(PrimerRadius.small(tokens: nil), 4)
    }

    func testMediumRadiusWithoutTokens() {
        XCTAssertEqual(PrimerRadius.medium(tokens: nil), 8)
    }

    func testLargeRadiusWithoutTokens() {
        XCTAssertEqual(PrimerRadius.large(tokens: nil), 12)
    }

    // MARK: - Tests with Nil Token Values (Should Use Fallbacks)

    func testSmallSizeWithNilTokenValue() {
        let tokens = MockDesignTokens(primerSizeSmall: .some(nil))
        XCTAssertEqual(PrimerSize.small(tokens: tokens), 16)
    }

    func testSmallRadiusWithNilTokenValue() {
        let tokens = MockDesignTokens(primerRadiusSmall: .some(nil))
        XCTAssertEqual(PrimerRadius.small(tokens: tokens), 4)
    }
}

// MARK: - Mock Design Tokens

private func MockDesignTokens(
    primerSizeSmall: CGFloat?? = .none,
    primerSizeMedium: CGFloat?? = .none,
    primerSizeLarge: CGFloat?? = .none,
    primerSizeXlarge: CGFloat?? = .none,
    primerSizeXxlarge: CGFloat?? = .none,
    primerSizeXxxlarge: CGFloat?? = .none,
    primerRadiusXsmall: CGFloat?? = .none,
    primerRadiusSmall: CGFloat?? = .none,
    primerRadiusMedium: CGFloat?? = .none,
    primerRadiusLarge: CGFloat?? = .none
) -> DesignTokens {
    // Create base DesignTokens from empty JSON
    let jsonData = "{}".data(using: .utf8)!
    let tokens = try! JSONDecoder().decode(DesignTokens.self, from: jsonData)

    // Set test values (double optional pattern to allow explicit nil)
    if let value = primerSizeSmall { tokens.primerSizeSmall = value }
    if let value = primerSizeMedium { tokens.primerSizeMedium = value }
    if let value = primerSizeLarge { tokens.primerSizeLarge = value }
    if let value = primerSizeXlarge { tokens.primerSizeXlarge = value }
    if let value = primerSizeXxlarge { tokens.primerSizeXxlarge = value }
    if let value = primerSizeXxxlarge { tokens.primerSizeXxxlarge = value }
    if let value = primerRadiusXsmall { tokens.primerRadiusXsmall = value }
    if let value = primerRadiusSmall { tokens.primerRadiusSmall = value }
    if let value = primerRadiusMedium { tokens.primerRadiusMedium = value }
    if let value = primerRadiusLarge { tokens.primerRadiusLarge = value }

    return tokens
}
