//
//  TimeoutTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable @_spi(PrimerInternal) import PrimerBDCCore
import XCTest

@MainActor
final class TimeoutTests: XCTestCase {

    func testReturnsTheOperationsValue() async throws {
        let value = try await withTimeout(nanoseconds: 1_000_000_000) { 42 }

        XCTAssertEqual(value, 42)
    }

    func testPassesTheOperationsErrorOn() async {
        do {
            _ = try await withTimeout(nanoseconds: 1_000_000_000) { () async throws -> Int in throw Failure.failed }
            XCTFail("Expected the operation's error")
        } catch {
            XCTAssertEqual(error as? Failure, .failed)
        }
    }

    func testThrowsOnceTheTimeIsUpWithoutWaitingForTheOperation() async {
        let startedAt = Date()

        do {
            _ = try await withTimeout(nanoseconds: 20_000_000) { () async -> Int in
                // Ignores cancellation.
                await withCheckedContinuation { continuation in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { continuation.resume(returning: 1) }
                }
            }
            XCTFail("Expected a timeout")
        } catch {
            XCTAssertEqual(error as? TimeoutError, TimeoutError(nanoseconds: 20_000_000))
        }
        XCTAssertLessThan(Date().timeIntervalSince(startedAt), 0.5)
    }

    func testCancelsTheOperationOnceTheTimeIsUp() async {
        let cancelled = expectation(description: "operation cancelled")

        _ = try? await withTimeout(nanoseconds: 20_000_000) { () async throws -> Int in
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
            } catch {
                cancelled.fulfill()
                throw error
            }
            return 1
        }

        await fulfillment(of: [cancelled], timeout: 1)
    }
}

private enum Failure: Error {
    case failed
}
