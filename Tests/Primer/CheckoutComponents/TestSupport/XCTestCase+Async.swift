//
//  XCTestCase+Async.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest

/// Extension providing async testing utilities
extension XCTestCase {

    /// Collects values from an AsyncStream up to a limit or timeout
    /// - Parameters:
    ///   - stream: The AsyncStream to collect from
    ///   - count: The maximum number of values to collect
    ///   - timeout: The maximum time to wait (default: 2.0 seconds)
    /// - Returns: An array of collected values
    /// - Throws: TestError.timeout if the timeout is reached before collecting enough values
    func collect<T>(
        _ stream: AsyncStream<T>,
        count: Int,
        timeout: TimeInterval = 2.0
    ) async throws -> [T] {
        var values: [T] = []

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                for await value in stream {
                    values.append(value)
                    if values.count >= count {
                        return
                    }
                }
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TestError.timeout
            }

            _ = try await group.next()
            group.cancelAll()
        }

        return values
    }

    /// Collects the first value from an AsyncStream with a timeout
    /// - Parameters:
    ///   - stream: The AsyncStream to collect from
    ///   - timeout: The maximum time to wait (default: 2.0 seconds)
    /// - Returns: The first value from the stream
    /// - Throws: TestError.timeout if no value is received within the timeout
    func collectFirst<T>(
        _ stream: AsyncStream<T>,
        timeout: TimeInterval = 2.0
    ) async throws -> T {
        let values = try await collect(stream, count: 1, timeout: timeout)
        guard let first = values.first else {
            throw TestError.timeout
        }
        return first
    }

    /// Waits for an async condition to become true
    /// - Parameters:
    ///   - timeout: Maximum time to wait
    ///   - pollingInterval: Time between condition checks
    ///   - condition: The condition to check
    /// - Returns: True if condition was met, false if timeout occurred
    func waitFor(
        timeout: TimeInterval = 2.0,
        pollingInterval: TimeInterval = 0.1,
        condition: @escaping () async -> Bool
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if await condition() {
                return true
            }
            try? await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
        }

        return false
    }

    /// Asserts that an async throwing expression throws a specific error type
    /// - Parameters:
    ///   - expression: The async throwing expression
    ///   - errorType: The expected error type
    ///   - message: Optional failure message
    ///   - file: The file where the assertion is made
    ///   - line: The line where the assertion is made
    func assertThrowsAsync<T, E: Error>(
        _ expression: @autoclosure () async throws -> T,
        errorType: E.Type,
        _ message: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error of type \(errorType) but no error was thrown. \(message)", file: file, line: line)
        } catch {
            XCTAssertTrue(
                error is E,
                "Expected error of type \(errorType) but got \(type(of: error)). \(message)",
                file: file,
                line: line
            )
        }
    }

    /// Asserts that an async throwing expression does not throw
    /// - Parameters:
    ///   - expression: The async throwing expression
    ///   - message: Optional failure message
    ///   - file: The file where the assertion is made
    ///   - line: The line where the assertion is made
    /// - Returns: The result of the expression if successful
    @discardableResult
    func assertNoThrowAsync<T>(
        _ expression: @autoclosure () async throws -> T,
        _ message: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) async -> T? {
        do {
            return try await expression()
        } catch {
            XCTFail("Unexpected error: \(error). \(message)", file: file, line: line)
            return nil
        }
    }
}

// MARK: - Expectation Helpers

extension XCTestCase {

    /// Creates and fulfills an expectation when a condition is met
    /// - Parameters:
    ///   - description: Description of the expectation
    ///   - timeout: Maximum time to wait
    ///   - condition: The condition to check
    func expectAsync(
        _ description: String,
        timeout: TimeInterval = 2.0,
        condition: @escaping () async -> Bool
    ) async {
        let expectation = expectation(description: description)

        Task {
            let result = await waitFor(timeout: timeout, condition: condition)
            if result {
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: timeout + 0.5)
    }
}
