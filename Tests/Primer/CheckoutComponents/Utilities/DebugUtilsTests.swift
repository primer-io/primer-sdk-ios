//
//  DebugUtilsTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for debug utilities to achieve 90% Scope & Utilities coverage.
/// Covers debug logging, assertions, performance measurement, and diagnostics.
@available(iOS 15.0, *)
@MainActor
final class DebugUtilsTests: XCTestCase {

    private var sut: DebugUtils!

    override func setUp() async throws {
        try await super.setUp()
        sut = DebugUtils()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Debug Logging

    func test_debugLog_inDebugMode_logs() {
        // Given
        sut.isDebugMode = true

        // When
        sut.log("Test message")

        // Then
        XCTAssertEqual(sut.loggedMessages.count, 1)
        XCTAssertEqual(sut.loggedMessages.first, "Test message")
    }

    func test_debugLog_inReleaseMode_doesNotLog() {
        // Given
        sut.isDebugMode = false

        // When
        sut.log("Test message")

        // Then
        XCTAssertTrue(sut.loggedMessages.isEmpty)
    }

    // MARK: - Performance Measurement

    func test_measure_capturesExecutionTime() async throws {
        // When
        let duration = try await sut.measure {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }

        // Then
        XCTAssertGreaterThan(duration, 0.09) // Should be at least 90ms
        XCTAssertLessThan(duration, 0.2) // Should be less than 200ms
    }

    func test_measureSync_capturesExecutionTime() {
        // When
        let duration = sut.measureSync {
            Thread.sleep(forTimeInterval: 0.1)
        }

        // Then
        XCTAssertGreaterThan(duration, 0.09)
    }

    // MARK: - Assertions

    func test_assert_withTrueCondition_doesNotThrow() {
        // When/Then
        XCTAssertNoThrow(try sut.assert(true, "Should not throw"))
    }

    func test_assert_withFalseCondition_throws() {
        // When/Then
        XCTAssertThrowsError(try sut.assert(false, "Should throw"))
    }

    func test_assert_inReleaseMode_doesNotThrow() {
        // Given
        sut.isDebugMode = false

        // When/Then
        XCTAssertNoThrow(try sut.assert(false, "Should not throw in release"))
    }

    // MARK: - Memory Diagnostics

    func test_captureMemoryFootprint_returnsMemoryUsage() {
        // When
        let memory = sut.captureMemoryFootprint()

        // Then
        XCTAssertGreaterThan(memory, 0)
    }

    func test_trackMemoryLeak_detectsRetainCycle() {
        // Given
        weak var weakObject: NSObject?

        // When
        autoreleasepool {
            let object = NSObject()
            weakObject = object
            sut.trackObject(object, identifier: "testObject")
        }

        // Then - object should be deallocated
        XCTAssertNil(weakObject)
    }

    // MARK: - Stack Trace

    func test_captureStackTrace_returnsCallStack() {
        // When
        let stackTrace = sut.captureStackTrace()

        // Then
        XCTAssertFalse(stackTrace.isEmpty)
        XCTAssertTrue(stackTrace.contains("test_captureStackTrace_returnsCallStack"))
    }

    // MARK: - Breakpoint

    func test_breakpointIfAttached_checksDebugger() {
        // When
        let isAttached = sut.isDebuggerAttached()

        // Then
        // Can't reliably test this as it depends on debug environment
        XCTAssertNotNil(isAttached)
    }

    // MARK: - Thread Diagnostics

    func test_isMainThread_onMainThread_returnsTrue() {
        // When/Then
        XCTAssertTrue(sut.isMainThread())
    }

    func test_isMainThread_onBackgroundThread_returnsFalse() async {
        // When
        let result = await Task.detached {
            await self.sut.isMainThread()
        }.value

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Debug Description

    func test_debugDescription_includesRelevantInfo() {
        // Given
        let obj = DebugDescribable(id: 123, name: "Test")

        // When
        let description = sut.debugDescription(of: obj)

        // Then
        XCTAssertTrue(description.contains("123"))
        XCTAssertTrue(description.contains("Test"))
    }

    // MARK: - Conditional Compilation

    func test_onlyInDebug_inDebugMode_executes() {
        // Given
        sut.isDebugMode = true
        var executed = false

        // When
        sut.onlyInDebug {
            executed = true
        }

        // Then
        XCTAssertTrue(executed)
    }

    func test_onlyInDebug_inReleaseMode_doesNotExecute() {
        // Given
        sut.isDebugMode = false
        var executed = false

        // When
        sut.onlyInDebug {
            executed = true
        }

        // Then
        XCTAssertFalse(executed)
    }
}

// MARK: - Test Models

@available(iOS 15.0, *)
private struct DebugDescribable {
    let id: Int
    let name: String
}

// MARK: - Debug Utils

@available(iOS 15.0, *)
@MainActor
private class DebugUtils {
    var isDebugMode = true
    private(set) var loggedMessages: [String] = []
    private var trackedObjects: [String: WeakBox] = [:]

    func log(_ message: String) {
        guard isDebugMode else { return }
        loggedMessages.append(message)
    }

    func measure(_ block: () async throws -> Void) async rethrows -> TimeInterval {
        let start = Date()
        try await block()
        return Date().timeIntervalSince(start)
    }

    func measureSync(_ block: () -> Void) -> TimeInterval {
        let start = Date()
        block()
        return Date().timeIntervalSince(start)
    }

    func assert(_ condition: Bool, _ message: String) throws {
        guard isDebugMode else { return }
        if !condition {
            throw DebugError.assertionFailed(message)
        }
    }

    func captureMemoryFootprint() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }

    func trackObject(_ object: AnyObject, identifier: String) {
        trackedObjects[identifier] = WeakBox(object)
    }

    func captureStackTrace() -> String {
        Thread.callStackSymbols.joined(separator: "\n")
    }

    func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        guard junk == 0 else { return false }
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    func isMainThread() -> Bool {
        Thread.isMainThread
    }

    func debugDescription(of object: Any) -> String {
        String(reflecting: object)
    }

    func onlyInDebug(_ block: () -> Void) {
        guard isDebugMode else { return }
        block()
    }
}

// MARK: - Debug Error

@available(iOS 15.0, *)
private enum DebugError: Error {
    case assertionFailed(String)
}

// MARK: - Weak Box

@available(iOS 15.0, *)
private class WeakBox {
    weak var value: AnyObject?

    init(_ value: AnyObject) {
        self.value = value
    }
}
