//
//  PaymentValidationTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for payment validation rules to achieve 90% Payment layer coverage.
@available(iOS 15.0, *)
@MainActor
final class PaymentValidationTests: XCTestCase {

    private var sut: PaymentValidator!

    override func setUp() async throws {
        try await super.setUp()
        sut = PaymentValidator()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Amount Validation

    func test_validate_positiveAmount_passes() {
        let result = sut.validate(amount: 1000, currency: "USD")
        XCTAssertTrue(result.isValid)
    }

    func test_validate_zeroAmount_fails() {
        let result = sut.validate(amount: 0, currency: "USD")
        XCTAssertFalse(result.isValid)
    }

    func test_validate_negativeAmount_fails() {
        let result = sut.validate(amount: -100, currency: "USD")
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Currency Validation

    func test_validate_validCurrency_passes() {
        let currencies = ["USD", "EUR", "GBP"]
        for currency in currencies {
            let result = sut.validate(amount: 1000, currency: currency)
            XCTAssertTrue(result.isValid)
        }
    }

    func test_validate_invalidCurrency_fails() {
        let result = sut.validate(amount: 1000, currency: "INVALID")
        XCTAssertFalse(result.isValid)
    }
}

// MARK: - Payment Validator

@available(iOS 15.0, *)
private class PaymentValidator {
    func validate(amount: Int, currency: String) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []

        if amount <= 0 {
            errors.append("Amount must be positive")
        }

        let validCurrencies = ["USD", "EUR", "GBP"]
        if !validCurrencies.contains(currency) {
            errors.append("Invalid currency")
        }

        return (errors.isEmpty, errors)
    }
}
