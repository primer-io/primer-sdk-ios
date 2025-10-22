//
//  PrimerInputFieldStylesTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

@available(iOS 15.0, *)
class PrimerInputFieldStylesTests: XCTestCase {

    // MARK: - Border Color Tests

    func testBorderColorWhenError() {
        // When there's an error message, should return error border color
        let color = primerInputBorderColor(
            errorMessage: "Error",
            isFocused: false,
            styling: nil,
            tokens: nil
        )

        XCTAssertEqual(color, Color.red)
    }

    func testBorderColorWhenFocused() {
        // When focused and no error, should return focus border color
        let color = primerInputBorderColor(
            errorMessage: nil,
            isFocused: true,
            styling: nil,
            tokens: nil
        )

        XCTAssertEqual(color, Color.blue)
    }

    func testBorderColorWhenDefault() {
        // When not focused and no error, should return default border color
        let color = primerInputBorderColor(
            errorMessage: nil,
            isFocused: false,
            styling: nil,
            tokens: nil
        )

        XCTAssertEqual(color, PrimerCheckoutColors.gray100(tokens: nil))
    }

    func testBorderColorWithCustomStyling() {
        // When custom styling is provided, should use it
        let styling = PrimerFieldStyling(
            borderColor: Color.green,
            focusedBorderColor: Color.orange,
            errorBorderColor: Color.purple
        )

        // Error state
        let errorColor = primerInputBorderColor(
            errorMessage: "Error",
            isFocused: false,
            styling: styling,
            tokens: nil
        )
        XCTAssertEqual(errorColor, Color.purple)

        // Focused state
        let focusedColor = primerInputBorderColor(
            errorMessage: nil,
            isFocused: true,
            styling: styling,
            tokens: nil
        )
        XCTAssertEqual(focusedColor, Color.orange)

        // Default state
        let defaultColor = primerInputBorderColor(
            errorMessage: nil,
            isFocused: false,
            styling: styling,
            tokens: nil
        )
        XCTAssertEqual(defaultColor, Color.green)
    }

    func testBorderColorWithTokens() {
        // When tokens are provided, should use them
        let tokens = MockDesignTokens(
            primerColorBorderOutlinedError: Color.pink,
            primerColorBorderOutlinedFocus: Color.cyan,
            primerColorBorderOutlinedDefault: Color.gray
        )

        // Error state
        let errorColor = primerInputBorderColor(
            errorMessage: "Error",
            isFocused: false,
            styling: nil,
            tokens: tokens
        )
        XCTAssertEqual(errorColor, Color.pink)

        // Focused state
        let focusedColor = primerInputBorderColor(
            errorMessage: nil,
            isFocused: true,
            styling: nil,
            tokens: tokens
        )
        XCTAssertEqual(focusedColor, Color.cyan)

        // Default state
        let defaultColor = primerInputBorderColor(
            errorMessage: nil,
            isFocused: false,
            styling: nil,
            tokens: tokens
        )
        XCTAssertEqual(defaultColor, Color.gray)
    }

    func testBorderColorPriority() {
        // Styling should take priority over tokens
        let styling = PrimerFieldStyling(errorBorderColor: Color.purple)
        let tokens = MockDesignTokens(primerColorBorderOutlinedError: Color.pink)

        let color = primerInputBorderColor(
            errorMessage: "Error",
            isFocused: false,
            styling: styling,
            tokens: tokens
        )

        XCTAssertEqual(color, Color.purple) // Styling wins
    }

    func testBorderColorWithEmptyErrorMessage() {
        // Empty error message should be treated as no error
        let color = primerInputBorderColor(
            errorMessage: "",
            isFocused: false,
            styling: nil,
            tokens: nil
        )

        XCTAssertNotEqual(color, Color.red) // Should not use error color
    }

    func testBorderColorErrorTakesPrecedenceOverFocus() {
        // Error should take precedence over focus state
        let color = primerInputBorderColor(
            errorMessage: "Error",
            isFocused: true, // Even though focused
            styling: nil,
            tokens: nil
        )

        XCTAssertEqual(color, Color.red) // Should use error color, not focus color
    }
}

// MARK: - Mock Design Tokens

private func MockDesignTokens(
    primerColorBorderOutlinedError: Color?? = .none,
    primerColorBorderOutlinedFocus: Color?? = .none,
    primerColorBorderOutlinedDefault: Color?? = .none
) -> DesignTokens {
    // Create base DesignTokens from empty JSON
    let jsonData = "{}".data(using: .utf8)!
    let tokens = try! JSONDecoder().decode(DesignTokens.self, from: jsonData)

    // Set test values (double optional pattern to allow explicit nil)
    if let value = primerColorBorderOutlinedError { tokens.primerColorBorderOutlinedError = value }
    if let value = primerColorBorderOutlinedFocus { tokens.primerColorBorderOutlinedFocus = value }
    if let value = primerColorBorderOutlinedDefault { tokens.primerColorBorderOutlinedDefault = value }

    return tokens
}
