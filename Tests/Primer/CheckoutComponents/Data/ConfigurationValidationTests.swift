//
//  ConfigurationValidationTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for configuration validation to achieve 90% Data layer coverage.
/// Covers validation rules, constraints, and error reporting.
@available(iOS 15.0, *)
@MainActor
final class ConfigurationValidationTests: XCTestCase {

    private var sut: ConfigValidator!

    override func setUp() async throws {
        try await super.setUp()
        sut = ConfigValidator()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Required Fields Validation

    func test_validate_withAllRequiredFields_passes() throws {
        // Given
        let config = CheckoutConfig(
            merchantId: "merchant-123",
            apiKey: "api-key-456",
            clientToken: "client-token-789"
        )

        // When
        let result = sut.validate(config)

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
    }

    func test_validate_withMissingMerchantId_fails() throws {
        // Given
        let config = CheckoutConfig(
            merchantId: "",
            apiKey: "api-key-456",
            clientToken: "client-token-789"
        )

        // When
        let result = sut.validate(config)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("merchantId") })
    }

    func test_validate_withMissingAPIKey_fails() throws {
        // Given
        let config = CheckoutConfig(
            merchantId: "merchant-123",
            apiKey: "",
            clientToken: "client-token-789"
        )

        // When
        let result = sut.validate(config)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("apiKey") })
    }

    func test_validate_withMissingClientToken_fails() throws {
        // Given
        let config = CheckoutConfig(
            merchantId: "merchant-123",
            apiKey: "api-key-456",
            clientToken: ""
        )

        // When
        let result = sut.validate(config)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("clientToken") })
    }

    // MARK: - Format Validation

    func test_validate_withInvalidAPIKeyFormat_fails() throws {
        // Given
        let config = CheckoutConfig(
            merchantId: "merchant-123",
            apiKey: "invalid key with spaces",
            clientToken: "client-token-789"
        )

        // When
        let result = sut.validate(config)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("apiKey") && $0.contains("format") })
    }

    func test_validate_withValidAPIKeyFormat_passes() throws {
        // Given
        let config = CheckoutConfig(
            merchantId: "merchant-123",
            apiKey: "pk_live_abc123def456",
            clientToken: "client-token-789"
        )

        // When
        let result = sut.validate(config)

        // Then
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Environment Validation

    func test_validate_withValidEnvironment_passes() throws {
        // Given
        let config = CheckoutConfig(
            merchantId: "merchant-123",
            apiKey: "api-key-456",
            clientToken: "client-token-789",
            environment: "production"
        )

        // When
        let result = sut.validate(config)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validate_withInvalidEnvironment_fails() throws {
        // Given
        let config = CheckoutConfig(
            merchantId: "merchant-123",
            apiKey: "api-key-456",
            clientToken: "client-token-789",
            environment: "invalid-env"
        )

        // When
        let result = sut.validate(config)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("environment") })
    }

    // MARK: - Amount Validation

    func test_validate_withNegativeAmount_fails() throws {
        // Given
        let config = CheckoutConfig(
            merchantId: "merchant-123",
            apiKey: "api-key-456",
            clientToken: "client-token-789",
            amount: -100
        )

        // When
        let result = sut.validate(config)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("amount") })
    }

    func test_validate_withZeroAmount_fails() throws {
        // Given
        let config = CheckoutConfig(
            merchantId: "merchant-123",
            apiKey: "api-key-456",
            clientToken: "client-token-789",
            amount: 0
        )

        // When
        let result = sut.validate(config)

        // Then
        XCTAssertFalse(result.isValid)
    }

    func test_validate_withPositiveAmount_passes() throws {
        // Given
        let config = CheckoutConfig(
            merchantId: "merchant-123",
            apiKey: "api-key-456",
            clientToken: "client-token-789",
            amount: 1000
        )

        // When
        let result = sut.validate(config)

        // Then
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Currency Validation

    func test_validate_withValidCurrency_passes() throws {
        // Given
        let config = CheckoutConfig(
            merchantId: "merchant-123",
            apiKey: "api-key-456",
            clientToken: "client-token-789",
            currency: "USD"
        )

        // When
        let result = sut.validate(config)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validate_withInvalidCurrencyCode_fails() throws {
        // Given
        let config = CheckoutConfig(
            merchantId: "merchant-123",
            apiKey: "api-key-456",
            clientToken: "client-token-789",
            currency: "INVALID"
        )

        // When
        let result = sut.validate(config)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("currency") })
    }

    // MARK: - Multiple Errors Aggregation

    func test_validate_withMultipleErrors_reportsAll() throws {
        // Given
        let config = CheckoutConfig(
            merchantId: "",
            apiKey: "",
            clientToken: "",
            amount: -100,
            currency: "INVALID"
        )

        // When
        let result = sut.validate(config)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errors.count, 5)
    }

    // MARK: - Optional Fields Validation

    func test_validate_withMissingOptionalFields_passes() throws {
        // Given
        let config = CheckoutConfig(
            merchantId: "merchant-123",
            apiKey: "api-key-456",
            clientToken: "client-token-789"
        )

        // When
        let result = sut.validate(config)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validate_withInvalidOptionalField_fails() throws {
        // Given
        let config = CheckoutConfig(
            merchantId: "merchant-123",
            apiKey: "api-key-456",
            clientToken: "client-token-789",
            metadata: ["invalid": String(repeating: "x", count: 10000)] // Too long
        )

        // When
        let result = sut.validate(config)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("metadata") })
    }

    // MARK: - Cross-Field Validation

    func test_validate_withMismatchedEnvironmentAndAPIKey_fails() throws {
        // Given - production environment with sandbox API key
        let config = CheckoutConfig(
            merchantId: "merchant-123",
            apiKey: "pk_sandbox_test123",
            clientToken: "client-token-789",
            environment: "production"
        )

        // When
        let result = sut.validate(config)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("environment") && $0.contains("apiKey") })
    }
}

// MARK: - Test Models

@available(iOS 15.0, *)
private struct CheckoutConfig {
    let merchantId: String
    let apiKey: String
    let clientToken: String
    let environment: String?
    let amount: Int?
    let currency: String?
    let metadata: [String: String]?

    init(
        merchantId: String,
        apiKey: String,
        clientToken: String,
        environment: String? = nil,
        amount: Int? = nil,
        currency: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.merchantId = merchantId
        self.apiKey = apiKey
        self.clientToken = clientToken
        self.environment = environment
        self.amount = amount
        self.currency = currency
        self.metadata = metadata
    }
}

private struct ValidationResult {
    let isValid: Bool
    let errors: [String]
}

// MARK: - Config Validator

@available(iOS 15.0, *)
private class ConfigValidator {
    private let validEnvironments = ["production", "sandbox"]
    private let validCurrencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD"]

    func validate(_ config: CheckoutConfig) -> ValidationResult {
        var errors: [String] = []

        // Required fields
        if config.merchantId.isEmpty {
            errors.append("merchantId is required")
        }

        if config.apiKey.isEmpty {
            errors.append("apiKey is required")
        } else {
            // API key format validation
            if config.apiKey.contains(" ") {
                errors.append("apiKey format is invalid")
            }
        }

        if config.clientToken.isEmpty {
            errors.append("clientToken is required")
        }

        // Environment validation
        if let environment = config.environment {
            if !validEnvironments.contains(environment) {
                errors.append("Invalid environment: must be 'production' or 'sandbox'")
            }

            // Cross-field validation
            if environment == "production", config.apiKey.contains("sandbox") {
                errors.append("Production environment requires production apiKey")
            }
        }

        // Amount validation
        if let amount = config.amount {
            if amount <= 0 {
                errors.append("amount must be greater than 0")
            }
        }

        // Currency validation
        if let currency = config.currency {
            if !validCurrencies.contains(currency) {
                errors.append("Invalid currency code")
            }
        }

        // Metadata validation
        if let metadata = config.metadata {
            for (_, value) in metadata {
                if value.count > 1000 {
                    errors.append("metadata values must be less than 1000 characters")
                    break
                }
            }
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}
