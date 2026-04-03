//
//  RetentionPolicyTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class RetentionPolicyTests: XCTestCase {

    // MARK: - Singleton Retention

    func test_singleton_returnsSameInstanceOnMultipleCalls() async throws {
        let container = Container()
        _ = try await container.register(MockRetentionService.self).asSingleton().with { _ in MockRetentionService() }

        let instance1 = try await container.resolve(MockRetentionService.self)
        let instance2 = try await container.resolve(MockRetentionService.self)

        XCTAssertTrue(instance1 === instance2)
    }

    func test_singleton_retainsInstanceBetweenCalls() async throws {
        let container = Container()
        _ = try await container.register(MockRetentionService.self).asSingleton().with { _ in MockRetentionService() }

        let instance1 = try await container.resolve(MockRetentionService.self)
        weak var weakRef = instance1
        let instance2 = try await container.resolve(MockRetentionService.self)

        XCTAssertNotNil(weakRef)
        XCTAssertTrue(instance1 === instance2)
    }

    func test_singleton_survivesContainerRetention() async throws {
        let container = Container()
        _ = try await container.register(MockRetentionService.self).asSingleton().with { _ in MockRetentionService() }

        let instance1 = try await container.resolve(MockRetentionService.self)
        weak var weakRef = instance1
        _ = try await container.resolve(MockRetentionService.self)

        XCTAssertNotNil(weakRef)
    }

    // MARK: - Transient Retention

    func test_transient_returnsDifferentInstancesOnMultipleCalls() async throws {
        let container = Container()
        _ = try await container.register(MockRetentionService.self).asTransient().with { _ in MockRetentionService() }

        let instance1 = try await container.resolve(MockRetentionService.self)
        let instance2 = try await container.resolve(MockRetentionService.self)

        XCTAssertFalse(instance1 === instance2)
    }

    func test_transient_doesNotRetainInstance() async throws {
        let container = Container()
        _ = try await container.register(MockRetentionService.self).asTransient().with { _ in MockRetentionService() }

        weak var weakRef: MockRetentionService?
        do {
            let instance = try await container.resolve(MockRetentionService.self)
            weakRef = instance
        }

        XCTAssertNil(weakRef)
    }

    func test_transient_createsNewInstanceEachTime() async throws {
        let counter = Counter()
        let container = Container()
        _ = try await container.register(MockRetentionService.self).asTransient().with { _ in
            await counter.increment()
            return MockRetentionService()
        }

        _ = try await container.resolve(MockRetentionService.self)
        _ = try await container.resolve(MockRetentionService.self)
        _ = try await container.resolve(MockRetentionService.self)

        let count = await counter.value
        XCTAssertEqual(count, 3)
    }

    // MARK: - Weak Retention

    func test_weak_retainsInstanceWhileReferencesExist() async throws {
        let container = Container()
        _ = try await container.register(MockRetentionService.self).asWeak().with { _ in MockRetentionService() }

        let instance1 = try await container.resolve(MockRetentionService.self)
        let instance2 = try await container.resolve(MockRetentionService.self)

        XCTAssertTrue(instance1 === instance2)
    }

    func test_weak_releasesInstanceWhenNoReferencesExist() async throws {
        let container = Container()
        _ = try await container.register(MockRetentionService.self).asWeak().with { _ in MockRetentionService() }

        weak var weakRef: MockRetentionService?
        do {
            let instance = try await container.resolve(MockRetentionService.self)
            weakRef = instance
        }

        XCTAssertNil(weakRef)
    }

    func test_weak_createsNewInstanceAfterDeallocation() async throws {
        let container = Container()
        _ = try await container.register(MockRetentionService.self).asWeak().with { _ in MockRetentionService() }

        do {
            _ = try await container.resolve(MockRetentionService.self)
        }

        let instance2 = try await container.resolve(MockRetentionService.self)
        XCTAssertNotNil(instance2)
    }

    // MARK: - Policy Comparison

    func test_differentPolicies_behaveDifferently() async throws {
        let container = Container()
        _ = try await container.register(MockRetentionService.self).named("singleton").asSingleton().with { _ in MockRetentionService() }
        _ = try await container.register(MockRetentionService.self).named("transient").asTransient().with { _ in MockRetentionService() }

        let singleton1 = try await container.resolve(MockRetentionService.self, name: "singleton")
        let singleton2 = try await container.resolve(MockRetentionService.self, name: "singleton")
        let transient1 = try await container.resolve(MockRetentionService.self, name: "transient")
        let transient2 = try await container.resolve(MockRetentionService.self, name: "transient")

        XCTAssertTrue(singleton1 === singleton2)
        XCTAssertFalse(transient1 === transient2)
    }

    // MARK: - Container Reset

    func test_reset_clearsSingletonInstances() async throws {
        let container = Container()
        _ = try await container.register(MockRetentionService.self).asSingleton().with { _ in MockRetentionService() }
        let instance1 = try await container.resolve(MockRetentionService.self)

        await container.reset(ignoreDependencies: [Never.Type]())
        _ = try await container.register(MockRetentionService.self).asSingleton().with { _ in MockRetentionService() }
        let instance2 = try await container.resolve(MockRetentionService.self)

        XCTAssertFalse(instance1 === instance2)
    }

    func test_reset_doesNotAffectTransientPolicy() async throws {
        let container = Container()
        _ = try await container.register(MockRetentionService.self).asTransient().with { _ in MockRetentionService() }

        await container.reset(ignoreDependencies: [Never.Type]())
        _ = try await container.register(MockRetentionService.self).asTransient().with { _ in MockRetentionService() }
        let instance1 = try await container.resolve(MockRetentionService.self)
        let instance2 = try await container.resolve(MockRetentionService.self)

        XCTAssertFalse(instance1 === instance2)
    }

    // MARK: - Concurrent Access

    func test_singleton_withConcurrentResolution_returnsSameInstance() async throws {
        let container = Container()
        _ = try await container.register(MockRetentionService.self).asSingleton().with { _ in MockRetentionService() }

        let instances = await withTaskGroup(of: MockRetentionService?.self, returning: [MockRetentionService].self) { group in
            for _ in 0..<10 {
                group.addTask {
                    try? await container.resolve(MockRetentionService.self)
                }
            }

            var results: [MockRetentionService] = []
            for await instance in group {
                if let instance { results.append(instance) }
            }
            return results
        }

        guard let firstInstance = instances.first else {
            XCTFail("Expected at least one instance")
            return
        }
        for instance in instances {
            XCTAssertTrue(instance === firstInstance)
        }
    }
}

// MARK: - Test Types

@available(iOS 15.0, *)
private final class MockRetentionService {
    let id = UUID()
}

@available(iOS 15.0, *)
private actor Counter {
    private(set) var value = 0
    func increment() { value += 1 }
}
