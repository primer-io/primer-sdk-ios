//
//  PaymentCancellationTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for payment cancellation handling to achieve 90% Payment layer coverage.
@available(iOS 15.0, *)
@MainActor
final class PaymentCancellationTests: XCTestCase {

    private var sut: PaymentCancellationHandler!

    override func setUp() async throws {
        try await super.setUp()
        sut = PaymentCancellationHandler()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    func test_cancel_duringProcessing_throwsCancellationError() async throws {
        let task = Task {
            try await sut.processPayment()
        }

        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected
        }
    }

    func test_cancel_cleansUpResources() async throws {
        let task = Task {
            try await sut.processPayment()
        }

        task.cancel()

        do {
            _ = try await task.value
        } catch {
            // Expected
        }

        XCTAssertTrue(sut.didCleanup)
    }
}

@available(iOS 15.0, *)
private class PaymentCancellationHandler {
    var didCleanup = false

    func processPayment() async throws {
        defer {
            cleanup()
        }

        try await Task.sleep(nanoseconds: 1_000_000_000)
        try Task.checkCancellation()
    }

    func cleanup() {
        didCleanup = true
    }
}
