//
//  CheckoutColorsTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

@available(iOS 15.0, *)
class CheckoutColorsTests: XCTestCase {

    // MARK: - Text Colors

    func testTextPrimaryWithValue() {
        let tokens = MockDesignTokens(primerColorTextPrimary: Color.blue)
        XCTAssertEqual(PrimerCheckoutColors.textPrimary(tokens: tokens), Color.blue)
    }

    func testTextPrimaryWithNil() {
        let tokens = MockDesignTokens(primerColorTextPrimary: .some(nil))
        XCTAssertEqual(PrimerCheckoutColors.textPrimary(tokens: tokens), Color(red: 0x21/255, green: 0x21/255, blue: 0x21/255))
    }

    func testTextSecondaryWithValue() {
        let tokens = MockDesignTokens(primerColorTextSecondary: Color.green)
        XCTAssertEqual(PrimerCheckoutColors.textSecondary(tokens: tokens), Color.green)
    }

    func testTextSecondaryWithNil() {
        let tokens = MockDesignTokens(primerColorTextSecondary: .some(nil))
        XCTAssertEqual(PrimerCheckoutColors.textSecondary(tokens: tokens), .secondary)
    }

    func testTextNegativeWithValue() {
        let tokens = MockDesignTokens(primerColorTextNegative: Color.orange)
        XCTAssertEqual(PrimerCheckoutColors.textNegative(tokens: tokens), Color.orange)
    }

    func testTextNegativeWithNil() {
        let tokens = MockDesignTokens(primerColorTextNegative: .some(nil))
        XCTAssertEqual(PrimerCheckoutColors.textNegative(tokens: tokens), .red)
    }

    func testTextPlaceholderWithValue() {
        let tokens = MockDesignTokens(primerColorTextPlaceholder: Color.brown)
        XCTAssertEqual(PrimerCheckoutColors.textPlaceholder(tokens: tokens), Color.brown)
    }

    func testTextPlaceholderWithNil() {
        let tokens = MockDesignTokens(primerColorTextPlaceholder: .some(nil))
        XCTAssertNotNil(PrimerCheckoutColors.textPlaceholder(tokens: tokens))
    }

    // MARK: - Icon Colors

    func testIconNegativeWithValue() {
        let tokens = MockDesignTokens(primerColorIconNegative: Color.purple)
        XCTAssertEqual(PrimerCheckoutColors.iconNegative(tokens: tokens), Color.purple)
    }

    func testIconNegativeWithNil() {
        let tokens = MockDesignTokens(primerColorIconNegative: .some(nil))
        XCTAssertEqual(PrimerCheckoutColors.iconNegative(tokens: tokens), Color(red: 1.0, green: 0.45, blue: 0.47))
    }

    func testIconPositiveWithValue() {
        let tokens = MockDesignTokens(primerColorIconPositive: Color.mint)
        XCTAssertEqual(PrimerCheckoutColors.iconPositive(tokens: tokens), Color.mint)
    }

    func testIconPositiveWithNil() {
        let tokens = MockDesignTokens(primerColorIconPositive: .some(nil))
        XCTAssertNotNil(PrimerCheckoutColors.iconPositive(tokens: tokens))
    }

    // MARK: - Border Colors

    func testBorderDefaultWithValue() {
        let tokens = MockDesignTokens(primerColorBorderOutlinedDefault: Color.gray)
        XCTAssertEqual(PrimerCheckoutColors.borderDefault(tokens: tokens), Color.gray)
    }

    func testBorderDefaultWithNil() {
        let tokens = MockDesignTokens(primerColorBorderOutlinedDefault: .some(nil))
        XCTAssertNotNil(PrimerCheckoutColors.borderDefault(tokens: tokens))
    }

    func testBorderErrorWithValue() {
        let tokens = MockDesignTokens(primerColorBorderOutlinedError: Color.pink)
        XCTAssertEqual(PrimerCheckoutColors.borderError(tokens: tokens), Color.pink)
    }

    func testBorderErrorWithNil() {
        let tokens = MockDesignTokens(primerColorBorderOutlinedError: .some(nil))
        XCTAssertEqual(PrimerCheckoutColors.borderError(tokens: tokens), .red)
    }

    func testBorderFocusWithValue() {
        let tokens = MockDesignTokens(primerColorBorderOutlinedFocus: Color.cyan)
        XCTAssertEqual(PrimerCheckoutColors.borderFocus(tokens: tokens), Color.cyan)
    }

    func testBorderFocusWithNil() {
        let tokens = MockDesignTokens(primerColorBorderOutlinedFocus: .some(nil))
        XCTAssertEqual(PrimerCheckoutColors.borderFocus(tokens: tokens), .blue)
    }

    // MARK: - Background Colors

    func testBackgroundWithValue() {
        let tokens = MockDesignTokens(primerColorBackground: Color.yellow)
        XCTAssertEqual(PrimerCheckoutColors.background(tokens: tokens), Color.yellow)
    }

    func testBackgroundWithNil() {
        let tokens = MockDesignTokens(primerColorBackground: .some(nil))
        XCTAssertEqual(PrimerCheckoutColors.background(tokens: tokens), .white)
    }

    // MARK: - Gray Scale Colors

    func testGray100WithValue() {
        let tokens = MockDesignTokens(primerColorGray100: Color.gray)
        XCTAssertEqual(PrimerCheckoutColors.gray100(tokens: tokens), Color.gray)
    }

    func testGray100WithNil() {
        let tokens = MockDesignTokens(primerColorGray100: .some(nil))
        XCTAssertNotNil(PrimerCheckoutColors.gray100(tokens: tokens))
    }

    func testGray200WithValue() {
        let tokens = MockDesignTokens(primerColorGray200: Color.gray)
        XCTAssertEqual(PrimerCheckoutColors.gray200(tokens: tokens), Color.gray)
    }

    func testGray200WithNil() {
        let tokens = MockDesignTokens(primerColorGray200: .some(nil))
        XCTAssertNotNil(PrimerCheckoutColors.gray200(tokens: tokens))
    }

    func testGray300WithValue() {
        let tokens = MockDesignTokens(primerColorGray300: Color.gray)
        XCTAssertEqual(PrimerCheckoutColors.gray300(tokens: tokens), Color.gray)
    }

    func testGray300WithNil() {
        let tokens = MockDesignTokens(primerColorGray300: .some(nil))
        XCTAssertNotNil(PrimerCheckoutColors.gray300(tokens: tokens))
    }

    // MARK: - Semantic UI Colors (no token mapping)

    func testWhite() {
        XCTAssertEqual(PrimerCheckoutColors.white(tokens: nil), .white)
    }

    func testGray() {
        XCTAssertEqual(PrimerCheckoutColors.gray(tokens: nil), .gray)
    }

    func testBlue() {
        XCTAssertEqual(PrimerCheckoutColors.blue(tokens: nil), .blue)
    }

    func testGreen() {
        XCTAssertEqual(PrimerCheckoutColors.green(tokens: nil), .green)
    }

    func testOrange() {
        XCTAssertEqual(PrimerCheckoutColors.orange(tokens: nil), .orange)
    }

    func testPrimary() {
        XCTAssertEqual(PrimerCheckoutColors.primary(tokens: nil), .primary)
    }

    func testSecondary() {
        XCTAssertEqual(PrimerCheckoutColors.secondary(tokens: nil), .secondary)
    }

    func testClear() {
        XCTAssertEqual(PrimerCheckoutColors.clear(tokens: nil), .clear)
    }
}

// MARK: - Mock Design Tokens

private func MockDesignTokens(
    primerColorTextPrimary: Color?? = .none,
    primerColorTextSecondary: Color?? = .none,
    primerColorTextNegative: Color?? = .none,
    primerColorIconNegative: Color?? = .none,
    primerColorBorderOutlinedDefault: Color?? = .none,
    primerColorBorderOutlinedError: Color?? = .none,
    primerColorBorderOutlinedFocus: Color?? = .none,
    primerColorBackground: Color?? = .none,
    primerColorGray100: Color?? = .none,
    primerColorGray200: Color?? = .none,
    primerColorGray300: Color?? = .none,
    primerColorTextPlaceholder: Color?? = .none,
    primerColorIconPositive: Color?? = .none
) -> DesignTokens {
    // Create base DesignTokens from empty JSON
    let jsonData = "{}".data(using: .utf8)!
    let tokens = try! JSONDecoder().decode(DesignTokens.self, from: jsonData)

    // Set test values (explicitly handling nil to override defaults)
    // Using double optional pattern: .none means "don't set", .some(nil) means "set to nil", .some(value) means "set to value"
    if let value = primerColorTextPrimary { tokens.primerColorTextPrimary = value }
    if let value = primerColorTextSecondary { tokens.primerColorTextSecondary = value }
    if let value = primerColorTextNegative { tokens.primerColorTextNegative = value }
    if let value = primerColorIconNegative { tokens.primerColorIconNegative = value }
    if let value = primerColorBorderOutlinedDefault { tokens.primerColorBorderOutlinedDefault = value }
    if let value = primerColorBorderOutlinedError { tokens.primerColorBorderOutlinedError = value }
    if let value = primerColorBorderOutlinedFocus { tokens.primerColorBorderOutlinedFocus = value }
    if let value = primerColorBackground { tokens.primerColorBackground = value }
    if let value = primerColorGray100 { tokens.primerColorGray100 = value }
    if let value = primerColorGray200 { tokens.primerColorGray200 = value }
    if let value = primerColorGray300 { tokens.primerColorGray300 = value }
    if let value = primerColorTextPlaceholder { tokens.primerColorTextPlaceholder = value }
    if let value = primerColorIconPositive { tokens.primerColorIconPositive = value }

    return tokens
}
