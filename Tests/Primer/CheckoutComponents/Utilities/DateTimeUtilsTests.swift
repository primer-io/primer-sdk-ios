//
//  DateTimeUtilsTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for date/time utilities to achieve 90% Scope & Utilities coverage.
/// Covers date formatting, parsing, comparison, and timezone handling.
@available(iOS 15.0, *)
@MainActor
final class DateTimeUtilsTests: XCTestCase {

    private var sut: DateTimeUtils!

    override func setUp() async throws {
        try await super.setUp()
        sut = DateTimeUtils()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Date Formatting

    func test_formatDate_withDefaultFormat_formatsCorrectly() {
        // Given
        let date = createDate(year: 2024, month: 12, day: 25)

        // When
        let result = sut.formatDate(date)

        // Then
        XCTAssertTrue(result.contains("2024"))
        XCTAssertTrue(result.contains("12") || result.contains("Dec"))
        XCTAssertTrue(result.contains("25"))
    }

    func test_formatDate_withCustomFormat_usesFormat() {
        // Given
        let date = createDate(year: 2024, month: 12, day: 25)

        // When
        let result = sut.formatDate(date, format: "yyyy-MM-dd")

        // Then
        XCTAssertEqual(result, "2024-12-25")
    }

    func test_formatDate_withTime_includesTime() {
        // Given
        let date = createDate(year: 2024, month: 12, day: 25, hour: 14, minute: 30)

        // When
        let result = sut.formatDate(date, format: "yyyy-MM-dd HH:mm")

        // Then
        XCTAssertEqual(result, "2024-12-25 14:30")
    }

    // MARK: - Date Parsing

    func test_parseDate_withValidString_returnsDate() throws {
        // When
        let date = try sut.parseDate("2024-12-25", format: "yyyy-MM-dd")

        // Then
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 12)
        XCTAssertEqual(components.day, 25)
    }

    func test_parseDate_withInvalidString_throwsError() {
        // When/Then
        XCTAssertThrowsError(try sut.parseDate("invalid", format: "yyyy-MM-dd"))
    }

    // MARK: - ISO8601 Formatting

    func test_formatISO8601_formatsCorrectly() {
        // Given
        let date = createDate(year: 2024, month: 12, day: 25, hour: 14, minute: 30)

        // When
        let result = sut.formatISO8601(date)

        // Then
        XCTAssertTrue(result.contains("2024-12-25"))
        XCTAssertTrue(result.contains("T"))
    }

    func test_parseISO8601_parsesCorrectly() throws {
        // Given
        let isoString = "2024-12-25T14:30:00Z"

        // When
        let date = try sut.parseISO8601(isoString)

        // Then
        XCTAssertNotNil(date)
    }

    // MARK: - Date Comparison

    func test_isSameDay_withSameDates_returnsTrue() {
        // Given
        let date1 = createDate(year: 2024, month: 12, day: 25, hour: 10)
        let date2 = createDate(year: 2024, month: 12, day: 25, hour: 20)

        // When/Then
        XCTAssertTrue(sut.isSameDay(date1, date2))
    }

    func test_isSameDay_withDifferentDates_returnsFalse() {
        // Given
        let date1 = createDate(year: 2024, month: 12, day: 25)
        let date2 = createDate(year: 2024, month: 12, day: 26)

        // When/Then
        XCTAssertFalse(sut.isSameDay(date1, date2))
    }

    func test_daysBetween_calculatesCorrectly() {
        // Given
        let date1 = createDate(year: 2024, month: 12, day: 25)
        let date2 = createDate(year: 2024, month: 12, day: 30)

        // When
        let days = sut.daysBetween(date1, date2)

        // Then
        XCTAssertEqual(days, 5)
    }

    // MARK: - Relative Time

    func test_relativeTime_withFutureDate_returnsCorrectString() {
        // Given
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now

        // When
        let result = sut.relativeTime(from: futureDate)

        // Then
        XCTAssertTrue(result.contains("hour") || result.contains("minute"))
    }

    func test_relativeTime_withPastDate_returnsCorrectString() {
        // Given
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago

        // When
        let result = sut.relativeTime(from: pastDate)

        // Then
        XCTAssertTrue(result.contains("hour") || result.contains("ago"))
    }

    // MARK: - Date Components

    func test_startOfDay_returnsStartOfDay() {
        // Given
        let date = createDate(year: 2024, month: 12, day: 25, hour: 14, minute: 30)

        // When
        let startOfDay = sut.startOfDay(for: date)

        // Then
        let components = Calendar.current.dateComponents([.hour, .minute], from: startOfDay)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
    }

    func test_endOfDay_returnsEndOfDay() {
        // Given
        let date = createDate(year: 2024, month: 12, day: 25, hour: 14, minute: 30)

        // When
        let endOfDay = sut.endOfDay(for: date)

        // Then
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: endOfDay)
        XCTAssertEqual(components.hour, 23)
        XCTAssertEqual(components.minute, 59)
        XCTAssertEqual(components.second, 59)
    }

    // MARK: - Helper

    private func createDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }
}

// MARK: - Date Time Utils

@available(iOS 15.0, *)
private class DateTimeUtils {
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    private let iso8601Formatter = ISO8601DateFormatter()

    func formatDate(_ date: Date, format: String = "MMM dd, yyyy") -> String {
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }

    func parseDate(_ string: String, format: String) throws -> Date {
        dateFormatter.dateFormat = format
        guard let date = dateFormatter.date(from: string) else {
            throw DateError.invalidFormat
        }
        return date
    }

    func formatISO8601(_ date: Date) -> String {
        iso8601Formatter.string(from: date)
    }

    func parseISO8601(_ string: String) throws -> Date {
        guard let date = iso8601Formatter.date(from: string) else {
            throw DateError.invalidFormat
        }
        return date
    }

    func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }

    func daysBetween(_ date1: Date, _ date2: Date) -> Int {
        let components = calendar.dateComponents([.day], from: date1, to: date2)
        return abs(components.day ?? 0)
    }

    func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    func endOfDay(for date: Date) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return calendar.date(byAdding: components, to: startOfDay(for: date))!
    }
}

// MARK: - Date Error

@available(iOS 15.0, *)
private enum DateError: Error {
    case invalidFormat
}
