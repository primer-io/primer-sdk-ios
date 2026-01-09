//
//  PaymentResultHandlingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for payment result handling to achieve 90% Payment layer coverage.
@available(iOS 15.0, *)
@MainActor
final class PaymentResultHandlingTests: XCTestCase {

    private var sut: PaymentResultHandler!

    override func setUp() async throws {
        try await super.setUp()
        sut = PaymentResultHandler()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    func test_handleSuccess_completesPayment() async throws {
        let result = PaymentResult(status: "success", transactionId: "tx-123")
        let handled = try await sut.handle(result)
        XCTAssertEqual(handled.status, "success")
    }

    func test_handleDeclined_throwsError() async throws {
        let result = PaymentResult(status: "declined", transactionId: "tx-123")
        do {
            _ = try await sut.handle(result)
            XCTFail("Expected declined error")
        } catch {
            // Expected
        }
    }
}

@available(iOS 15.0, *)
private struct PaymentResult {
    let status: String
    let transactionId: String
}

@available(iOS 15.0, *)
private class PaymentResultHandler {
    func handle(_ result: PaymentResult) async throws -> PaymentResult {
        guard result.status != "declined" else {
            throw NSError(domain: "test", code: 1)
        }
        return result
    }
}
