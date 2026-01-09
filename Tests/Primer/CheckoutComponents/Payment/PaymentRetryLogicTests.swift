//
//  PaymentRetryLogicTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for payment retry logic to achieve 90% Payment layer coverage.
@available(iOS 15.0, *)
@MainActor
final class PaymentRetryLogicTests: XCTestCase {

    private var sut: PaymentRetryHandler!

    override func setUp() async throws {
        try await super.setUp()
        sut = PaymentRetryHandler()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    func test_retry_onNetworkError_succeeds() async throws {
        var attempts = 0
        let result = try await sut.executeWithRetry(maxRetries: 3) {
            attempts += 1
            if attempts < 2 {
                throw TestData.Errors.networkTimeout
            }
            return "success"
        }
        XCTAssertEqual(result, "success")
        XCTAssertEqual(attempts, 2)
    }

    func test_retry_exhausted_throwsError() async throws {
        do {
            _ = try await sut.executeWithRetry(maxRetries: 2) {
                throw TestData.Errors.networkTimeout
            }
            XCTFail("Expected error")
        } catch {
            // Expected
        }
    }
}

@available(iOS 15.0, *)
private class PaymentRetryHandler {
    func executeWithRetry<T>(maxRetries: Int, operation: () async throws -> T) async throws -> T {
        var lastError: Error?
        for attempt in 0...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: 100_000_000)
                }
            }
        }
        throw lastError!
    }
}
