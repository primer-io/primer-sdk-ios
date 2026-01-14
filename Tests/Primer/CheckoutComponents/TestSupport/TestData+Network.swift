//
//  TestData+Network.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
extension TestData {

    // MARK: - Error Keys

    enum ErrorKeys {
        static let test = "test"
    }

    // MARK: - Diagnostics IDs

    enum DiagnosticsIds {
        static let test = "test-diagnostics"
    }
}

// MARK: - Test Error Type

/// Custom error type for test scenarios
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
