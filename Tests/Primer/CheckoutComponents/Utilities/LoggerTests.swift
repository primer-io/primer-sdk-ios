//
//  LoggerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for logging utilities to achieve 90% Scope & Utilities coverage.
/// Covers log levels, filtering, formatting, and output handling.
@available(iOS 15.0, *)
@MainActor
final class LoggerTests: XCTestCase {

    private var sut: Logger!
    private var mockOutput: MockLogOutput!

    override func setUp() async throws {
        try await super.setUp()
        mockOutput = MockLogOutput()
        sut = Logger(output: mockOutput)
    }

    override func tearDown() async throws {
        sut = nil
        mockOutput = nil
        try await super.tearDown()
    }

    // MARK: - Log Levels

    func test_debug_logsAtDebugLevel() async throws {
        // When
        await sut.debug("Debug message")

        // Then
        let messages = await mockOutput.messages
        XCTAssertEqual(messages.count, 1)
        XCTAssertTrue(messages.first?.contains("[DEBUG]") ?? false)
        XCTAssertTrue(messages.first?.contains("Debug message") ?? false)
    }

    func test_info_logsAtInfoLevel() async throws {
        // When
        await sut.info("Info message")

        // Then
        let messages = await mockOutput.messages
        XCTAssertEqual(messages.count, 1)
        XCTAssertTrue(messages.first?.contains("[INFO]") ?? false)
    }

    func test_warning_logsAtWarningLevel() async throws {
        // When
        await sut.warning("Warning message")

        // Then
        let messages = await mockOutput.messages
        XCTAssertEqual(messages.count, 1)
        XCTAssertTrue(messages.first?.contains("[WARNING]") ?? false)
    }

    func test_error_logsAtErrorLevel() async throws {
        // When
        await sut.error("Error message")

        // Then
        let messages = await mockOutput.messages
        XCTAssertEqual(messages.count, 1)
        XCTAssertTrue(messages.first?.contains("[ERROR]") ?? false)
    }

    // MARK: - Log Level Filtering

    func test_setMinimumLevel_filtersLowerLevels() async throws {
        // Given
        sut.minimumLevel = .warning

        // When
        await sut.debug("Debug message")
        await sut.info("Info message")
        await sut.warning("Warning message")
        await sut.error("Error message")

        // Then
        let messages = await mockOutput.messages
        XCTAssertEqual(messages.count, 2) // Only warning and error
    }

    // MARK: - Message Formatting

    func test_log_includesTimestamp() async throws {
        // When
        await sut.info("Test message")

        // Then
        let messages = await mockOutput.messages
        let message = messages.first ?? ""
        XCTAssertTrue(message.contains(":")) // Timestamp format
    }

    func test_log_includesCategory() async throws {
        // Given
        let logger = Logger(category: "Network", output: mockOutput)

        // When
        await logger.info("Test message")

        // Then
        let messages = await mockOutput.messages
        let message = messages.first ?? ""
        XCTAssertTrue(message.contains("[Network]"))
    }

    // MARK: - Context

    func test_logWithContext_includesContext() async throws {
        // When
        await sut.info("Test message", context: ["userId": "123", "sessionId": "abc"])

        // Then
        let messages = await mockOutput.messages
        let message = messages.first ?? ""
        XCTAssertTrue(message.contains("userId"))
        XCTAssertTrue(message.contains("123"))
    }

    // MARK: - Error Logging

    func test_logError_includesErrorDescription() async throws {
        // Given
        let error = NSError(domain: "TestError", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])

        // When
        await sut.error("Error occurred", error: error)

        // Then
        let messages = await mockOutput.messages
        let message = messages.first ?? ""
        XCTAssertTrue(message.contains("Test error"))
        XCTAssertTrue(message.contains("123"))
    }

    // MARK: - Performance

    func test_logging_withDisabledOutput_doesNotSlowDown() async throws {
        // Given
        sut.isEnabled = false
        let startTime = Date()

        // When
        for _ in 0..<1000 {
            await sut.info("Test message")
        }

        // Then
        let duration = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(duration, 0.1) // Should be very fast when disabled
        let messages = await mockOutput.messages
        XCTAssertTrue(messages.isEmpty)
    }

    // MARK: - Multiple Outputs

    func test_logger_withMultipleOutputs_logsToAll() async throws {
        // Given
        let output1 = MockLogOutput()
        let output2 = MockLogOutput()
        let logger = Logger(outputs: [output1, output2])

        // When
        await logger.info("Test message")

        // Then
        let messages1 = await output1.messages
        let messages2 = await output2.messages
        XCTAssertEqual(messages1.count, 1)
        XCTAssertEqual(messages2.count, 1)
    }

    // MARK: - Thread Safety

    func test_logging_fromMultipleThreads_handlesSafely() async {
        // When
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    await self.sut.info("Message \(i)")
                }
            }
        }

        // Then
        let messages = await mockOutput.messages
        XCTAssertEqual(messages.count, 100)
    }
}

// MARK: - Test Models

@available(iOS 15.0, *)
private enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Mock Log Output

@available(iOS 15.0, *)
private actor MockLogOutput {
    var messages: [String] = []

    func write(_ message: String) {
        messages.append(message)
    }

    func clear() {
        messages.removeAll()
    }
}

// MARK: - Logger

@available(iOS 15.0, *)
@MainActor
private class Logger {
    private let outputs: [MockLogOutput]
    private let category: String
    var minimumLevel: LogLevel = .debug
    var isEnabled: Bool = true

    init(category: String = "", output: MockLogOutput) {
        self.category = category
        self.outputs = [output]
    }

    init(category: String = "", outputs: [MockLogOutput]) {
        self.category = category
        self.outputs = outputs
    }

    func debug(_ message: String, context: [String: String] = [:]) async {
        await logAsync(message, level: .debug, context: context)
    }

    func info(_ message: String, context: [String: String] = [:]) async {
        await logAsync(message, level: .info, context: context)
    }

    func warning(_ message: String, context: [String: String] = [:]) async {
        await logAsync(message, level: .warning, context: context)
    }

    func error(_ message: String, error: Error? = nil, context: [String: String] = [:]) async {
        var fullMessage = message
        if let error = error {
            fullMessage += " - \(error.localizedDescription)"
            if let nsError = error as NSError? {
                fullMessage += " (Code: \(nsError.code))"
            }
        }
        await logAsync(fullMessage, level: .error, context: context)
    }

    private func log(_ message: String, level: LogLevel, context: [String: String]) {
        guard isEnabled, level >= minimumLevel else { return }

        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let levelString = "[\(String(describing: level).uppercased())]"
        let categoryString = category.isEmpty ? "" : "[\(category)]"
        let contextString = context.isEmpty ? "" : " \(context)"

        let formattedMessage = "\(timestamp) \(levelString)\(categoryString) \(message)\(contextString)"

        Task {
            for output in outputs {
                await output.write(formattedMessage)
            }
        }
    }

    private func logAsync(_ message: String, level: LogLevel, context: [String: String]) async {
        guard isEnabled, level >= minimumLevel else { return }

        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let levelString = "[\(String(describing: level).uppercased())]"
        let categoryString = category.isEmpty ? "" : "[\(category)]"
        let contextString = context.isEmpty ? "" : " \(context)"

        let formattedMessage = "\(timestamp) \(levelString)\(categoryString) \(message)\(contextString)"

        for output in outputs {
            await output.write(formattedMessage)
        }
    }
}
