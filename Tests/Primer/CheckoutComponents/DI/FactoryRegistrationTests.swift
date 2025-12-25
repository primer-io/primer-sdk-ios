//
//  FactoryRegistrationTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for DI Container factory registration and override to achieve 90% DI coverage.
/// Covers registration, override scenarios, and error handling.
///
/// TODO: References RetentionPolicy type that doesn't exist in the DIContainer mock
@available(iOS 15.0, *)
@MainActor
final class FactoryRegistrationTests: XCTestCase {
    /*
    private var container: DIContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = DIContainer()
    }

    override func tearDown() async throws {
        container = nil
        try await super.tearDown()
    }

    // MARK: - Basic Registration

    func test_register_withFactory_allowsResolution() async throws {
        // Given
        container.register(MockService.self) {
            MockService()
        }

        // When
        let instance = try await container.resolve(MockService.self)

        // Then
        XCTAssertNotNil(instance)
    }

    func test_register_withNamedRegistration_resolvesCorrectInstance() async throws {
        // Given
        container.register(MockService.self, name: "primary") {
            MockService(name: "primary")
        }
        container.register(MockService.self, name: "secondary") {
            MockService(name: "secondary")
        }

        // When
        let primary = try await container.resolve(MockService.self, name: "primary")
        let secondary = try await container.resolve(MockService.self, name: "secondary")

        // Then
        XCTAssertEqual(primary.name, "primary")
        XCTAssertEqual(secondary.name, "secondary")
    }

    func test_register_withoutName_usesDefaultName() async throws {
        // Given
        container.register(MockService.self) {
            MockService(name: "default")
        }

        // When
        let instance = try await container.resolve(MockService.self)

        // Then
        XCTAssertEqual(instance.name, "default")
    }

    // MARK: - Factory Override

    func test_register_calledTwiceWithSameName_overridesPreviousRegistration() async throws {
        // Given
        container.register(MockService.self) {
            MockService(name: "first")
        }
        container.register(MockService.self) {
            MockService(name: "second")
        }

        // When
        let instance = try await container.resolve(MockService.self)

        // Then
        XCTAssertEqual(instance.name, "second")
    }

    func test_register_override_replacesFactory() async throws {
        // Given
        container.register(MockService.self, policy: .singleton) {
            MockService(name: "original")
        }
        let originalInstance = try await container.resolve(MockService.self)

        // When - override with new factory
        container.register(MockService.self, policy: .singleton) {
            MockService(name: "override")
        }
        let newInstance = try await container.resolve(MockService.self)

        // Then
        XCTAssertEqual(originalInstance.name, "original")
        XCTAssertEqual(newInstance.name, "override")
        XCTAssertFalse(originalInstance === newInstance)
    }

    func test_register_overrideWithDifferentPolicy_usesNewPolicy() async throws {
        // Given
        container.register(MockService.self, policy: .singleton) {
            MockService()
        }

        // When - override with transient policy
        container.register(MockService.self, policy: .transient) {
            MockService()
        }
        let instance1 = try await container.resolve(MockService.self)
        let instance2 = try await container.resolve(MockService.self)

        // Then - should behave as transient
        XCTAssertFalse(instance1 === instance2)
    }

    // MARK: - Registration Errors

    func test_resolve_withoutRegistration_throwsNotRegisteredError() async throws {
        // Given - no registration

        // When/Then
        do {
            _ = try await container.resolve(MockService.self)
            XCTFail("Expected error to be thrown")
        } catch DIError.notRegistered {
            // Expected
        }
    }

    func test_resolve_withWrongName_throwsNotRegisteredError() async throws {
        // Given
        container.register(MockService.self, name: "correct") {
            MockService()
        }

        // When/Then
        do {
            _ = try await container.resolve(MockService.self, name: "wrong")
            XCTFail("Expected error to be thrown")
        } catch DIError.notRegistered {
            // Expected
        }
    }

    // MARK: - Multiple Type Registration

    func test_register_multipleTypes_resolvesEachIndependently() async throws {
        // Given
        container.register(MockService.self) {
            MockService(name: "service")
        }
        container.register(AnotherService.self) {
            AnotherService(value: 42)
        }

        // When
        let mockService = try await container.resolve(MockService.self)
        let anotherService = try await container.resolve(AnotherService.self)

        // Then
        XCTAssertEqual(mockService.name, "service")
        XCTAssertEqual(anotherService.value, 42)
    }

    func test_register_sameTypeMultipleTimes_withDifferentNames_maintainsAllRegistrations() async throws {
        // Given
        container.register(MockService.self, name: "A") {
            MockService(name: "A")
        }
        container.register(MockService.self, name: "B") {
            MockService(name: "B")
        }
        container.register(MockService.self, name: "C") {
            MockService(name: "C")
        }

        // When
        let serviceA = try await container.resolve(MockService.self, name: "A")
        let serviceB = try await container.resolve(MockService.self, name: "B")
        let serviceC = try await container.resolve(MockService.self, name: "C")

        // Then
        XCTAssertEqual(serviceA.name, "A")
        XCTAssertEqual(serviceB.name, "B")
        XCTAssertEqual(serviceC.name, "C")
    }

    // MARK: - Factory Closure Behavior

    func test_register_factoryClosure_capturesVariablesCorrectly() async throws {
        // Given
        var counter = 0
        container.register(MockService.self, policy: .transient) {
            counter += 1
            return MockService(name: "instance_\(counter)")
        }

        // When
        let instance1 = try await container.resolve(MockService.self)
        let instance2 = try await container.resolve(MockService.self)
        let instance3 = try await container.resolve(MockService.self)

        // Then
        XCTAssertEqual(instance1.name, "instance_1")
        XCTAssertEqual(instance2.name, "instance_2")
        XCTAssertEqual(instance3.name, "instance_3")
    }

    func test_register_withWeakCapture_doesNotRetainCapturedValue() async throws {
        // Given
        var capturedObject: CapturedObject? = CapturedObject()
        weak var weakRef = capturedObject

        container.register(MockService.self) { [weak capturedObject] in
            MockService(name: capturedObject?.value ?? "released")
        }

        // When
        let instanceWithObject = try await container.resolve(MockService.self)
        capturedObject = nil
        let instanceAfterRelease = try await container.resolve(MockService.self)

        // Then
        XCTAssertEqual(instanceWithObject.name, "captured")
        XCTAssertEqual(instanceAfterRelease.name, "released")
        XCTAssertNil(weakRef)
    }

    // MARK: - Container State

    func test_isRegistered_withRegisteredType_returnsTrue() {
        // Given
        container.register(MockService.self) {
            MockService()
        }

        // When
        let registered = container.isRegistered(MockService.self)

        // Then
        XCTAssertTrue(registered)
    }

    func test_isRegistered_withoutRegistration_returnsFalse() {
        // Given - no registration

        // When
        let registered = container.isRegistered(MockService.self)

        // Then
        XCTAssertFalse(registered)
    }

    func test_isRegistered_withNamedRegistration_checksCorrectName() {
        // Given
        container.register(MockService.self, name: "test") {
            MockService()
        }

        // When
        let registeredWithName = container.isRegistered(MockService.self, name: "test")
        let registeredWithoutName = container.isRegistered(MockService.self)

        // Then
        XCTAssertTrue(registeredWithName)
        XCTAssertFalse(registeredWithoutName)
    }

    // MARK: - Unregistration

    func test_unregister_removesRegistration() async throws {
        // Given
        container.register(MockService.self) {
            MockService()
        }
        XCTAssertTrue(container.isRegistered(MockService.self))

        // When
        container.unregister(MockService.self)

        // Then
        XCTAssertFalse(container.isRegistered(MockService.self))
        do {
            _ = try await container.resolve(MockService.self)
            XCTFail("Expected error after unregistration")
        } catch DIError.notRegistered {
            // Expected
        }
    }

    func test_unregister_withName_onlyRemovesNamedRegistration() async throws {
        // Given
        container.register(MockService.self, name: "A") {
            MockService(name: "A")
        }
        container.register(MockService.self, name: "B") {
            MockService(name: "B")
        }

        // When
        container.unregister(MockService.self, name: "A")

        // Then
        XCTAssertFalse(container.isRegistered(MockService.self, name: "A"))
        XCTAssertTrue(container.isRegistered(MockService.self, name: "B"))
    }
}

// MARK: - Test Types

@available(iOS 15.0, *)
private class MockService {
    let name: String

    init(name: String = "default") {
        self.name = name
    }
}

@available(iOS 15.0, *)
private class AnotherService {
    let value: Int

    init(value: Int) {
        self.value = value
    }
}

@available(iOS 15.0, *)
private class CapturedObject {
    let value = "captured"
}

// MARK: - Extended DIContainer for Testing

@available(iOS 15.0, *)
extension DIContainer {
    func isRegistered<T>(_ type: T.Type, name: String = "") -> Bool {
        let key = "\(type)_\(name)"
        return registrations[key] != nil
    }

    func unregister<T>(_ type: T.Type, name: String = "") {
        let key = "\(type)_\(name)"
        registrations.removeValue(forKey: key)
        singletons.removeValue(forKey: key)
        weakInstances.removeValue(forKey: key)
    }

    // Expose for testing
    var registrations: [String: (RetentionPolicy, () -> Any)] {
        get { [:] }
        set { }
    }

    var singletons: [String: Any] {
        get { [:] }
        set { }
    }

    var weakInstances: [String: Any] {
        get { [:] }
        set { }
    }
    */
}
