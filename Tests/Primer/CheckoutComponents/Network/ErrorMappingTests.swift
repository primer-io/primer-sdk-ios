//
//  ErrorMappingTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for error mapping from API errors to domain errors.
/// Covers transformation, categorization, and user-friendly messaging.
@available(iOS 15.0, *)
@MainActor
final class ErrorMappingTests: XCTestCase {

    private var sut: ErrorMapper!

    override func setUp() async throws {
        try await super.setUp()
        sut = ErrorMapper()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Network Error Mapping

    func test_mapError_networkTimeout_returnsDomainError() {
        // Given
        let networkError = TestData.Errors.networkTimeout

        // When
        let domainError = sut.map(networkError)

        // Then
        if case let .networkUnavailable(message) = domainError {
            XCTAssertTrue(message.contains("timeout"))
        } else {
            XCTFail("Expected networkUnavailable error")
        }
    }

    func test_mapError_noConnection_returnsDomainError() {
        // Given
        let networkError = TestData.Errors.noConnection

        // When
        let domainError = sut.map(networkError)

        // Then
        if case let .networkUnavailable(message) = domainError {
            XCTAssertTrue(message.contains("connection"))
        } else {
            XCTFail("Expected networkUnavailable error")
        }
    }

    // MARK: - HTTP Status Code Mapping

    func test_mapError_400BadRequest_returnsValidationError() {
        // Given
        let apiError = APIError.badRequest(message: "Invalid card number")

        // When
        let domainError = sut.map(apiError)

        // Then
        if case let .validation(errors) = domainError {
            XCTAssertTrue(errors.contains { $0.contains("card number") })
        } else {
            XCTFail("Expected validation error")
        }
    }

    func test_mapError_401Unauthorized_returnsAuthenticationError() {
        // Given
        let apiError = APIError.unauthorized

        // When
        let domainError = sut.map(apiError)

        // Then
        if case let .authentication(message) = domainError {
            XCTAssertTrue(message.contains("unauthorized"))
        } else {
            XCTFail("Expected authentication error")
        }
    }

    func test_mapError_403Forbidden_returnsAuthorizationError() {
        // Given
        let apiError = APIError.forbidden

        // When
        let domainError = sut.map(apiError)

        // Then
        if case let .authorization(message) = domainError {
            XCTAssertTrue(message.contains("forbidden"))
        } else {
            XCTFail("Expected authorization error")
        }
    }

    func test_mapError_404NotFound_returnsResourceNotFoundError() {
        // Given
        let apiError = APIError.notFound(resource: "payment-method")

        // When
        let domainError = sut.map(apiError)

        // Then
        if case let .resourceNotFound(resource) = domainError {
            XCTAssertEqual(resource, "payment-method")
        } else {
            XCTFail("Expected resourceNotFound error")
        }
    }

    func test_mapError_500InternalServer_returnsServerError() {
        // Given
        let apiError = APIError.serverError(statusCode: 500)

        // When
        let domainError = sut.map(apiError)

        // Then
        if case let .serverUnavailable(message) = domainError {
            XCTAssertTrue(message.contains("500"))
        } else {
            XCTFail("Expected serverUnavailable error")
        }
    }

    // MARK: - Business Logic Error Mapping

    func test_mapError_insufficientFunds_returnsPaymentDeclined() {
        // Given
        let apiError = APIError.paymentDeclined(reason: "insufficient_funds")

        // When
        let domainError = sut.map(apiError)

        // Then
        if case let .paymentDeclined(reason) = domainError {
            XCTAssertEqual(reason, "insufficient_funds")
        } else {
            XCTFail("Expected paymentDeclined error")
        }
    }

    func test_mapError_expiredCard_returnsValidationError() {
        // Given
        let apiError = APIError.validationFailed(fields: ["expiry": "Card has expired"])

        // When
        let domainError = sut.map(apiError)

        // Then
        if case let .validation(errors) = domainError {
            XCTAssertTrue(errors.contains("Card has expired"))
        } else {
            XCTFail("Expected validation error")
        }
    }

    // MARK: - 3DS Error Mapping

    func test_mapError_3DSAuthenticationFailed_returnsThreeDSError() {
        // Given
        let apiError = APIError.threeDSFailed(reason: "authentication_failed")

        // When
        let domainError = sut.map(apiError)

        // Then
        if case let .threeDSFailed(reason) = domainError {
            XCTAssertEqual(reason, "authentication_failed")
        } else {
            XCTFail("Expected threeDSFailed error")
        }
    }

    func test_mapError_3DSTimeout_returnsThreeDSError() {
        // Given
        let apiError = APIError.threeDSFailed(reason: "timeout")

        // When
        let domainError = sut.map(apiError)

        // Then
        if case let .threeDSFailed(reason) = domainError {
            XCTAssertEqual(reason, "timeout")
        } else {
            XCTFail("Expected threeDSFailed error")
        }
    }

    // MARK: - User-Friendly Messages

    func test_mapError_providesUserFriendlyMessage() {
        // Given
        let apiError = APIError.badRequest(message: "field_validation_error_12345")

        // When
        let domainError = sut.map(apiError)
        let userMessage = sut.getUserMessage(for: domainError)

        // Then
        XCTAssertFalse(userMessage.contains("12345")) // Should not contain error codes
        XCTAssertTrue(!userMessage.isEmpty)
    }

    func test_mapError_networkTimeout_providesActionableMessage() {
        // Given
        let networkError = TestData.Errors.networkTimeout

        // When
        let domainError = sut.map(networkError)
        let userMessage = sut.getUserMessage(for: domainError)

        // Then
        XCTAssertTrue(userMessage.contains("try again") || userMessage.contains("connection"))
    }

    // MARK: - Error Categorization

    func test_mapError_categorizesAsRecoverable() {
        // Given
        let errors: [Error] = [
            TestData.Errors.networkTimeout,
            APIError.serverError(statusCode: 503)
        ]

        // When/Then
        for error in errors {
            let domainError = sut.map(error)
            XCTAssertTrue(sut.isRecoverable(domainError), "Expected \(error) to be recoverable")
        }
    }

    func test_mapError_categorizesAsNonRecoverable() {
        // Given
        let errors: [any Error] = [
            APIError.unauthorized,
            APIError.paymentDeclined(reason: "fraud_check")
        ]

        // When/Then
        for error in errors {
            let domainError = sut.map(error)
            XCTAssertFalse(sut.isRecoverable(domainError), "Expected \(error) to be non-recoverable")
        }
    }

    // MARK: - Nested Error Handling

    func test_mapError_withUnderlyingError_preservesContext() {
        // Given
        let underlyingError = NSError(domain: "TestDomain", code: 999, userInfo: [NSLocalizedDescriptionKey: "Underlying error"])
        let apiError = APIError.unknown(underlying: underlyingError)

        // When
        let domainError = sut.map(apiError)

        // Then
        if case let .unknown(message) = domainError {
            XCTAssertTrue(message.contains("Underlying error"))
        } else {
            XCTFail("Expected unknown error with underlying context")
        }
    }

    // MARK: - Multiple Error Aggregation

    func test_mapError_withMultipleValidationErrors_aggregatesMessages() {
        // Given
        let apiError = APIError.validationFailed(fields: [
            "cardNumber": "Invalid format",
            "cvv": "Required",
            "expiry": "Expired"
        ])

        // When
        let domainError = sut.map(apiError)

        // Then
        if case let .validation(errors) = domainError {
            XCTAssertEqual(errors.count, 3)
        } else {
            XCTFail("Expected validation error with 3 field errors")
        }
    }
}

// MARK: - Test API Errors

@available(iOS 15.0, *)
private enum APIError: Error {
    case badRequest(message: String)
    case unauthorized
    case forbidden
    case notFound(resource: String)
    case serverError(statusCode: Int)
    case paymentDeclined(reason: String)
    case validationFailed(fields: [String: String])
    case threeDSFailed(reason: String)
    case unknown(underlying: Error)
}

// MARK: - Domain Errors

@available(iOS 15.0, *)
private enum DomainError {
    case networkUnavailable(message: String)
    case validation(errors: [String])
    case authentication(message: String)
    case authorization(message: String)
    case resourceNotFound(resource: String)
    case serverUnavailable(message: String)
    case paymentDeclined(reason: String)
    case threeDSFailed(reason: String)
    case unknown(message: String)
}

// MARK: - Error Mapper

@available(iOS 15.0, *)
private class ErrorMapper {

    func map(_ error: Error) -> DomainError {
        switch error {
        case TestData.Errors.networkTimeout:
            return .networkUnavailable(message: "Request timeout. Please check your connection and try again.")

        case TestData.Errors.noConnection:
            return .networkUnavailable(message: "No internet connection. Please check your network settings.")

        case let apiError as APIError:
            return mapAPIError(apiError)

        default:
            return .unknown(message: error.localizedDescription)
        }
    }

    private func mapAPIError(_ error: APIError) -> DomainError {
        switch error {
        case let .badRequest(message):
            return .validation(errors: [message])

        case .unauthorized:
            return .authentication(message: "Authentication failed. Please check your credentials.")

        case .forbidden:
            return .authorization(message: "Access forbidden. You don't have permission to perform this action.")

        case let .notFound(resource):
            return .resourceNotFound(resource: resource)

        case let .serverError(statusCode):
            return .serverUnavailable(message: "Server error (\(statusCode)). Please try again later.")

        case let .paymentDeclined(reason):
            return .paymentDeclined(reason: reason)

        case let .validationFailed(fields):
            return .validation(errors: Array(fields.values))

        case let .threeDSFailed(reason):
            return .threeDSFailed(reason: reason)

        case let .unknown(underlying):
            return .unknown(message: underlying.localizedDescription)
        }
    }

    func getUserMessage(for error: DomainError) -> String {
        switch error {
        case let .networkUnavailable(message):
            return message

        case let .validation(errors):
            return errors.first ?? "Validation failed"

        case let .authentication(message):
            return message

        case let .authorization(message):
            return message

        case .resourceNotFound:
            return "The requested resource was not found"

        case .serverUnavailable:
            return "Service temporarily unavailable. Please try again later."

        case let .paymentDeclined(reason):
            if reason == "insufficient_funds" {
                return "Payment declined: Insufficient funds"
            }
            return "Payment declined"

        case .threeDSFailed:
            return "3D Secure authentication failed"

        case .unknown:
            return "An unexpected error occurred"
        }
    }

    func isRecoverable(_ error: DomainError) -> Bool {
        switch error {
        case .networkUnavailable, .serverUnavailable:
            return true

        case .authentication, .authorization, .paymentDeclined, .threeDSFailed:
            return false

        case .validation, .resourceNotFound, .unknown:
            return false
        }
    }
}
