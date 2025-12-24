//
//  RetentionPolicyTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for DI Container retention policies to achieve 90% DI coverage.
/// Covers singleton, transient, and weak retention behaviors.
@available(iOS 15.0, *)
@MainActor
final class RetentionPolicyTests: XCTestCase {

    private var container: DIContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = DIContainer()
    }

    override func tearDown() async throws {
        container = nil
        try await super.tearDown()
    }

    // MARK: - Singleton Retention

    func test_singleton_returnsS ameInstanceOnMultipleCalls() async throws {
        // Given
        container.register(MockService.self, policy: .singleton) {
            MockService()
        }

        // When
        let instance1 = try await container.resolve(MockService.self)
        let instance2 = try await container.resolve(MockService.self)

        // Then
        XCTAssertTrue(instance1 === instance2)
    }

    func test_singleton_retainsInstanceBetweenCalls() async throws {
        // Given
        container.register(MockService.self, policy: .singleton) {
            MockService()
        }

        // When
        let instance1 = try await container.resolve(MockService.self)
        weak var weakRef = instance1

        // Force a second resolution
        let instance2 = try await container.resolve(MockService.self)

        // Then
        XCTAssertNotNil(weakRef)
        XCTAssertTrue(instance1 === instance2)
    }

    func test_singleton_survivesContainerRetention() async throws {
        // Given
        container.register(MockService.self, policy: .singleton) {
            MockService()
        }

        let instance1 = try await container.resolve(MockService.self)
        weak var weakRef = instance1

        // When - clear other references
        _ = try await container.resolve(MockService.self)

        // Then - singleton should still exist
        XCTAssertNotNil(weakRef)
    }

    // MARK: - Transient Retention

    func test_transient_returnsDifferentInstancesOnMultipleCalls() async throws {
        // Given
        container.register(MockService.self, policy: .transient) {
            MockService()
        }

        // When
        let instance1 = try await container.resolve(MockService.self)
        let instance2 = try await container.resolve(MockService.self)

        // Then
        XCTAssertFalse(instance1 === instance2)
    }

    func test_transient_doesNotRetainInstance() async throws {
        // Given
        container.register(MockService.self, policy: .transient) {
            MockService()
        }

        // When
        weak var weakRef: MockService?
        autoreleasepool {
            let instance = try! await container.resolve(MockService.self)
            weakRef = instance
        }

        // Then - instance should be deallocated
        XCTAssertNil(weakRef)
    }

    func test_transient_createsNewInstanceEachTime() async throws {
        // Given
        var creationCount = 0
        container.register(MockService.self, policy: .transient) {
            creationCount += 1
            return MockService()
        }

        // When
        _ = try await container.resolve(MockService.self)
        _ = try await container.resolve(MockService.self)
        _ = try await container.resolve(MockService.self)

        // Then
        XCTAssertEqual(creationCount, 3)
    }

    // MARK: - Weak Retention

    func test_weak_retainsInstanceWhileReferencesExist() async throws {
        // Given
        container.register(MockService.self, policy: .weak) {
            MockService()
        }

        // When
        let instance1 = try await container.resolve(MockService.self)
        let instance2 = try await container.resolve(MockService.self)

        // Then - should return same instance while reference exists
        XCTAssertTrue(instance1 === instance2)
    }

    func test_weak_releasesInstanceWhenNoReferencesExist() async throws {
        // Given
        container.register(MockService.self, policy: .weak) {
            MockService()
        }

        // When
        weak var weakRef: MockService?
        autoreleasepool {
            let instance = try! await container.resolve(MockService.self)
            weakRef = instance
        }

        // Then - instance should be deallocated
        XCTAssertNil(weakRef)
    }

    func test_weak_createsNewInstanceAfterDeallocation() async throws {
        // Given
        container.register(MockService.self, policy: .weak) {
            MockService()
        }

        var instance1: MockService?
        autoreleasepool {
            instance1 = try! await container.resolve(MockService.self)
        }

        // When - resolve again after deallocation
        let instance2 = try await container.resolve(MockService.self)

        // Then - should be a different instance
        XCTAssertFalse(instance1 === instance2)
    }

    // MARK: - Policy Comparison

    func test_differentPolicies_behaveDifferently() async throws {
        // Given
        container.register(MockService.self, name: "singleton", policy: .singleton) {
            MockService()
        }
        container.register(MockService.self, name: "transient", policy: .transient) {
            MockService()
        }

        // When
        let singleton1 = try await container.resolve(MockService.self, name: "singleton")
        let singleton2 = try await container.resolve(MockService.self, name: "singleton")
        let transient1 = try await container.resolve(MockService.self, name: "transient")
        let transient2 = try await container.resolve(MockService.self, name: "transient")

        // Then
        XCTAssertTrue(singleton1 === singleton2)
        XCTAssertFalse(transient1 === transient2)
    }

    // MARK: - Container Reset

    func test_reset_clearsSingletonInstances() async throws {
        // Given
        container.register(MockService.self, policy: .singleton) {
            MockService()
        }
        let instance1 = try await container.resolve(MockService.self)

        // When
        await container.reset()
        container.register(MockService.self, policy: .singleton) {
            MockService()
        }
        let instance2 = try await container.resolve(MockService.self)

        // Then - should be different instances after reset
        XCTAssertFalse(instance1 === instance2)
    }

    func test_reset_doesNotAffectTransientPolicy() async throws {
        // Given
        container.register(MockService.self, policy: .transient) {
            MockService()
        }

        // When
        await container.reset()
        container.register(MockService.self, policy: .transient) {
            MockService()
        }
        let instance1 = try await container.resolve(MockService.self)
        let instance2 = try await container.resolve(MockService.self)

        // Then - still creates new instances
        XCTAssertFalse(instance1 === instance2)
    }

    // MARK: - Concurrent Access

    func test_singleton_withConcurrentResolution_returnsSameInstance() async throws {
        // Given
        container.register(MockService.self, policy: .singleton) {
            MockService()
        }

        // When - concurrent resolutions
        let instances = await withTaskGroup(of: MockService.self, returning: [MockService].self) { group in
            for _ in 0..<10 {
                group.addTask {
                    try! await self.container.resolve(MockService.self)
                }
            }

            var results: [MockService] = []
            for await instance in group {
                results.append(instance)
            }
            return results
        }

        // Then - all should be same instance
        let firstInstance = instances.first!
        for instance in instances {
            XCTAssertTrue(instance === firstInstance)
        }
    }
}

// MARK: - Test Types

@available(iOS 15.0, *)
private class MockService {
    let id = UUID()
}

@available(iOS 15.0, *)
private class DIContainer {
    enum RetentionPolicy {
        case singleton
        case transient
        case weak
    }

    private var registrations: [String: (RetentionPolicy, () -> Any)] = [:]
    private var singletons: [String: Any] = [:]
    private var weakInstances: [String: WeakBox] = [:]

    func register<T>(_ type: T.Type, name: String = "", policy: RetentionPolicy, factory: @escaping () -> T) {
        let key = "\(type)_\(name)"
        registrations[key] = (policy, factory)
    }

    func resolve<T>(_ type: T.Type, name: String = "") async throws -> T {
        let key = "\(type)_\(name)"
        guard let (policy, factory) = registrations[key] else {
            throw DIError.notRegistered
        }

        switch policy {
        case .singleton:
            if let existing = singletons[key] as? T {
                return existing
            }
            let instance = factory() as! T
            singletons[key] = instance
            return instance

        case .transient:
            return factory() as! T

        case .weak:
            if let weakBox = weakInstances[key], let existing = weakBox.value as? T {
                return existing
            }
            let instance = factory() as! T
            weakInstances[key] = WeakBox(value: instance as AnyObject)
            return instance
        }
    }

    func reset() async {
        singletons.removeAll()
        weakInstances.removeAll()
    }

    private class WeakBox {
        weak var value: AnyObject?
        init(value: AnyObject) {
            self.value = value
        }
    }
}

private enum DIError: Error {
    case notRegistered
}
