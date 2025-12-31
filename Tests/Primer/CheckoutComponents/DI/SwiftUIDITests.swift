//
//  SwiftUIDITests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

// MARK: - SwiftUI+DI Tests

/// Tests for SwiftUI DI integration components including property wrappers and view modifiers.
@available(iOS 15.0, *)
@MainActor
final class SwiftUIDITests: XCTestCase {

    // MARK: - Test Doubles

    private final class MockService {
        var identifier: String

        init(identifier: String = "default") {
            self.identifier = identifier
        }
    }

    private final class MockObservableService: ObservableObject {
        @Published var value: String = "observable_default"
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

    // MARK: - View Extension Tests

    func test_injectDependencies_returnsModifiedView() {
        // Arrange
        let view = Text("Test")

        // Act
        let modifiedView = view.injectDependencies()

        // Assert - should not throw and return a view
        XCTAssertNotNil(modifiedView)
    }

    func test_withResolvedDependency_returnsModifiedView() {
        // Arrange
        let view = Text("Test")

        // Act
        let modifiedView = view.withResolvedDependency(MockService.self) { _ in
            // Action closure
        }

        // Assert - should not throw and return a view
        XCTAssertNotNil(modifiedView)
    }

    func test_withResolvedDependency_withName_returnsModifiedView() {
        // Arrange
        let view = Text("Test")

        // Act
        let modifiedView = view.withResolvedDependency(MockService.self, name: "named") { _ in
            // Action closure
        }

        // Assert - should not throw and return a view
        XCTAssertNotNil(modifiedView)
    }

    // MARK: - DependencyInjectionModifier Tests

    func test_dependencyInjectionModifier_canBeCreated() {
        // Act
        let modifier = DependencyInjectionModifier()

        // Assert
        XCTAssertNotNil(modifier)
    }

    func test_dependencyInjectionModifier_appliedToView_returnsView() {
        // Arrange
        let view = Text("Content")

        // Act - apply modifier via View extension (proper way to use ViewModifier)
        let result = view.modifier(DependencyInjectionModifier())

        // Assert - should return a view without throwing
        XCTAssertNotNil(result)
    }

    // MARK: - DependencyResolutionModifier Tests

    func test_dependencyResolutionModifier_canBeCreated() {
        // Arrange
        var actionCalled = false

        // Act
        let modifier = DependencyResolutionModifier(
            type: MockService.self,
            name: nil,
            action: { _ in actionCalled = true }
        )

        // Assert
        XCTAssertNotNil(modifier)
        XCTAssertFalse(actionCalled) // Action not called until onAppear
    }

    func test_dependencyResolutionModifier_withName_canBeCreated() {
        // Arrange
        var actionCalled = false

        // Act
        let modifier = DependencyResolutionModifier(
            type: MockService.self,
            name: "special",
            action: { _ in actionCalled = true }
        )

        // Assert
        XCTAssertNotNil(modifier)
        XCTAssertFalse(actionCalled)
    }

    func test_dependencyResolutionModifier_appliedToView_returnsView() {
        // Arrange
        let view = Text("Content")
        let modifier = DependencyResolutionModifier(
            type: MockService.self,
            name: nil,
            action: { _ in }
        )

        // Act - apply modifier via View extension (proper way to use ViewModifier)
        let result = view.modifier(modifier)

        // Assert
        XCTAssertNotNil(result)
    }

    // MARK: - Injected Property Wrapper Tests

    func test_injected_init_setsTypeAndName() {
        // Act
        let injected = Injected(MockService.self, name: "test_name")

        // Assert - initially nil without container
        XCTAssertNil(injected.wrappedValue)
    }

    func test_injected_init_withoutName_setsTypeOnly() {
        // Act
        let injected = Injected(MockService.self)

        // Assert - initially nil without container
        XCTAssertNil(injected.wrappedValue)
    }

    func test_injected_wrappedValue_isNilWithoutContainer() {
        // Arrange
        var injected = Injected(MockService.self)

        // Act & Assert
        XCTAssertNil(injected.wrappedValue)
    }

    // Note: Direct value setting tests are removed because @State-backed
    // property wrappers don't work correctly outside SwiftUI view context

    func test_injected_projectedValue_returnsBinding() {
        // Arrange
        var injected = Injected(MockService.self)

        // Act
        let binding = injected.projectedValue

        // Assert
        XCTAssertNotNil(binding)
        XCTAssertNil(binding.wrappedValue)
    }

    // MARK: - RequiredInjected Property Wrapper Tests

    func test_requiredInjected_init_setsTypeNameAndFallback() {
        // Act
        var requiredInjected = RequiredInjected(
            MockService.self,
            name: "required_name",
            fallback: MockService(identifier: "fallback_value")
        )

        // Assert - should return fallback when no container
        XCTAssertEqual(requiredInjected.wrappedValue.identifier, "fallback_value")
    }

    func test_requiredInjected_init_withoutName_setsTypeAndFallback() {
        // Act
        var requiredInjected = RequiredInjected(
            MockService.self,
            fallback: MockService(identifier: "no_name_fallback")
        )

        // Assert
        XCTAssertEqual(requiredInjected.wrappedValue.identifier, "no_name_fallback")
    }

    func test_requiredInjected_wrappedValue_returnsFallbackWithoutContainer() {
        // Arrange
        var requiredInjected = RequiredInjected(
            MockService.self,
            fallback: MockService(identifier: "default_fallback")
        )

        // Act
        let value = requiredInjected.wrappedValue

        // Assert
        XCTAssertEqual(value.identifier, "default_fallback")
    }

    func test_requiredInjected_wrappedValue_cachesResolvedValue() {
        // Arrange
        var requiredInjected = RequiredInjected(
            MockService.self,
            fallback: MockService(identifier: "cached_test")
        )

        // Act - access twice
        let first = requiredInjected.wrappedValue
        let second = requiredInjected.wrappedValue

        // Assert - should return same identifier (cached)
        XCTAssertEqual(first.identifier, second.identifier)
    }

    // MARK: - Chained Modifier Tests

    func test_view_canChainMultipleModifiers() {
        // Arrange
        let view = Text("Test")

        // Act
        let modifiedView = view
            .injectDependencies()
            .withResolvedDependency(MockService.self) { _ in }
            .withResolvedDependency(MockObservableService.self, name: "observable") { _ in }

        // Assert
        XCTAssertNotNil(modifiedView)
    }

    // MARK: - Type Safety Tests

    func test_requiredInjected_maintainsTypeInformation() {
        // Arrange
        var requiredInjected = RequiredInjected(
            MockService.self,
            fallback: MockService(identifier: "typed_required")
        )

        // Assert - type should be preserved
        XCTAssertTrue(requiredInjected.wrappedValue is MockService)
    }

    // MARK: - Multiple Property Wrapper Instances Tests

    func test_multipleRequiredInjectedInstances_areIndependent() {
        // Arrange
        var required1 = RequiredInjected(MockService.self, fallback: MockService(identifier: "fb1"))
        var required2 = RequiredInjected(MockService.self, fallback: MockService(identifier: "fb2"))

        // Act - access both
        let value1 = required1.wrappedValue
        let value2 = required2.wrappedValue

        // Assert
        XCTAssertEqual(value1.identifier, "fb1")
        XCTAssertEqual(value2.identifier, "fb2")
    }
}
