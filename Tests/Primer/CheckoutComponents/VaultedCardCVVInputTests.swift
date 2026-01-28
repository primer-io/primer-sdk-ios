//
//  VaultedCardCVVInputTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

// MARK: - CVV Filtering Logic Tests

/// Tests for the CVV input filtering logic used in VaultedCardCVVInput.
/// The filtering logic ensures only numeric characters are accepted and the length is limited
/// based on the card network's expected CVV length.
@available(iOS 15.0, *)
final class CVVFilteringLogicTests: XCTestCase {

    // MARK: - Helpers

    /// Mirrors the filtering logic from VaultedCardCVVInput.filteredCvvBinding
    private func filterCvv(_ input: String, expectedLength: Int) -> String {
        String(input.filter(\.isNumber).prefix(expectedLength))
    }

    // MARK: - Numeric Input Tests

    func test_filteredCvv_numericInput_passesThrough() {
        XCTAssertEqual(filterCvv("123", expectedLength: 3), "123")
    }

    func test_filteredCvv_numericInputFourDigits_passesThrough() {
        XCTAssertEqual(filterCvv("1234", expectedLength: 4), "1234")
    }

    // MARK: - Non-Numeric Input Tests

    func test_filteredCvv_alphabeticInput_filtersToEmpty() {
        XCTAssertEqual(filterCvv("abc", expectedLength: 3), "")
    }

    func test_filteredCvv_mixedInput_keepsOnlyDigits() {
        XCTAssertEqual(filterCvv("1a2b3c", expectedLength: 3), "123")
    }

    func test_filteredCvv_specialCharacters_filtered() {
        XCTAssertEqual(filterCvv("12!", expectedLength: 3), "12")
    }

    func test_filteredCvv_spaces_filtered() {
        XCTAssertEqual(filterCvv("1 2 3", expectedLength: 3), "123")
    }

    // MARK: - Length Limiting Tests

    func test_filteredCvv_exceedsMaxLength_truncated() {
        XCTAssertEqual(filterCvv("12345", expectedLength: 3), "123")
    }

    func test_filteredCvv_exceedsMaxLengthFourDigit_truncated() {
        XCTAssertEqual(filterCvv("12345", expectedLength: 4), "1234")
    }

    func test_filteredCvv_exactLength_unchanged() {
        XCTAssertEqual(filterCvv("123", expectedLength: 3), "123")
    }

    func test_filteredCvv_lessThanMaxLength_unchanged() {
        XCTAssertEqual(filterCvv("12", expectedLength: 3), "12")
    }

    // MARK: - Edge Cases

    func test_filteredCvv_emptyInput_remainsEmpty() {
        XCTAssertEqual(filterCvv("", expectedLength: 3), "")
    }

    func test_filteredCvv_allNonNumeric_returnsEmpty() {
        XCTAssertEqual(filterCvv("abc!@#", expectedLength: 3), "")
    }

    func test_filteredCvv_mixedWithExcessLength_filtersAndTruncates() {
        // "1a2b3c4d5e" -> "12345" -> "123"
        XCTAssertEqual(filterCvv("1a2b3c4d5e", expectedLength: 3), "123")
    }
}

// MARK: - Expected CVV Length Tests

/// Tests for the expected CVV length calculation based on card network.
/// Different card networks require different CVV lengths (3 or 4 digits).
@available(iOS 15.0, *)
final class CVVExpectedLengthTests: XCTestCase {

    // MARK: - Helpers

    /// Mirrors the expectedCvvLength logic from VaultedCardCVVInput
    private func expectedCvvLength(for network: CardNetwork) -> Int {
        network.validation?.code.length ?? 3
    }

    // MARK: - Standard 3-Digit CVV Networks

    func test_expectedCvvLength_visa_returns3() {
        XCTAssertEqual(expectedCvvLength(for: .visa), 3)
    }

    func test_expectedCvvLength_mastercard_returns3() {
        XCTAssertEqual(expectedCvvLength(for: .masterCard), 3)
    }

    func test_expectedCvvLength_discover_returns3() {
        XCTAssertEqual(expectedCvvLength(for: .discover), 3)
    }

    func test_expectedCvvLength_jcb_returns3() {
        XCTAssertEqual(expectedCvvLength(for: .jcb), 3)
    }

    func test_expectedCvvLength_diners_returns3() {
        XCTAssertEqual(expectedCvvLength(for: .diners), 3)
    }

    func test_expectedCvvLength_maestro_returns3() {
        XCTAssertEqual(expectedCvvLength(for: .maestro), 3)
    }

    // MARK: - 4-Digit CVV Networks

    func test_expectedCvvLength_amex_returns4() {
        XCTAssertEqual(expectedCvvLength(for: .amex), 4)
    }

    // MARK: - Networks Without Validation (Default to 3)

    func test_expectedCvvLength_unknown_returnsDefault3() {
        XCTAssertEqual(expectedCvvLength(for: .unknown), 3)
    }

    func test_expectedCvvLength_bancontact_returnsDefault3() {
        // Bancontact has nil validation, should default to 3
        XCTAssertEqual(expectedCvvLength(for: .bancontact), 3)
    }

    func test_expectedCvvLength_cartesBancaires_returnsDefault3() {
        // Cartes Bancaires has nil validation, should default to 3
        XCTAssertEqual(expectedCvvLength(for: .cartesBancaires), 3)
    }
}

// MARK: - CVV Placeholder Tests

/// Tests for CVV placeholder string generation.
/// The placeholder should show the expected number of placeholder digits.
@available(iOS 15.0, *)
final class CVVPlaceholderTests: XCTestCase {

    // MARK: - Helpers

    /// Mirrors the cvvPlaceholder logic from VaultedCardCVVInput
    private func cvvPlaceholder(for network: CardNetwork) -> String {
        let expectedLength = network.validation?.code.length ?? 3
        return String(repeating: CheckoutComponentsStrings.cvvPlaceholderDigit, count: expectedLength)
    }

    // MARK: - Tests

    func test_cvvPlaceholder_visa_returnsThreePlaceholders() {
        let placeholder = cvvPlaceholder(for: .visa)
        XCTAssertEqual(placeholder.count, 3)
    }

    func test_cvvPlaceholder_amex_returnsFourPlaceholders() {
        let placeholder = cvvPlaceholder(for: .amex)
        XCTAssertEqual(placeholder.count, 4)
    }

    func test_cvvPlaceholder_unknown_returnsThreePlaceholders() {
        let placeholder = cvvPlaceholder(for: .unknown)
        XCTAssertEqual(placeholder.count, 3)
    }
}

// MARK: - CVV Border Color Logic Tests

/// Tests for the CVV input border color determination logic.
/// Border color changes based on error state, focus state, and default state.
@available(iOS 15.0, *)
final class CVVBorderColorLogicTests: XCTestCase {

    // MARK: - Border State Enum

    enum BorderState: Equatable {
        case error
        case focus
        case defaultState
    }

    // MARK: - Helpers

    /// Mirrors the cvvBorderColor logic from VaultedCardCVVInput
    private func borderState(hasError: Bool, isFocused: Bool) -> BorderState {
        if hasError {
            return .error
        } else if isFocused {
            return .focus
        } else {
            return .defaultState
        }
    }

    // MARK: - Tests

    func test_cvvBorderState_hasError_returnsError() {
        XCTAssertEqual(borderState(hasError: true, isFocused: false), .error)
    }

    func test_cvvBorderState_noErrorAndFocused_returnsFocus() {
        XCTAssertEqual(borderState(hasError: false, isFocused: true), .focus)
    }

    func test_cvvBorderState_noErrorNotFocused_returnsDefault() {
        XCTAssertEqual(borderState(hasError: false, isFocused: false), .defaultState)
    }

    func test_cvvBorderState_errorTakesPrecedence_overFocus() {
        // Error should take precedence even when focused
        XCTAssertEqual(borderState(hasError: true, isFocused: true), .error)
    }
}
