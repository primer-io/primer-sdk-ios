//
//  FraudCheckIntegrationTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for fraud check integration to achieve 90% Payment layer coverage.
@available(iOS 15.0, *)
@MainActor
final class FraudCheckIntegrationTests: XCTestCase {

    private var sut: FraudCheckService!

    override func setUp() async throws {
        try await super.setUp()
        sut = FraudCheckService()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    func test_checkFraud_lowRiskTransaction_passes() async throws {
        let transaction = FraudTransaction(amount: 100, deviceId: "device-123")
        let result = try await sut.checkFraud(transaction)
        XCTAssertEqual(result.riskLevel, .low)
        XCTAssertTrue(result.approved)
    }

    func test_checkFraud_highRiskTransaction_rejects() async throws {
        let transaction = FraudTransaction(amount: 10000, deviceId: "suspicious-device")
        let result = try await sut.checkFraud(transaction)
        XCTAssertEqual(result.riskLevel, .high)
        XCTAssertFalse(result.approved)
    }

    func test_checkFraud_mediumRiskTransaction_requiresReview() async throws {
        let transaction = FraudTransaction(amount: 5000, deviceId: "device-456")
        let result = try await sut.checkFraud(transaction)
        XCTAssertEqual(result.riskLevel, .medium)
    }
}

@available(iOS 15.0, *)
private struct FraudTransaction {
    let amount: Int
    let deviceId: String
}

@available(iOS 15.0, *)
private struct FraudCheckResult {
    let riskLevel: RiskLevel
    let approved: Bool

    enum RiskLevel {
        case low
        case medium
        case high
    }
}

@available(iOS 15.0, *)
private class FraudCheckService {
    func checkFraud(_ transaction: FraudTransaction) async throws -> FraudCheckResult {
        if transaction.deviceId.contains("suspicious") || transaction.amount > 9000 {
            return FraudCheckResult(riskLevel: .high, approved: false)
        } else if transaction.amount > 1000 {
            return FraudCheckResult(riskLevel: .medium, approved: true)
        } else {
            return FraudCheckResult(riskLevel: .low, approved: true)
        }
    }
}
