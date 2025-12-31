//
//  PrimerLayoutTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for PrimerLayout structs including spacing, size, radius, and component dimensions.
@available(iOS 15.0, *)
final class PrimerLayoutTests: XCTestCase {

    // MARK: - PrimerSpacing Tests

    func test_spacing_xxsmall_withNilTokens_returnsFallback() {
        XCTAssertEqual(PrimerSpacing.xxsmall(tokens: nil), 2)
    }

    func test_spacing_xsmall_withNilTokens_returnsFallback() {
        XCTAssertEqual(PrimerSpacing.xsmall(tokens: nil), 4)
    }

    func test_spacing_small_withNilTokens_returnsFallback() {
        XCTAssertEqual(PrimerSpacing.small(tokens: nil), 8)
    }

    func test_spacing_medium_withNilTokens_returnsFallback() {
        XCTAssertEqual(PrimerSpacing.medium(tokens: nil), 12)
    }

    func test_spacing_large_withNilTokens_returnsFallback() {
        XCTAssertEqual(PrimerSpacing.large(tokens: nil), 16)
    }

    func test_spacing_xlarge_withNilTokens_returnsFallback() {
        XCTAssertEqual(PrimerSpacing.xlarge(tokens: nil), 20)
    }

    func test_spacing_xxlarge_withNilTokens_returnsFallback() {
        XCTAssertEqual(PrimerSpacing.xxlarge(tokens: nil), 24)
    }

    // MARK: - PrimerSize Tests

    func test_size_small_withNilTokens_returnsFallback() {
        XCTAssertEqual(PrimerSize.small(tokens: nil), 16)
    }

    func test_size_medium_withNilTokens_returnsFallback() {
        XCTAssertEqual(PrimerSize.medium(tokens: nil), 20)
    }

    func test_size_large_withNilTokens_returnsFallback() {
        XCTAssertEqual(PrimerSize.large(tokens: nil), 24)
    }

    func test_size_xlarge_withNilTokens_returnsFallback() {
        XCTAssertEqual(PrimerSize.xlarge(tokens: nil), 32)
    }

    func test_size_xxlarge_withNilTokens_returnsFallback() {
        XCTAssertEqual(PrimerSize.xxlarge(tokens: nil), 44)
    }

    func test_size_xxxlarge_withNilTokens_returnsFallback() {
        XCTAssertEqual(PrimerSize.xxxlarge(tokens: nil), 56)
    }

    // MARK: - PrimerRadius Tests

    func test_radius_xsmall_withNilTokens_returnsFallback() {
        XCTAssertEqual(PrimerRadius.xsmall(tokens: nil), 2)
    }

    func test_radius_small_withNilTokens_returnsFallback() {
        XCTAssertEqual(PrimerRadius.small(tokens: nil), 4)
    }

    func test_radius_medium_withNilTokens_returnsFallback() {
        XCTAssertEqual(PrimerRadius.medium(tokens: nil), 8)
    }

    func test_radius_large_withNilTokens_returnsFallback() {
        XCTAssertEqual(PrimerRadius.large(tokens: nil), 12)
    }

    // MARK: - PrimerComponentHeight Tests

    func test_componentHeight_label_returnsExpectedValue() {
        XCTAssertEqual(PrimerComponentHeight.label, 16)
    }

    func test_componentHeight_errorMessage_returnsExpectedValue() {
        XCTAssertEqual(PrimerComponentHeight.errorMessage, 16)
    }

    func test_componentHeight_keyboardAccessory_returnsExpectedValue() {
        XCTAssertEqual(PrimerComponentHeight.keyboardAccessory, 44)
    }

    func test_componentHeight_paymentMethodCard_returnsExpectedValue() {
        XCTAssertEqual(PrimerComponentHeight.paymentMethodCard, 44)
    }

    func test_componentHeight_vaultedPaymentMethodCard_returnsExpectedValue() {
        XCTAssertEqual(PrimerComponentHeight.vaultedPaymentMethodCard, 64)
    }

    func test_componentHeight_vaultedPaymentMethodCardContentRow_returnsExpectedValue() {
        XCTAssertEqual(PrimerComponentHeight.vaultedPaymentMethodCardContentRow, 40)
    }

    func test_componentHeight_progressIndicator_returnsExpectedValue() {
        XCTAssertEqual(PrimerComponentHeight.progressIndicator, 56)
    }

    func test_componentHeight_emptyStateMinHeight_returnsExpectedValue() {
        XCTAssertEqual(PrimerComponentHeight.emptyStateMinHeight, 200)
    }

    func test_componentHeight_emptyStateTopPadding_returnsExpectedValue() {
        XCTAssertEqual(PrimerComponentHeight.emptyStateTopPadding, 100)
    }

    // MARK: - PrimerComponentWidth Tests

    func test_componentWidth_paymentMethodIcon_returnsExpectedValue() {
        XCTAssertEqual(PrimerComponentWidth.paymentMethodIcon, 32)
    }

    func test_componentWidth_cvvFieldMax_returnsExpectedValue() {
        XCTAssertEqual(PrimerComponentWidth.cvvFieldMax, 120)
    }

    // MARK: - PrimerBorderWidth Tests

    func test_borderWidth_thin_returnsExpectedValue() {
        XCTAssertEqual(PrimerBorderWidth.thin, 0.5)
    }

    func test_borderWidth_standard_returnsExpectedValue() {
        XCTAssertEqual(PrimerBorderWidth.standard, 1)
    }

    func test_borderWidth_selected_returnsExpectedValue() {
        XCTAssertEqual(PrimerBorderWidth.selected, 2)
    }

    // MARK: - PrimerScale Tests

    func test_scale_large_returnsExpectedValue() {
        XCTAssertEqual(PrimerScale.large, 2.0)
    }

    func test_scale_small_returnsExpectedValue() {
        XCTAssertEqual(PrimerScale.small, 0.8)
    }

    // MARK: - PrimerCardNetworkSelector Tests

    func test_cardNetworkSelector_badgeWidth_returnsExpectedValue() {
        XCTAssertEqual(PrimerCardNetworkSelector.badgeWidth, 28)
    }

    func test_cardNetworkSelector_badgeHeight_returnsExpectedValue() {
        XCTAssertEqual(PrimerCardNetworkSelector.badgeHeight, 20)
    }

    func test_cardNetworkSelector_buttonFrameWidth_returnsExpectedValue() {
        XCTAssertEqual(PrimerCardNetworkSelector.buttonFrameWidth, 34)
    }

    func test_cardNetworkSelector_buttonFrameHeight_returnsExpectedValue() {
        XCTAssertEqual(PrimerCardNetworkSelector.buttonFrameHeight, 26)
    }

    func test_cardNetworkSelector_buttonTotalWidth_returnsExpectedValue() {
        XCTAssertEqual(PrimerCardNetworkSelector.buttonTotalWidth, 36)
    }

    func test_cardNetworkSelector_selectedBorderHeight_returnsExpectedValue() {
        XCTAssertEqual(PrimerCardNetworkSelector.selectedBorderHeight, 28)
    }

    func test_cardNetworkSelector_chevronSize_returnsExpectedValue() {
        XCTAssertEqual(PrimerCardNetworkSelector.chevronSize, 20)
    }

    func test_cardNetworkSelector_chevronFontSize_returnsExpectedValue() {
        XCTAssertEqual(PrimerCardNetworkSelector.chevronFontSize, 10)
    }

    // MARK: - PrimerAnimationDuration Tests

    func test_animationDuration_focusDelay_returnsExpectedValue() {
        XCTAssertEqual(PrimerAnimationDuration.focusDelay, 0.3)
    }

    // MARK: - Spacing with Tokens Tests

    func test_spacing_withTokens_usesTokenValues() {
        // Given
        let tokens = DesignTokens()

        // When/Then - These should use token values if available, otherwise fallback
        let xxsmall = PrimerSpacing.xxsmall(tokens: tokens)
        let xsmall = PrimerSpacing.xsmall(tokens: tokens)
        let small = PrimerSpacing.small(tokens: tokens)
        let medium = PrimerSpacing.medium(tokens: tokens)
        let large = PrimerSpacing.large(tokens: tokens)
        let xlarge = PrimerSpacing.xlarge(tokens: tokens)
        let xxlarge = PrimerSpacing.xxlarge(tokens: tokens)

        // All values should be positive
        XCTAssertGreaterThan(xxsmall, 0)
        XCTAssertGreaterThan(xsmall, 0)
        XCTAssertGreaterThan(small, 0)
        XCTAssertGreaterThan(medium, 0)
        XCTAssertGreaterThan(large, 0)
        XCTAssertGreaterThan(xlarge, 0)
        XCTAssertGreaterThan(xxlarge, 0)
    }

    func test_size_withTokens_usesTokenValues() {
        // Given
        let tokens = DesignTokens()

        // When/Then - These should use token values if available, otherwise fallback
        let small = PrimerSize.small(tokens: tokens)
        let medium = PrimerSize.medium(tokens: tokens)
        let large = PrimerSize.large(tokens: tokens)
        let xlarge = PrimerSize.xlarge(tokens: tokens)
        let xxlarge = PrimerSize.xxlarge(tokens: tokens)
        let xxxlarge = PrimerSize.xxxlarge(tokens: tokens)

        // All values should be positive
        XCTAssertGreaterThan(small, 0)
        XCTAssertGreaterThan(medium, 0)
        XCTAssertGreaterThan(large, 0)
        XCTAssertGreaterThan(xlarge, 0)
        XCTAssertGreaterThan(xxlarge, 0)
        XCTAssertGreaterThan(xxxlarge, 0)
    }

    func test_radius_withTokens_usesTokenValues() {
        // Given
        let tokens = DesignTokens()

        // When/Then - These should use token values if available, otherwise fallback
        let xsmall = PrimerRadius.xsmall(tokens: tokens)
        let small = PrimerRadius.small(tokens: tokens)
        let medium = PrimerRadius.medium(tokens: tokens)
        let large = PrimerRadius.large(tokens: tokens)

        // All values should be positive
        XCTAssertGreaterThan(xsmall, 0)
        XCTAssertGreaterThan(small, 0)
        XCTAssertGreaterThan(medium, 0)
        XCTAssertGreaterThan(large, 0)
    }
}
