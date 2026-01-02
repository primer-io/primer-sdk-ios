//
//  ContainerErrorTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for ContainerError enum covering all error cases and their properties.
@available(iOS 15.0, *)
final class ContainerErrorTests: XCTestCase {

    // MARK: - Test Types

    private protocol TestProtocol {}
    private final class TestClass: TestProtocol {}
    private struct TestStruct {}

    // MARK: - Error Description Tests

    func test_dependencyNotRegistered_errorDescription_withoutSuggestions() {
        // Given
        let key = TypeKey(TestProtocol.self)
        let error = ContainerError.dependencyNotRegistered(key)

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Dependency not registered"))
        XCTAssertTrue(description!.contains("TestProtocol"))
        XCTAssertFalse(description!.contains("Suggestions"))
    }

    func test_dependencyNotRegistered_errorDescription_withSuggestions() {
        // Given
        let key = TypeKey(TestProtocol.self)
        let suggestions = ["ValidationService", "RulesFactory"]
        let error = ContainerError.dependencyNotRegistered(key, suggestions: suggestions)

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Suggestions"))
        XCTAssertTrue(description!.contains("ValidationService"))
        XCTAssertTrue(description!.contains("RulesFactory"))
    }

    func test_circularDependency_errorDescription() {
        // Given
        let key = TypeKey(TestProtocol.self)
        let path = [TypeKey(TestClass.self), TypeKey(TestStruct.self)]
        let error = ContainerError.circularDependency(key, path: path)

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Circular dependency detected"))
        XCTAssertTrue(description!.contains("TestProtocol"))
        XCTAssertTrue(description!.contains("Resolution path"))
        XCTAssertTrue(description!.contains("→"))
    }

    func test_containerUnavailable_errorDescription() {
        // Given
        let error = ContainerError.containerUnavailable

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("terminated"))
        XCTAssertTrue(description!.contains("no longer available"))
    }

    func test_scopeNotFound_errorDescription_withoutAvailableScopes() {
        // Given
        let error = ContainerError.scopeNotFound("checkout")

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Scope not found"))
        XCTAssertTrue(description!.contains("checkout"))
        XCTAssertFalse(description!.contains("Available scopes"))
    }

    func test_scopeNotFound_errorDescription_withAvailableScopes() {
        // Given
        let availableScopes = ["payment", "card", "vault"]
        let error = ContainerError.scopeNotFound("checkout", availableScopes: availableScopes)

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Scope not found"))
        XCTAssertTrue(description!.contains("Available scopes"))
        XCTAssertTrue(description!.contains("payment"))
        XCTAssertTrue(description!.contains("card"))
        XCTAssertTrue(description!.contains("vault"))
    }

    func test_typeCastFailed_errorDescription() {
        // Given
        let key = TypeKey(TestProtocol.self)
        let error = ContainerError.typeCastFailed(key, expected: TestProtocol.self, actual: TestStruct.self)

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Type cast failed"))
        XCTAssertTrue(description!.contains("Expected"))
        XCTAssertTrue(description!.contains("Actual"))
    }

    func test_factoryFailed_errorDescription() {
        // Given
        let key = TypeKey(TestProtocol.self)
        let underlyingError = NSError(domain: "TestDomain", code: 42, userInfo: [NSLocalizedDescriptionKey: "Test failure"])
        let error = ContainerError.factoryFailed(key, underlyingError: underlyingError)

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Factory"))
        XCTAssertTrue(description!.contains("failed"))
        XCTAssertTrue(description!.contains("Test failure"))
    }

    func test_weakUnsupported_errorDescription() {
        // Given
        let key = TypeKey(TestStruct.self)
        let error = ContainerError.weakUnsupported(key)

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("weakly cache"))
        XCTAssertTrue(description!.contains("not a class type"))
    }

    // MARK: - Recovery Suggestion Tests

    func test_dependencyNotRegistered_recoverySuggestion() {
        // Given
        let key = TypeKey(TestProtocol.self)
        let error = ContainerError.dependencyNotRegistered(key)

        // When
        let suggestion = error.recoverySuggestion

        // Then
        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion!.contains("register"))
    }

    func test_circularDependency_recoverySuggestion() {
        // Given
        let key = TypeKey(TestProtocol.self)
        let error = ContainerError.circularDependency(key, path: [])

        // When
        let suggestion = error.recoverySuggestion

        // Then
        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion!.contains("Break the circular dependency"))
    }

    func test_typeCastFailed_recoverySuggestion() {
        // Given
        let key = TypeKey(TestProtocol.self)
        let error = ContainerError.typeCastFailed(key, expected: TestProtocol.self, actual: TestStruct.self)

        // When
        let suggestion = error.recoverySuggestion

        // Then
        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion!.contains("registered type matches"))
    }

    func test_weakUnsupported_recoverySuggestion() {
        // Given
        let key = TypeKey(TestStruct.self)
        let error = ContainerError.weakUnsupported(key)

        // When
        let suggestion = error.recoverySuggestion

        // Then
        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion!.contains("singleton") || suggestion!.contains("transient"))
    }

    func test_containerUnavailable_recoverySuggestion_isNil() {
        // Given
        let error = ContainerError.containerUnavailable

        // When
        let suggestion = error.recoverySuggestion

        // Then
        XCTAssertNil(suggestion)
    }

    func test_scopeNotFound_recoverySuggestion_isNil() {
        // Given
        let error = ContainerError.scopeNotFound("test")

        // When
        let suggestion = error.recoverySuggestion

        // Then
        XCTAssertNil(suggestion)
    }

    func test_factoryFailed_recoverySuggestion_isNil() {
        // Given
        let key = TypeKey(TestProtocol.self)
        let underlyingError = NSError(domain: "Test", code: 0)
        let error = ContainerError.factoryFailed(key, underlyingError: underlyingError)

        // When
        let suggestion = error.recoverySuggestion

        // Then
        XCTAssertNil(suggestion)
    }

    // MARK: - Error Classification Tests

    func test_isUserError_returnsTrue_forUserErrors() {
        // Given
        let key = TypeKey(TestProtocol.self)
        let userErrors: [ContainerError] = [
            .dependencyNotRegistered(key),
            .typeCastFailed(key, expected: TestProtocol.self, actual: TestStruct.self),
            .weakUnsupported(key)
        ]

        // When/Then
        for error in userErrors {
            XCTAssertTrue(error.isUserError, "Expected \(error) to be a user error")
        }
    }

    func test_isUserError_returnsFalse_forNonUserErrors() {
        // Given
        let key = TypeKey(TestProtocol.self)
        let nonUserErrors: [ContainerError] = [
            .circularDependency(key, path: []),
            .containerUnavailable,
            .scopeNotFound("test"),
            .factoryFailed(key, underlyingError: NSError(domain: "Test", code: 0))
        ]

        // When/Then
        for error in nonUserErrors {
            XCTAssertFalse(error.isUserError, "Expected \(error) to not be a user error")
        }
    }

    func test_isSystemError_returnsTrue_forContainerUnavailable() {
        // Given
        let error = ContainerError.containerUnavailable

        // When/Then
        XCTAssertTrue(error.isSystemError)
    }

    func test_isSystemError_returnsFalse_forOtherErrors() {
        // Given
        let key = TypeKey(TestProtocol.self)
        let nonSystemErrors: [ContainerError] = [
            .dependencyNotRegistered(key),
            .circularDependency(key, path: []),
            .scopeNotFound("test"),
            .typeCastFailed(key, expected: TestProtocol.self, actual: TestStruct.self),
            .factoryFailed(key, underlyingError: NSError(domain: "Test", code: 0)),
            .weakUnsupported(key)
        ]

        // When/Then
        for error in nonSystemErrors {
            XCTAssertFalse(error.isSystemError, "Expected \(error) to not be a system error")
        }
    }

    // MARK: - LocalizedError Conformance Tests

    func test_conformsToLocalizedError() {
        // Given
        let key = TypeKey(TestProtocol.self)
        let error: Error = ContainerError.dependencyNotRegistered(key)

        // When
        let localizedError = error as? LocalizedError

        // Then
        XCTAssertNotNil(localizedError)
        XCTAssertNotNil(localizedError?.errorDescription)
    }

    // MARK: - Sendable Conformance Tests

    func test_canBeSentAcrossConcurrencyBoundaries() async {
        // Given
        let key = TypeKey(TestProtocol.self)
        let error = ContainerError.dependencyNotRegistered(key)

        // When - send across concurrency boundary
        let result = await Task.detached { () -> ContainerError in
            return error
        }.value

        // Then
        XCTAssertNotNil(result.errorDescription)
    }
}
