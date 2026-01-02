//
//  XCTestCase+Async.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

// MARK: - Async Stream Test Helpers

@available(iOS 15.0, *)
extension XCTestCase {

    // MARK: - Collect Values

    /// Collects a specified number of values from an AsyncStream with timeout.
    ///
    /// - Parameters:
    ///   - stream: The AsyncStream to collect values from
    ///   - count: Number of values to collect
    ///   - timeout: Maximum time to wait (default: 2.0 seconds)
    /// - Returns: Array of collected values
    /// - Throws: `AsyncTestError.timeout` if timeout expires before collecting all values
    ///
    /// Example:
    /// ```swift
    /// let values = try await collect(scope.state, count: 3)
    /// XCTAssertEqual(values, [.initializing, .loading, .ready])
    /// ```
    func collect<T>(
        _ stream: AsyncStream<T>,
        count: Int,
        timeout: TimeInterval = 2.0
    ) async throws -> [T] {
        try await withThrowingTaskGroup(of: [T].self) { group in
            group.addTask {
                var collected: [T] = []
                for await value in stream {
                    collected.append(value)
                    if collected.count >= count {
                        break
                    }
                }
                return collected
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw AsyncTestError.timeout(
                    message: "Timed out waiting to collect \(count) values after \(timeout)s"
                )
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    // MARK: - Await First Value

    /// Gets the first value emitted by an AsyncStream with timeout.
    ///
    /// - Parameters:
    ///   - stream: The AsyncStream to get the first value from
    ///   - timeout: Maximum time to wait (default: 1.0 seconds)
    /// - Returns: The first emitted value
    /// - Throws: `AsyncTestError.timeout` if timeout expires, `AsyncTestError.streamDidNotEmit` if stream completes without emitting
    ///
    /// Example:
    /// ```swift
    /// let firstState = try await awaitFirst(scope.state)
    /// XCTAssertEqual(firstState, .initializing)
    /// ```
    func awaitFirst<T>(
        _ stream: AsyncStream<T>,
        timeout: TimeInterval = 1.0
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                for await value in stream {
                    return value
                }
                throw AsyncTestError.streamDidNotEmit
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw AsyncTestError.timeout(
                    message: "Timed out waiting for first value after \(timeout)s"
                )
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    // MARK: - Await Matching Value

    /// Waits for a value matching a predicate from an AsyncStream with timeout.
    ///
    /// - Parameters:
    ///   - stream: The AsyncStream to observe
    ///   - predicate: A closure that returns true when the desired value is found
    ///   - timeout: Maximum time to wait (default: 2.0 seconds)
    /// - Returns: The first value matching the predicate
    /// - Throws: `AsyncTestError.timeout` if timeout expires before finding a match
    ///
    /// Example:
    /// ```swift
    /// let readyState = try await awaitValue(scope.state) { $0 == .ready }
    /// XCTAssertEqual(readyState, .ready)
    /// ```
    func awaitValue<T>(
        _ stream: AsyncStream<T>,
        matching predicate: @escaping (T) -> Bool,
        timeout: TimeInterval = 2.0
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                for await value in stream {
                    if predicate(value) {
                        return value
                    }
                }
                throw AsyncTestError.noMatchingValue
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw AsyncTestError.timeout(
                    message: "Timed out waiting for matching value after \(timeout)s"
                )
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    // MARK: - Await Equatable Value

    /// Waits for a specific equatable value from an AsyncStream with timeout.
    ///
    /// - Parameters:
    ///   - stream: The AsyncStream to observe
    ///   - expectedValue: The value to wait for
    ///   - timeout: Maximum time to wait (default: 2.0 seconds)
    /// - Returns: The matched value
    /// - Throws: `AsyncTestError.timeout` if timeout expires before finding the value
    ///
    /// Example:
    /// ```swift
    /// let state = try await awaitValue(scope.state, equalTo: .ready)
    /// ```
    func awaitValue<T: Equatable>(
        _ stream: AsyncStream<T>,
        equalTo expectedValue: T,
        timeout: TimeInterval = 2.0
    ) async throws -> T {
        try await awaitValue(stream, matching: { $0 == expectedValue }, timeout: timeout)
    }

    // MARK: - Collect Until

    /// Collects values from an AsyncStream until a predicate is satisfied.
    ///
    /// - Parameters:
    ///   - stream: The AsyncStream to collect values from
    ///   - predicate: A closure that returns true when collection should stop
    ///   - timeout: Maximum time to wait (default: 2.0 seconds)
    /// - Returns: Array of collected values including the final matching value
    /// - Throws: `AsyncTestError.timeout` if timeout expires before predicate is satisfied
    ///
    /// Example:
    /// ```swift
    /// let states = try await collectUntil(scope.state) { $0 == .ready }
    /// XCTAssertEqual(states.last, .ready)
    /// ```
    func collectUntil<T>(
        _ stream: AsyncStream<T>,
        _ predicate: @escaping (T) -> Bool,
        timeout: TimeInterval = 2.0
    ) async throws -> [T] {
        try await withThrowingTaskGroup(of: [T].self) { group in
            group.addTask {
                var collected: [T] = []
                for await value in stream {
                    collected.append(value)
                    if predicate(value) {
                        break
                    }
                }
                return collected
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw AsyncTestError.timeout(
                    message: "Timed out waiting for predicate match after \(timeout)s"
                )
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    // MARK: - Assert Stream Emits

    /// Asserts that a stream emits at least one value within timeout.
    ///
    /// - Parameters:
    ///   - stream: The AsyncStream to observe
    ///   - timeout: Maximum time to wait (default: 1.0 seconds)
    ///   - message: Optional failure message
    ///   - file: Source file for assertion failure
    ///   - line: Source line for assertion failure
    func assertStreamEmits<T>(
        _ stream: AsyncStream<T>,
        timeout: TimeInterval = 1.0,
        _ message: String = "Stream should emit at least one value",
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            _ = try await awaitFirst(stream, timeout: timeout)
        } catch {
            XCTFail("\(message): \(error)", file: file, line: line)
        }
    }
}

// MARK: - Async Test Errors

/// Errors that can occur during async stream testing
enum AsyncTestError: Error, LocalizedError {
    case timeout(message: String)
    case streamDidNotEmit
    case noMatchingValue

    var errorDescription: String? {
        switch self {
        case let .timeout(message):
            return message
        case .streamDidNotEmit:
            return "AsyncStream completed without emitting any values"
        case .noMatchingValue:
            return "AsyncStream completed without emitting a matching value"
        }
    }
}

// MARK: - Task Helpers

@available(iOS 15.0, *)
extension XCTestCase {

    /// Executes an async operation with a timeout.
    ///
    /// - Parameters:
    ///   - timeout: Maximum time to wait
    ///   - operation: The async operation to execute
    /// - Returns: The result of the operation
    /// - Throws: `AsyncTestError.timeout` if timeout expires
    func withTimeout<T>(
        _ timeout: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw AsyncTestError.timeout(message: "Operation timed out after \(timeout)s")
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
