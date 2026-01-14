//
//  TestData.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Organized by category for easy discovery and use.
@available(iOS 15.0, *)
enum TestData {

    // MARK: - Accessibility

    enum Accessibility {
        // Test configuration
        static let concurrentOperationCount = 10
        static let testTimeout: TimeInterval = 5.0
        static let testQueueLabel = "test.concurrent"
        static let concurrentExpectationDescription = "Concurrent announcements"

        // Announcement messages for tests
        static let errorPrefix = "Error"
        static let statePrefix = "State"
        static let errorMessage = "Error message"
        static let stateChangeMessage = "State change"
        static let layoutChangeMessage = "Layout change"
        static let screenChangeMessage = "Screen change"

        // Test case descriptions
        static let errorDescription = "Error announcements"
        static let stateChangeDescription = "State change announcements"
        static let layoutChangeDescription = "Layout change announcements"
        static let screenChangeDescription = "Screen change announcements"
    }

    // MARK: - Tokens

    enum Tokens {
        static let valid = "test-token"
        static let invalid = "invalid-token"
        static let expired = "expired-token"
    }
}

// MARK: - Test Error Type

enum TestError: Error, Equatable {
    case timeout
    case cancelled
    case validationFailed(String)
    case networkFailure
    case unknown

    var localizedDescription: String {
        switch self {
        case .timeout:
            return "Operation timed out"
        case .cancelled:
            return "Operation was cancelled"
        case let .validationFailed(message):
            return "Validation failed: \(message)"
        case .networkFailure:
            return "Network request failed"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
