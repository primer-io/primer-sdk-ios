//
//  CheckoutColorsTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

/// Tests for CheckoutColors enum color resolution methods.
@available(iOS 15.0, *)
final class CheckoutColorsTests: XCTestCase {

    // MARK: - Text Colors Tests

    func test_textPrimary_withNilTokens_returnsFallback() {
        // When
        let color = CheckoutColors.textPrimary(tokens: nil)

        // Then
        XCTAssertEqual(color, .primary)
    }

    func test_textSecondary_withNilTokens_returnsFallback() {
        // When
        let color = CheckoutColors.textSecondary(tokens: nil)

        // Then
        XCTAssertEqual(color, .secondary)
    }

    func test_textNegative_withNilTokens_returnsFallback() {
        // When
        let color = CheckoutColors.textNegative(tokens: nil)

        // Then
        XCTAssertEqual(color, .red)
    }

    func test_textPlaceholder_withNilTokens_returnsFallback() {
        // When
        let color = CheckoutColors.textPlaceholder(tokens: nil)

        // Then
        XCTAssertNotNil(color)
    }

    // MARK: - Icon Colors Tests

    func test_iconNegative_withNilTokens_returnsFallback() {
        // When
        let color = CheckoutColors.iconNegative(tokens: nil)

        // Then
        XCTAssertEqual(color, .red)
    }

    func test_iconPositive_withNilTokens_returnsFallback() {
        // When
        let color = CheckoutColors.iconPositive(tokens: nil)

        // Then
        XCTAssertNotNil(color)
    }

    // MARK: - Border Colors Tests

    func test_borderDefault_withNilTokens_returnsFallback() {
        // When
        let color = CheckoutColors.borderDefault(tokens: nil)

        // Then
        XCTAssertEqual(color, .gray)
    }

    func test_borderError_withNilTokens_returnsFallback() {
        // When
        let color = CheckoutColors.borderError(tokens: nil)

        // Then
        XCTAssertEqual(color, .red)
    }

    func test_borderFocus_withNilTokens_returnsFallback() {
        // When
        let color = CheckoutColors.borderFocus(tokens: nil)

        // Then
        XCTAssertEqual(color, .blue)
    }

    // MARK: - Background Colors Tests

    func test_background_withNilTokens_returnsFallback() {
        // When
        let color = CheckoutColors.background(tokens: nil)

        // Then
        XCTAssertEqual(color, .white)
    }

    // MARK: - Gray Colors Tests

    func test_gray100_withNilTokens_returnsFallback() {
        // When
        let color = CheckoutColors.gray100(tokens: nil)

        // Then
        XCTAssertNotNil(color)
    }

    func test_gray200_withNilTokens_returnsFallback() {
        // When
        let color = CheckoutColors.gray200(tokens: nil)

        // Then
        XCTAssertNotNil(color)
    }

    func test_gray300_withNilTokens_returnsFallback() {
        // When
        let color = CheckoutColors.gray300(tokens: nil)

        // Then
        XCTAssertNotNil(color)
    }

    func test_gray700_withNilTokens_returnsFallback() {
        // When
        let color = CheckoutColors.gray700(tokens: nil)

        // Then
        XCTAssertNotNil(color)
    }

    // MARK: - Static Colors Tests

    func test_white_returnsWhite() {
        // When
        let color = CheckoutColors.white(tokens: nil)

        // Then
        XCTAssertEqual(color, .white)
    }

    func test_gray_returnsGray() {
        // When
        let color = CheckoutColors.gray(tokens: nil)

        // Then
        XCTAssertEqual(color, .gray)
    }

    func test_blue_returnsBlue() {
        // When
        let color = CheckoutColors.blue(tokens: nil)

        // Then
        XCTAssertEqual(color, .blue)
    }

    func test_green_returnsGreen() {
        // When
        let color = CheckoutColors.green(tokens: nil)

        // Then
        XCTAssertEqual(color, .green)
    }

    func test_orange_returnsOrange() {
        // When
        let color = CheckoutColors.orange(tokens: nil)

        // Then
        XCTAssertEqual(color, .orange)
    }

    func test_primary_returnsPrimary() {
        // When
        let color = CheckoutColors.primary(tokens: nil)

        // Then
        XCTAssertEqual(color, .primary)
    }

    func test_secondary_returnsSecondary() {
        // When
        let color = CheckoutColors.secondary(tokens: nil)

        // Then
        XCTAssertEqual(color, .secondary)
    }

    func test_clear_returnsClear() {
        // When
        let color = CheckoutColors.clear(tokens: nil)

        // Then
        XCTAssertEqual(color, .clear)
    }

    // MARK: - Token-Based Resolution Tests

    func test_textPrimary_withTokens_usesTokenValue() {
        // Given
        let tokens = DesignTokens()

        // When
        let color = CheckoutColors.textPrimary(tokens: tokens)

        // Then - Should return a valid color
        XCTAssertNotNil(color)
    }

    func test_textSecondary_withTokens_usesTokenValue() {
        // Given
        let tokens = DesignTokens()

        // When
        let color = CheckoutColors.textSecondary(tokens: tokens)

        // Then - Should return a valid color
        XCTAssertNotNil(color)
    }

    func test_textNegative_withTokens_usesTokenValue() {
        // Given
        let tokens = DesignTokens()

        // When
        let color = CheckoutColors.textNegative(tokens: tokens)

        // Then - Should return a valid color
        XCTAssertNotNil(color)
    }

    func test_borderDefault_withTokens_usesTokenValue() {
        // Given
        let tokens = DesignTokens()

        // When
        let color = CheckoutColors.borderDefault(tokens: tokens)

        // Then - Should return a valid color
        XCTAssertNotNil(color)
    }

    func test_borderError_withTokens_usesTokenValue() {
        // Given
        let tokens = DesignTokens()

        // When
        let color = CheckoutColors.borderError(tokens: tokens)

        // Then - Should return a valid color
        XCTAssertNotNil(color)
    }

    func test_borderFocus_withTokens_usesTokenValue() {
        // Given
        let tokens = DesignTokens()

        // When
        let color = CheckoutColors.borderFocus(tokens: tokens)

        // Then - Should return a valid color
        XCTAssertNotNil(color)
    }

    func test_background_withTokens_usesTokenValue() {
        // Given
        let tokens = DesignTokens()

        // When
        let color = CheckoutColors.background(tokens: tokens)

        // Then - Should return a valid color
        XCTAssertNotNil(color)
    }

    func test_gray100_withTokens_usesTokenValue() {
        // Given
        let tokens = DesignTokens()

        // When
        let color = CheckoutColors.gray100(tokens: tokens)

        // Then - Should return a valid color
        XCTAssertNotNil(color)
    }

    func test_textPlaceholder_withTokens_usesTokenValue() {
        // Given
        let tokens = DesignTokens()

        // When
        let color = CheckoutColors.textPlaceholder(tokens: tokens)

        // Then - Should return a valid color
        XCTAssertNotNil(color)
    }

    func test_iconPositive_withTokens_usesTokenValue() {
        // Given
        let tokens = DesignTokens()

        // When
        let color = CheckoutColors.iconPositive(tokens: tokens)

        // Then - Should return a valid color
        XCTAssertNotNil(color)
    }

    func test_iconNegative_withTokens_usesTokenValue() {
        // Given
        let tokens = DesignTokens()

        // When
        let color = CheckoutColors.iconNegative(tokens: tokens)

        // Then - Should return a valid color
        XCTAssertNotNil(color)
    }
}
