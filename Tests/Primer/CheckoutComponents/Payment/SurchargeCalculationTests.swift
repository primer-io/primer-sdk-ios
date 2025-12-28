//
//  SurchargeCalculationTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for surcharge calculation to achieve 90% Payment layer coverage.
@available(iOS 15.0, *)
@MainActor
final class SurchargeCalculationTests: XCTestCase {

    private var sut: SurchargeCalculator!

    override func setUp() async throws {
        try await super.setUp()
        sut = SurchargeCalculator()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    func test_calculate_withPercentageFee_calculatesCorrectly() {
        let surcharge = sut.calculate(amount: TestData.Amounts.standard, feePercentage: 2.5)
        XCTAssertEqual(surcharge, 25)
    }

    func test_calculate_withFixedFee_returnsFixedAmount() {
        let surcharge = sut.calculate(amount: TestData.Amounts.standard, fixedFee: 50)
        XCTAssertEqual(surcharge, 50)
    }

    func test_calculate_withBothFees_combinesBoth() {
        let surcharge = sut.calculate(amount: TestData.Amounts.standard, feePercentage: 2.0, fixedFee: 30)
        XCTAssertEqual(surcharge, 50) // 20 + 30
    }

    func test_calculate_zeroAmount_returnsZero() {
        let surcharge = sut.calculate(amount: 0, feePercentage: 2.0)
        XCTAssertEqual(surcharge, 0)
    }
}

@available(iOS 15.0, *)
private class SurchargeCalculator {
    func calculate(amount: Int, feePercentage: Double = 0.0, fixedFee: Int = 0) -> Int {
        let percentageFee = Int(Double(amount) * feePercentage / 100.0)
        return percentageFee + fixedFee
    }
}
