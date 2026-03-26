//
//  DIContainerSwiftUITests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

// MARK: - DIContainer+SwiftUI Tests

@available(iOS 15.0, *)
@MainActor
final class DIContainerSwiftUITests: XCTestCase {

    // MARK: - Test Doubles

    private final class MockObservableService: ObservableObject {
        @Published var value: String = TestData.DI.defaultValue

        init() {}

        init(value: String) {
            self.value = value
        }
    }

    // MARK: - Setup / Teardown

    private var savedContainer: ContainerProtocol?

    override func setUp() async throws {
        try await super.setUp()
        savedContainer = await DIContainer.current
        await DIContainer.clearContainer()
    }

    override func tearDown() async throws {
        if let savedContainer {
            await DIContainer.setContainer(savedContainer)
        } else {
            await DIContainer.clearContainer()
        }
        try await super.tearDown()
    }

    // MARK: - stateObject Tests (Static Container)

    func test_stateObject_withAvailableContainer_resolvesFromContainer() async throws {
        // Arrange
        let container = Container()
        let expectedValue = TestData.DI.resolvedValue

        _ = try await container.register(MockObservableService.self)
            .asSingleton()
            .with { _ in MockObservableService(value: expectedValue) }

        await DIContainer.setContainer(container)

        // Act
        let stateObject = DIContainer.stateObject(
            MockObservableService.self,
            default: MockObservableService(value: TestData.DI.fallbackValue)
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
            default: MockObservableService(value: TestData.DI.fallbackValueAlternate)
        )

        // Assert
        XCTAssertEqual(stateObject.wrappedValue.value, TestData.DI.fallbackValueAlternate)
    }

    // MARK: - stateObject Tests (From EnvironmentValues)

    func test_stateObject_fromEnvironment_resolvesFromEnvironmentContainer() async throws {
        // Arrange
        let container = Container()
        let expectedValue = TestData.DI.envResolvedValue

        _ = try await container.register(MockObservableService.self)
            .asSingleton()
            .with { _ in MockObservableService(value: expectedValue) }

        var environment = EnvironmentValues()
        environment.diContainer = container

        // Act
        let stateObject = DIContainer.stateObject(
            MockObservableService.self,
            from: environment,
            default: MockObservableService(value: TestData.DI.fallbackValue)
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
            default: MockObservableService(value: TestData.DI.envFallbackValue)
        )

        // Assert
        XCTAssertEqual(stateObject.wrappedValue.value, TestData.DI.envFallbackValue)
    }

    // MARK: - resolve Tests

    func test_resolve_withAvailableContainer_returnsResolvedInstance() async throws {
        // Arrange
        let container = Container()
        let expectedValue = TestData.DI.resolveTestValue

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

}
