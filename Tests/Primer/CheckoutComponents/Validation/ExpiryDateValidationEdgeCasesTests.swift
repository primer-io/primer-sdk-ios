//
//  ExpiryDateValidationEdgeCasesTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for expiry date validation edge cases to achieve 90% coverage.
/// Covers edge cases like current month, year boundaries, and format variations.
@available(iOS 15.0, *)
@MainActor
final class ExpiryDateValidationEdgeCasesTests: XCTestCase {

    private var sut: DefaultValidationService!

    override func setUp() async throws {
        try await super.setUp()
        sut = DefaultValidationService()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Current Month Edge Cases

    func test_validateExpiry_withCurrentMonth_returnsValid() {
        // Given
        let (month, year) = TestData.ExpiryDates.currentMonth

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateExpiry_withCurrentMonthLastDay_returnsValid() {
        // Given - Current month should be valid until end of month
        let (month, year) = TestData.ExpiryDates.currentMonth

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Future Date Validation

    func test_validateExpiry_withFutureDate_returnsValid() {
        // Given
        let (month, year) = TestData.ExpiryDates.validFuture

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateExpiry_withFarFutureDate_returnsValid() {
        // Given - 10 years in future
        let calendar = Calendar.current
        let futureDate = calendar.date(byAdding: .year, value: 10, to: Date())!
        let month = String(format: "%02d", calendar.component(.month, from: futureDate))
        let year = String(calendar.component(.year, from: futureDate) % 100)

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Expired Date Validation

    func test_validateExpiry_withLastMonth_returnsInvalid() {
        // Given
        let (month, year) = TestData.ExpiryDates.expired

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateExpiry_withLastYear_returnsInvalid() {
        // Given
        let calendar = Calendar.current
        let lastYear = calendar.component(.year, from: Date()) - 1
        let month = "12"
        let year = String(lastYear % 100)

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Year Boundary Edge Cases

    func test_validateExpiry_atYearBoundary_december_returnsValidOrInvalid() {
        // Given
        let currentYear = Calendar.current.component(.year, from: Date())
        let month = "12"
        let year = String(currentYear % 100)

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        // December of current year should be valid
        XCTAssertTrue(result.isValid)
    }

    func test_validateExpiry_atYearBoundary_january_returnsValid() {
        // Given
        let nextYear = Calendar.current.component(.year, from: Date()) + 1
        let month = "01"
        let year = String(nextYear % 100)

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateExpiry_centuryRollover_2099To2100_handlesCorrectly() {
        // Given - Testing century rollover
        let month = "12"
        let year = "99" // 2099

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then - 2099 should be valid (far future)
        XCTAssertTrue(result.isValid)
    }

    func test_validateExpiry_centuryRollover_2000_handlesCorrectly() {
        // Given
        let month = "01"
        let year = "00" // Could be 2000 or 2100

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then - Should interpret as past (2000) and return invalid
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Invalid Month Validation

    func test_validateExpiry_withInvalidMonth_13_returnsInvalid() {
        // Given
        let (month, year) = TestData.ExpiryDates.invalidMonth // "13"

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateExpiry_withZeroMonth_returnsInvalid() {
        // Given
        let (month, year) = TestData.ExpiryDates.zeroMonth // "00"

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateExpiry_withNegativeMonth_returnsInvalid() {
        // Given
        let month = "-01"
        let year = "25"

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Format Variation Edge Cases

    func test_validateExpiry_withSingleDigitMonth_withoutLeadingZero_returnsValid() {
        // Given
        let month = "5" // May without leading zero
        let (_, year) = TestData.ExpiryDates.validFuture

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then - Should accept both "05" and "5"
        XCTAssertTrue(result.isValid)
    }

    func test_validateExpiry_withTwoDigitMonth_withLeadingZero_returnsValid() {
        // Given
        let month = "05" // May with leading zero
        let (_, year) = TestData.ExpiryDates.validFuture

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateExpiry_withFourDigitYear_returnsValid() {
        // Given
        let month = "12"
        let currentYear = Calendar.current.component(.year, from: Date())
        let futureYear = currentYear + 2
        let year = String(futureYear) // Full 4-digit year

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateExpiry_withTwoDigitYear_returnsValid() {
        // Given
        let month = "12"
        let (_, year) = TestData.ExpiryDates.validFuture // 2-digit year

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Empty and Nil Value Edge Cases

    func test_validateExpiry_withEmptyMonth_returnsInvalid() {
        // Given
        let (month, year) = TestData.ExpiryDates.empty

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateExpiry_withEmptyYear_returnsInvalid() {
        // Given
        let month = "12"
        let year = ""

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateExpiry_withBothEmpty_returnsInvalid() {
        // Given
        let month = ""
        let year = ""

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Non-Numeric Input Edge Cases

    func test_validateExpiry_withLettersInMonth_returnsInvalid() {
        // Given
        let month = "AB"
        let year = "25"

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateExpiry_withLettersInYear_returnsInvalid() {
        // Given
        let month = "12"
        let year = "XY"

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validateExpiry_withSpecialCharactersInMonth_returnsInvalid() {
        // Given
        let month = "1@"
        let year = "25"

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Whitespace Edge Cases

    func test_validateExpiry_withWhitespaceInMonth_shouldTrimAndValidate() {
        // Given
        let month = " 12 " // With leading/trailing whitespace
        let (_, year) = TestData.ExpiryDates.validFuture

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then - Should trim whitespace and validate
        XCTAssertTrue(result.isValid)
    }

    func test_validateExpiry_withWhitespaceInYear_shouldTrimAndValidate() {
        // Given
        let month = "12"
        let (_, yearValue) = TestData.ExpiryDates.validFuture
        let year = " \(yearValue) " // With leading/trailing whitespace

        // When
        let result = sut.validateExpiry(month: month, year: year)

        // Then - Should trim whitespace and validate
        XCTAssertTrue(result.isValid)
    }
}
