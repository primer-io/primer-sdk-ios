//
//  DIContainerSwiftUITests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

// MARK: - DIContainer+SwiftUI Tests

/// Tests for SwiftUI integration extensions on DIContainer.
/// Tests stateObject creation, resolution, and environment value integration.
@available(iOS 15.0, *)
@MainActor
final class DIContainerSwiftUITests: XCTestCase {

    // MARK: - Test Doubles

    private final class MockObservableService: ObservableObject {
        @Published var value: String = "default"

        init() {}

        init(value: String) {
            self.value = value
        }
    }

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        await DIContainer.clearContainer()
    }

    override func tearDown() async throws {
        await DIContainer.clearContainer()
        try await super.tearDown()
    }

    // MARK: - DIContainerEnvironmentKey Tests

    func test_environmentKey_defaultValue_isNil() {
        let defaultValue = DIContainer.DIContainerEnvironmentKey.defaultValue

        XCTAssertNil(defaultValue)
    }

    // MARK: - stateObject Tests (Static Container)

    func test_stateObject_withAvailableContainer_resolvesFromContainer() async throws {
        // Arrange
        let container = Container()
        let expectedValue = "resolved_value"

        _ = try await container.register(MockObservableService.self)
            .asSingleton()
            .with { _ in MockObservableService(value: expectedValue) }

        await DIContainer.setContainer(container)

        // Act
        let stateObject = DIContainer.stateObject(
            MockObservableService.self,
            default: MockObservableService(value: "fallback")
        )

        // Assert
        XCTAssertEqual(stateObject.wrappedValue.value, expectedValue)
    }

    func test_stateObject_withUnavailableContainer_usesFallback() async {
        // Arrange - no container set
        await DIContainer.clearContainer()

        // Act
        let stateObject = DIContainer.stateObject(
            MockObservableService.self,
            default: MockObservableService(value: "fallback_value")
        )

        // Assert
        XCTAssertEqual(stateObject.wrappedValue.value, "fallback_value")
    }

    func test_stateObject_withResolutionFailure_usesFallback() async throws {
        // Arrange - container exists but type not registered
        let container = Container()
        await DIContainer.setContainer(container)

        // Act
        let stateObject = DIContainer.stateObject(
            MockObservableService.self,
            default: MockObservableService(value: "fallback_on_failure")
        )

        // Assert
        XCTAssertEqual(stateObject.wrappedValue.value, "fallback_on_failure")
    }

    func test_stateObject_withName_resolvesNamedDependency() async throws {
        // Arrange
        let container = Container()
        let expectedValue = "named_value"

        _ = try await container.register(MockObservableService.self)
            .named("special")
            .asSingleton()
            .with { _ in MockObservableService(value: expectedValue) }

        await DIContainer.setContainer(container)

        // Act
        let stateObject = DIContainer.stateObject(
            MockObservableService.self,
            name: "special",
            default: MockObservableService(value: "fallback")
        )

        // Assert
        XCTAssertEqual(stateObject.wrappedValue.value, expectedValue)
    }

    // MARK: - stateObject Tests (From EnvironmentValues)

    func test_stateObject_fromEnvironment_resolvesFromEnvironmentContainer() async throws {
        // Arrange
        let container = Container()
        let expectedValue = "env_resolved"

        _ = try await container.register(MockObservableService.self)
            .asSingleton()
            .with { _ in MockObservableService(value: expectedValue) }

        var environment = EnvironmentValues()
        environment.diContainer = container

        // Act
        let stateObject = DIContainer.stateObject(
            MockObservableService.self,
            from: environment,
            default: MockObservableService(value: "fallback")
        )

        // Assert
        XCTAssertEqual(stateObject.wrappedValue.value, expectedValue)
    }

    func test_stateObject_fromEnvironment_withoutContainer_usesFallback() {
        // Arrange - environment without container
        let environment = EnvironmentValues()

        // Act
        let stateObject = DIContainer.stateObject(
            MockObservableService.self,
            from: environment,
            default: MockObservableService(value: "env_fallback")
        )

        // Assert
        XCTAssertEqual(stateObject.wrappedValue.value, "env_fallback")
    }

    func test_stateObject_fromEnvironment_withResolutionFailure_usesFallback() async throws {
        // Arrange - container without the type registered
        let container = Container()
        var environment = EnvironmentValues()
        environment.diContainer = container

        // Act
        let stateObject = DIContainer.stateObject(
            MockObservableService.self,
            from: environment,
            default: MockObservableService(value: "env_fallback_on_failure")
        )

        // Assert
        XCTAssertEqual(stateObject.wrappedValue.value, "env_fallback_on_failure")
    }

    func test_stateObject_fromEnvironment_withName_resolvesNamedDependency() async throws {
        // Arrange
        let container = Container()
        let expectedValue = "env_named_value"

        _ = try await container.register(MockObservableService.self)
            .named("env_special")
            .asSingleton()
            .with { _ in MockObservableService(value: expectedValue) }

        var environment = EnvironmentValues()
        environment.diContainer = container

        // Act
        let stateObject = DIContainer.stateObject(
            MockObservableService.self,
            name: "env_special",
            from: environment,
            default: MockObservableService(value: "fallback")
        )

        // Assert
        XCTAssertEqual(stateObject.wrappedValue.value, expectedValue)
    }

    // MARK: - resolve Tests

    func test_resolve_withAvailableContainer_returnsResolvedInstance() async throws {
        // Arrange
        let container = Container()
        let expectedValue = "resolve_test"

        _ = try await container.register(MockObservableService.self)
            .asSingleton()
            .with { _ in MockObservableService(value: expectedValue) }

        var environment = EnvironmentValues()
        environment.diContainer = container

        // Act
        let resolved = try DIContainer.resolve(MockObservableService.self, from: environment)

        // Assert
        XCTAssertEqual(resolved.value, expectedValue)
    }

    func test_resolve_withoutContainer_throwsContainerUnavailable() {
        // Arrange
        let environment = EnvironmentValues()

        // Act & Assert
        XCTAssertThrowsError(
            try DIContainer.resolve(MockObservableService.self, from: environment)
        ) { error in
            guard let containerError = error as? ContainerError else {
                XCTFail("Expected ContainerError but got \(type(of: error))")
                return
            }
            if case .containerUnavailable = containerError {
                // Expected error type
            } else {
                XCTFail("Expected containerUnavailable but got \(containerError)")
            }
        }
    }

    func test_resolve_withName_resolvesNamedDependency() async throws {
        // Arrange
        let container = Container()

        _ = try await container.register(MockObservableService.self)
            .named("named_resolve")
            .asSingleton()
            .with { _ in MockObservableService(value: "named_resolved") }

        var environment = EnvironmentValues()
        environment.diContainer = container

        // Act
        let resolved = try DIContainer.resolve(
            MockObservableService.self,
            from: environment,
            name: "named_resolve"
        )

        // Assert
        XCTAssertEqual(resolved.value, "named_resolved")
    }

    func test_resolve_withUnregisteredType_throwsError() async throws {
        // Arrange
        let container = Container()
        var environment = EnvironmentValues()
        environment.diContainer = container

        // Act & Assert
        XCTAssertThrowsError(
            try DIContainer.resolve(MockObservableService.self, from: environment)
        )
    }

    // MARK: - EnvironmentValues Extension Tests

    func test_environmentValues_diContainer_defaultIsNil() {
        let environment = EnvironmentValues()

        XCTAssertNil(environment.diContainer)
    }

    func test_environmentValues_diContainer_canSetAndGet() async {
        // Arrange
        let container = Container()
        var environment = EnvironmentValues()

        // Act
        environment.diContainer = container

        // Assert
        XCTAssertNotNil(environment.diContainer)
    }

    func test_environmentValues_diContainer_canBeCleared() async {
        // Arrange
        let container = Container()
        var environment = EnvironmentValues()
        environment.diContainer = container

        // Act
        environment.diContainer = nil

        // Assert
        XCTAssertNil(environment.diContainer)
    }

    // MARK: - Type Inference Tests

    func test_stateObject_typeInference_worksCorrectly() async throws {
        // Arrange
        let container = Container()

        _ = try await container.register(MockObservableService.self)
            .asSingleton()
            .with { _ in MockObservableService(value: "inferred") }

        await DIContainer.setContainer(container)

        // Act - type should be inferred from return type
        let stateObject: StateObject<MockObservableService> = DIContainer.stateObject(
            default: MockObservableService(value: "fallback")
        )

        // Assert
        XCTAssertEqual(stateObject.wrappedValue.value, "inferred")
    }
}
