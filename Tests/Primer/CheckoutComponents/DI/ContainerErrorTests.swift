//
//  ContainerErrorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class ContainerErrorTests: XCTestCase {

    // MARK: - errorDescription Tests

    func test_dependencyNotRegistered_withNoSuggestions_returnsTypeInfo() {
        // Given
        let key = TypeKey(String.self)
        let error = ContainerError.dependencyNotRegistered(key)

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Dependency not registered"))
        XCTAssertTrue(description!.contains("\(key)"))
    }

    func test_dependencyNotRegistered_withSuggestions_includesSuggestions() {
        // Given
        let key = TypeKey(String.self)
        let error = ContainerError.dependencyNotRegistered(key, suggestions: ["StringService", "StringProvider"])

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Suggestions"))
        XCTAssertTrue(description!.contains("StringService"))
        XCTAssertTrue(description!.contains("StringProvider"))
    }

    func test_circularDependency_includesResolutionPath() {
        // Given
        let key = TypeKey(String.self)
        let path = [TypeKey(Int.self), TypeKey(Double.self), TypeKey(String.self)]
        let error = ContainerError.circularDependency(key, path: path)

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Circular dependency"))
        XCTAssertTrue(description!.contains("Resolution path"))
    }

    func test_containerUnavailable_returnsDescription() {
        // Given
        let error = ContainerError.containerUnavailable

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("terminated"))
    }

    func test_scopeNotFound_withNoAvailableScopes_returnsBasicMessage() {
        // Given
        let error = ContainerError.scopeNotFound("checkout")

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Scope not found"))
        XCTAssertTrue(description!.contains("checkout"))
    }

    func test_scopeNotFound_withAvailableScopes_listsAvailable() {
        // Given
        let error = ContainerError.scopeNotFound("payment", availableScopes: ["checkout", "card"])

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Available scopes"))
        XCTAssertTrue(description!.contains("checkout"))
        XCTAssertTrue(description!.contains("card"))
    }

    func test_typeCastFailed_includesExpectedAndActual() {
        // Given
        let key = TypeKey(String.self)
        let error = ContainerError.typeCastFailed(key, expected: String(describing: String.self), actual: String(describing: Int.self))

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Type cast failed"))
        XCTAssertTrue(description!.contains("Expected"))
        XCTAssertTrue(description!.contains("Actual"))
    }

    func test_factoryFailed_includesUnderlyingError() {
        // Given
        let key = TypeKey(String.self)
        let underlying = TestError.networkFailure
        let error = ContainerError.factoryFailed(key, underlyingError: underlying)

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Factory"))
        XCTAssertTrue(description!.contains("failed"))
    }

    func test_weakUnsupported_returnsDescription() {
        // Given
        let key = TypeKey(Int.self)
        let error = ContainerError.weakUnsupported(key)

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("weakly cache"))
        XCTAssertTrue(description!.contains("not a class type"))
    }

    // MARK: - recoverySuggestion Tests

    func test_dependencyNotRegistered_hasRecoverySuggestion() {
        let error = ContainerError.dependencyNotRegistered(TypeKey(String.self))
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion!.contains("Register"))
    }

    func test_circularDependency_hasRecoverySuggestion() {
        let error = ContainerError.circularDependency(TypeKey(String.self), path: [])
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion!.contains("circular"))
    }

    func test_typeCastFailed_hasRecoverySuggestion() {
        let error = ContainerError.typeCastFailed(TypeKey(String.self), expected: String(describing: String.self), actual: String(describing: Int.self))
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func test_weakUnsupported_hasRecoverySuggestion() {
        let error = ContainerError.weakUnsupported(TypeKey(Int.self))
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion!.contains("singleton"))
    }

    func test_containerUnavailable_hasNoRecoverySuggestion() {
        let error = ContainerError.containerUnavailable
        XCTAssertNil(error.recoverySuggestion)
    }

    func test_scopeNotFound_hasNoRecoverySuggestion() {
        let error = ContainerError.scopeNotFound("test")
        XCTAssertNil(error.recoverySuggestion)
    }

    func test_factoryFailed_hasNoRecoverySuggestion() {
        let error = ContainerError.factoryFailed(TypeKey(String.self), underlyingError: TestError.unknown)
        XCTAssertNil(error.recoverySuggestion)
    }

    // MARK: - isUserError Tests

    func test_dependencyNotRegistered_isUserError() {
        let error = ContainerError.dependencyNotRegistered(TypeKey(String.self))
        XCTAssertTrue(error.isUserError)
        XCTAssertFalse(error.isSystemError)
    }

    func test_typeCastFailed_isUserError() {
        let error = ContainerError.typeCastFailed(TypeKey(String.self), expected: String(describing: String.self), actual: String(describing: Int.self))
        XCTAssertTrue(error.isUserError)
    }

    func test_weakUnsupported_isUserError() {
        let error = ContainerError.weakUnsupported(TypeKey(Int.self))
        XCTAssertTrue(error.isUserError)
    }

    func test_circularDependency_isNotUserError() {
        let error = ContainerError.circularDependency(TypeKey(String.self), path: [])
        XCTAssertFalse(error.isUserError)
    }

    func test_factoryFailed_isNotUserError() {
        let error = ContainerError.factoryFailed(TypeKey(String.self), underlyingError: TestError.unknown)
        XCTAssertFalse(error.isUserError)
    }

    // MARK: - isSystemError Tests

    func test_containerUnavailable_isSystemError() {
        let error = ContainerError.containerUnavailable
        XCTAssertTrue(error.isSystemError)
        XCTAssertFalse(error.isUserError)
    }

    func test_dependencyNotRegistered_isNotSystemError() {
        let error = ContainerError.dependencyNotRegistered(TypeKey(String.self))
        XCTAssertFalse(error.isSystemError)
    }

    func test_circularDependency_isNotSystemError() {
        let error = ContainerError.circularDependency(TypeKey(String.self), path: [])
        XCTAssertFalse(error.isSystemError)
    }

    func test_scopeNotFound_isNotSystemError() {
        let error = ContainerError.scopeNotFound("test")
        XCTAssertFalse(error.isSystemError)
    }
}
