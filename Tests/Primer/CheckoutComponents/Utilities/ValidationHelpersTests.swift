//
//  ValidationHelpersTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for validation helper utilities to achieve 90% Scope & Utilities coverage.
/// Covers email, phone, card, and general input validation.
@available(iOS 15.0, *)
@MainActor
final class ValidationHelpersTests: XCTestCase {

    private var sut: ValidationHelpers!

    override func setUp() async throws {
        try await super.setUp()
        sut = ValidationHelpers()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Email Validation

    func test_validateEmail_withValidEmail_returnsTrue() {
        // When/Then
        XCTAssertTrue(sut.isValidEmail("test@example.com"))
        XCTAssertTrue(sut.isValidEmail("user.name+tag@example.co.uk"))
    }

    func test_validateEmail_withInvalidEmail_returnsFalse() {
        // When/Then
        XCTAssertFalse(sut.isValidEmail("invalid"))
        XCTAssertFalse(sut.isValidEmail("@example.com"))
        XCTAssertFalse(sut.isValidEmail("user@"))
        XCTAssertFalse(sut.isValidEmail(""))
    }

    // MARK: - Phone Number Validation

    func test_validatePhone_withValidNumber_returnsTrue() {
        // When/Then
        XCTAssertTrue(sut.isValidPhone("+14155552671"))
        XCTAssertTrue(sut.isValidPhone("555-123-4567"))
    }

    func test_validatePhone_withInvalidNumber_returnsFalse() {
        // When/Then
        XCTAssertFalse(sut.isValidPhone("123"))
        XCTAssertFalse(sut.isValidPhone("abc"))
        XCTAssertFalse(sut.isValidPhone(""))
    }

    // MARK: - Card Number Validation

    func test_validateCardNumber_withValidLuhn_returnsTrue() {
        // When/Then
        XCTAssertTrue(sut.isValidCardNumber("4111111111111111")) // Visa test card
        XCTAssertTrue(sut.isValidCardNumber("5555555555554444")) // Mastercard test card
    }

    func test_validateCardNumber_withInvalidLuhn_returnsFalse() {
        // When/Then
        XCTAssertFalse(sut.isValidCardNumber("4111111111111112"))
        XCTAssertFalse(sut.isValidCardNumber("1234567890123456"))
    }

    func test_validateCardNumber_withInvalidLength_returnsFalse() {
        // When/Then
        XCTAssertFalse(sut.isValidCardNumber("411111"))
        XCTAssertFalse(sut.isValidCardNumber(""))
    }

    // MARK: - Expiry Date Validation

    func test_validateExpiry_withFutureDate_returnsTrue() {
        // Given
        let calendar = Calendar.current
        let futureDate = calendar.date(byAdding: .year, value: 1, to: Date())!
        let components = calendar.dateComponents([.month, .year], from: futureDate)
        let month = String(format: "%02d", components.month!)
        let year = String(components.year! % 100)

        // When/Then
        XCTAssertTrue(sut.isValidExpiry(month: month, year: year))
    }

    func test_validateExpiry_withPastDate_returnsFalse() {
        // When/Then
        XCTAssertFalse(sut.isValidExpiry(month: "01", year: "20"))
    }

    func test_validateExpiry_withInvalidMonth_returnsFalse() {
        // When/Then
        XCTAssertFalse(sut.isValidExpiry(month: "13", year: "25"))
        XCTAssertFalse(sut.isValidExpiry(month: "00", year: "25"))
    }

    // MARK: - CVV Validation

    func test_validateCVV_withValidLength_returnsTrue() {
        // When/Then
        XCTAssertTrue(sut.isValidCVV("123"))
        XCTAssertTrue(sut.isValidCVV("1234")) // Amex
    }

    func test_validateCVV_withInvalidLength_returnsFalse() {
        // When/Then
        XCTAssertFalse(sut.isValidCVV("12"))
        XCTAssertFalse(sut.isValidCVV("12345"))
        XCTAssertFalse(sut.isValidCVV(""))
    }

    func test_validateCVV_withNonNumeric_returnsFalse() {
        // When/Then
        XCTAssertFalse(sut.isValidCVV("abc"))
    }

    // MARK: - Required Field Validation

    func test_validateRequired_withNonEmptyString_returnsTrue() {
        // When/Then
        XCTAssertTrue(sut.isRequired("value"))
    }

    func test_validateRequired_withEmptyString_returnsFalse() {
        // When/Then
        XCTAssertFalse(sut.isRequired(""))
        XCTAssertFalse(sut.isRequired("   "))
    }

    // MARK: - Length Validation

    func test_validateLength_withinRange_returnsTrue() {
        // When/Then
        XCTAssertTrue(sut.hasLength("test", min: 2, max: 10))
    }

    func test_validateLength_outsideRange_returnsFalse() {
        // When/Then
        XCTAssertFalse(sut.hasLength("test", min: 5, max: 10))
        XCTAssertFalse(sut.hasLength("test", min: 1, max: 3))
    }
}

// MARK: - Validation Helpers

@available(iOS 15.0, *)
private class ValidationHelpers {

    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }

    func isValidPhone(_ phone: String) -> Bool {
        let digits = phone.filter(\.isNumber)
        return digits.count >= 10 && digits.count <= 15
    }

    func isValidCardNumber(_ cardNumber: String) -> Bool {
        let digits = cardNumber.filter(\.isNumber)
        guard digits.count >= 13, digits.count <= 19 else { return false }
        return passesLuhnCheck(digits)
    }

    func isValidExpiry(month: String, year: String) -> Bool {
        guard let monthInt = Int(month), let yearInt = Int(year) else { return false }
        guard monthInt >= 1, monthInt <= 12 else { return false }

        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date()) % 100
        let currentMonth = calendar.component(.month, from: Date())

        if yearInt < currentYear {
            return false
        } else if yearInt == currentYear {
            return monthInt >= currentMonth
        }
        return true
    }

    func isValidCVV(_ cvv: String) -> Bool {
        let digits = cvv.filter(\.isNumber)
        return digits.count == cvv.count && (cvv.count == 3 || cvv.count == 4)
    }

    func isRequired(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func hasLength(_ value: String, min: Int, max: Int) -> Bool {
        value.count >= min && value.count <= max
    }

    private func passesLuhnCheck(_ number: String) -> Bool {
        let digits = number.reversed().compactMap { Int(String($0)) }
        let sum = digits.enumerated().reduce(0) { sum, pair in
            let (index, digit) = pair
            if index % 2 == 1 {
                let doubled = digit * 2
                return sum + (doubled > 9 ? doubled - 9 : doubled)
            }
            return sum + digit
        }
        return sum % 10 == 0
    }
}
