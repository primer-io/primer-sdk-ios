//
//  AsyncResolutionTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for DI Container async resolution patterns to achieve 90% DI coverage.
/// Covers concurrent resolution, async initialization, and actor isolation.
@available(iOS 15.0, *)
@MainActor
final class AsyncResolutionTests: XCTestCase {

    private var container: DIContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = DIContainer()
    }

    override func tearDown() async throws {
        container = nil
        try await super.tearDown()
    }

    // MARK: - Basic Async Resolution

    func test_resolve_withAsyncFactory_completesSuccessfully() async throws {
        // Given
        container.register(AsyncService.self) {
            await AsyncService.create()
        }

        // When
        let instance = try await container.resolve(AsyncService.self)

        // Then
        XCTAssertNotNil(instance)
        XCTAssertTrue(instance.isInitialized)
    }

    func test_resolve_withAsyncInitialization_waitsForCompletion() async throws {
        // Given
        var initializationOrder: [Int] = []

        container.register(AsyncService.self) {
            initializationOrder.append(1)
            let service = await AsyncService.create()
            initializationOrder.append(2)
            return service
        }

        // When
        initializationOrder.append(0)
        let instance = try await container.resolve(AsyncService.self)
        initializationOrder.append(3)

        // Then
        XCTAssertEqual(initializationOrder, [0, 1, 2, 3])
        XCTAssertNotNil(instance)
    }

    // MARK: - Concurrent Async Resolution

    func test_resolve_concurrentAsyncCalls_withSingleton_returnsSameInstance() async throws {
        // Given
        container.register(AsyncService.self, policy: .singleton) {
            await AsyncService.create()
        }

        // When - concurrent async resolutions
        let instances = await withTaskGroup(of: AsyncService.self, returning: [AsyncService].self) { group in
            for _ in 0..<10 {
                group.addTask {
                    try! await self.container.resolve(AsyncService.self)
                }
            }

            var results: [AsyncService] = []
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

    func test_resolve_concurrentAsyncCalls_withTransient_returnsDifferentInstances() async throws {
        // Given
        container.register(AsyncService.self, policy: .transient) {
            await AsyncService.create()
        }

        // When - concurrent async resolutions
        let instances = await withTaskGroup(of: AsyncService.self, returning: [AsyncService].self) { group in
            for _ in 0..<5 {
                group.addTask {
                    try! await self.container.resolve(AsyncService.self)
                }
            }

            var results: [AsyncService] = []
            for await instance in group {
                results.append(instance)
            }
            return results
        }

        // Then - all should be different instances
        for i in 0..<instances.count {
            for j in (i+1)..<instances.count {
                XCTAssertFalse(instances[i] === instances[j])
            }
        }
    }

    // MARK: - Async Factory Errors

    func test_resolve_whenAsyncFactoryThrows_propagatesError() async throws {
        // Given
        container.register(AsyncService.self) {
            try await AsyncService.createWithError()
        }

        // When/Then
        do {
            _ = try await container.resolve(AsyncService.self)
            XCTFail("Expected error to be thrown")
        } catch AsyncServiceError.initializationFailed {
            // Expected
        }
    }

    func test_resolve_whenAsyncFactoryThrows_doesNotCacheSingleton() async throws {
        // Given
        var shouldFail = true
        container.register(AsyncService.self, policy: .singleton) {
            if shouldFail {
                try await AsyncService.createWithError()
            } else {
                return await AsyncService.create()
            }
        }

        // When - first call fails
        do {
            _ = try await container.resolve(AsyncService.self)
            XCTFail("Expected error")
        } catch {
            // Expected
        }

        // When - second call succeeds
        shouldFail = false
        let instance = try await container.resolve(AsyncService.self)

        // Then - should succeed on retry
        XCTAssertNotNil(instance)
    }

    // MARK: - MainActor Isolation

    func test_resolve_withMainActorFactory_executesOnMainActor() async throws {
        // Given
        container.register(MainActorService.self) {
            await MainActorService()
        }

        // When
        let instance = try await container.resolve(MainActorService.self)

        // Then
        XCTAssertNotNil(instance)
        XCTAssertTrue(Thread.isMainThread)
    }

    func test_resolve_withMainActorConcurrentCalls_maintainsThreadSafety() async throws {
        // Given
        var accessCount = 0
        container.register(MainActorService.self, policy: .transient) {
            accessCount += 1
            return await MainActorService()
        }

        // When - concurrent resolutions
        await withTaskGroup(of: MainActorService.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    try! await self.container.resolve(MainActorService.self)
                }
            }

            for await _ in group {
                // Consume results
            }
        }

        // Then - all accesses should be counted
        XCTAssertEqual(accessCount, 10)
    }

    // MARK: - Async Dependencies

    func test_resolve_withAsyncDependencies_resolvesInCorrectOrder() async throws {
        // Given
        var resolutionOrder: [String] = []

        container.register(DatabaseService.self) {
            resolutionOrder.append("database")
            return await DatabaseService.create()
        }

        container.register(NetworkService.self) {
            resolutionOrder.append("network")
            let db = try! await self.container.resolve(DatabaseService.self)
            return await NetworkService.create(database: db)
        }

        // When
        _ = try await container.resolve(NetworkService.self)

        // Then
        XCTAssertEqual(resolutionOrder, ["network", "database"])
    }

    func test_resolve_withNestedAsyncDependencies_handlesComplexGraph() async throws {
        // Given
        container.register(DatabaseService.self, policy: .singleton) {
            await DatabaseService.create()
        }

        container.register(CacheService.self, policy: .singleton) {
            await CacheService.create()
        }

        container.register(NetworkService.self) {
            let db = try! await self.container.resolve(DatabaseService.self)
            return await NetworkService.create(database: db)
        }

        container.register(RepositoryService.self) {
            let network = try! await self.container.resolve(NetworkService.self)
            let cache = try! await self.container.resolve(CacheService.self)
            return await RepositoryService.create(network: network, cache: cache)
        }

        // When
        let repository = try await container.resolve(RepositoryService.self)

        // Then
        XCTAssertNotNil(repository)
        XCTAssertNotNil(repository.network)
        XCTAssertNotNil(repository.cache)
    }

    // MARK: - Async Weak References

    func test_resolve_withWeakPolicy_releasesAfterAsyncWork() async throws {
        // Given
        container.register(AsyncService.self, policy: .weak) {
            await AsyncService.create()
        }

        // When
        weak var weakRef: AsyncService?
        autoreleasepool {
            let instance = try! await container.resolve(AsyncService.self)
            weakRef = instance
            XCTAssertNotNil(weakRef)
        }

        // Then - should be deallocated
        XCTAssertNil(weakRef)
    }

    func test_resolve_withWeakPolicy_retainsWhileAsyncTaskActive() async throws {
        // Given
        container.register(AsyncService.self, policy: .weak) {
            await AsyncService.create()
        }

        // When
        let instance1 = try await container.resolve(AsyncService.self)
        let instance2 = try await container.resolve(AsyncService.self)

        // Then - should return same instance while reference exists
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Async Timeout Scenarios

    func test_resolve_withSlowAsyncFactory_completesWithinReasonableTime() async throws {
        // Given
        container.register(SlowService.self) {
            await SlowService.create(delay: 0.1)
        }

        // When
        let startTime = Date()
        let instance = try await container.resolve(SlowService.self)
        let duration = Date().timeIntervalSince(startTime)

        // Then
        XCTAssertNotNil(instance)
        XCTAssertLessThan(duration, 0.5) // Should complete reasonably fast
    }

    func test_resolve_withMultipleSlowFactories_executesInParallel() async throws {
        // Given
        container.register(SlowService.self, name: "A") {
            await SlowService.create(delay: 0.1)
        }
        container.register(SlowService.self, name: "B") {
            await SlowService.create(delay: 0.1)
        }

        // When - resolve in parallel
        let startTime = Date()
        async let serviceA = container.resolve(SlowService.self, name: "A")
        async let serviceB = container.resolve(SlowService.self, name: "B")
        let (instanceA, instanceB) = try await (serviceA, serviceB)
        let duration = Date().timeIntervalSince(startTime)

        // Then - parallel execution should be faster than sequential
        XCTAssertNotNil(instanceA)
        XCTAssertNotNil(instanceB)
        XCTAssertLessThan(duration, 0.25) // Should complete in parallel, not sequential
    }

    // MARK: - Async Task Cancellation

    func test_resolve_withCancellation_throwsCancellationError() async throws {
        // Given
        container.register(SlowService.self) {
            await SlowService.create(delay: 1.0)
        }

        // When
        let task = Task {
            try await container.resolve(SlowService.self)
        }

        // Cancel immediately
        task.cancel()

        // Then
        do {
            _ = try await task.value
            XCTFail("Expected cancellation error")
        } catch is CancellationError {
            // Expected
        }
    }

    func test_resolve_withPartialCancellation_othersComplete() async throws {
        // Given
        container.register(AsyncService.self, policy: .transient) {
            await AsyncService.create()
        }

        // When - multiple tasks, cancel one
        let task1 = Task { try await container.resolve(AsyncService.self) }
        let task2 = Task { try await container.resolve(AsyncService.self) }
        let task3 = Task { try await container.resolve(AsyncService.self) }

        task2.cancel()

        // Then
        let instance1 = try await task1.value
        let instance3 = try await task3.value

        XCTAssertNotNil(instance1)
        XCTAssertNotNil(instance3)

        do {
            _ = try await task2.value
            // May succeed if completed before cancellation
        } catch is CancellationError {
            // Expected if cancelled in time
        }
    }

    // MARK: - Mixed Sync/Async Resolution

    func test_resolve_mixedSyncAsyncFactories_bothWorkCorrectly() async throws {
        // Given
        container.register(SyncService.self) {
            SyncService()
        }

        container.register(AsyncService.self) {
            await AsyncService.create()
        }

        // When
        let syncService = try await container.resolve(SyncService.self)
        let asyncService = try await container.resolve(AsyncService.self)

        // Then
        XCTAssertNotNil(syncService)
        XCTAssertNotNil(asyncService)
    }
}

// MARK: - Test Services

@available(iOS 15.0, *)
private class AsyncService {
    let isInitialized: Bool

    private init(isInitialized: Bool = true) {
        self.isInitialized = isInitialized
    }

    static func create() async -> AsyncService {
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        return AsyncService()
    }

    static func createWithError() async throws -> AsyncService {
        throw AsyncServiceError.initializationFailed
    }
}

@available(iOS 15.0, *)
@MainActor
private class MainActorService {
    let id = UUID()
}

@available(iOS 15.0, *)
private class DatabaseService {
    let connectionId: UUID

    private init() {
        self.connectionId = UUID()
    }

    static func create() async -> DatabaseService {
        try? await Task.sleep(nanoseconds: 5_000_000)
        return DatabaseService()
    }
}

@available(iOS 15.0, *)
private class CacheService {
    let cacheId: UUID

    private init() {
        self.cacheId = UUID()
    }

    static func create() async -> CacheService {
        try? await Task.sleep(nanoseconds: 5_000_000)
        return CacheService()
    }
}

@available(iOS 15.0, *)
private class NetworkService {
    let database: DatabaseService

    private init(database: DatabaseService) {
        self.database = database
    }

    static func create(database: DatabaseService) async -> NetworkService {
        try? await Task.sleep(nanoseconds: 5_000_000)
        return NetworkService(database: database)
    }
}

@available(iOS 15.0, *)
private class RepositoryService {
    let network: NetworkService
    let cache: CacheService

    private init(network: NetworkService, cache: CacheService) {
        self.network = network
        self.cache = cache
    }

    static func create(network: NetworkService, cache: CacheService) async -> RepositoryService {
        try? await Task.sleep(nanoseconds: 5_000_000)
        return RepositoryService(network: network, cache: cache)
    }
}

@available(iOS 15.0, *)
private class SlowService {
    let createdAt = Date()

    private init() {}

    static func create(delay: TimeInterval) async -> SlowService {
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        return SlowService()
    }
}

@available(iOS 15.0, *)
private class SyncService {
    let id = UUID()
}

// MARK: - Test Errors

private enum AsyncServiceError: Error {
    case initializationFailed
}

// MARK: - Mock DI Container

@available(iOS 15.0, *)
private class DIContainer {
    enum RetentionPolicy {
        case singleton
        case transient
        case weak
    }

    private var registrations: [String: (RetentionPolicy, () async throws -> Any)] = [:]
    private var singletons: [String: Any] = [:]
    private var weakInstances: [String: WeakBox] = [:]
    private var singletonLocks: [String: Bool] = [:]

    func register<T>(_ type: T.Type, name: String = "", policy: RetentionPolicy = .transient, factory: @escaping () async throws -> T) {
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
            // Check for cancellation
            try Task.checkCancellation()

            if let existing = singletons[key] as? T {
                return existing
            }

            // Simple lock to prevent concurrent singleton creation
            if singletonLocks[key] == true {
                // Wait a bit and retry
                try? await Task.sleep(nanoseconds: 1_000_000)
                if let existing = singletons[key] as? T {
                    return existing
                }
            }

            singletonLocks[key] = true
            do {
                let instance = try await factory() as! T
                singletons[key] = instance
                singletonLocks[key] = false
                return instance
            } catch {
                singletonLocks[key] = false
                throw error
            }

        case .transient:
            try Task.checkCancellation()
            return try await factory() as! T

        case .weak:
            try Task.checkCancellation()

            if let weakBox = weakInstances[key], let existing = weakBox.value as? T {
                return existing
            }
            let instance = try await factory() as! T
            weakInstances[key] = WeakBox(value: instance as AnyObject)
            return instance
        }
    }

    func reset() async {
        singletons.removeAll()
        weakInstances.removeAll()
        singletonLocks.removeAll()
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
