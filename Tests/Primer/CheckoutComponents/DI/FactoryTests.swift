//
//  FactoryTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for Factory protocols and container extensions.
@available(iOS 15.0, *)
final class FactoryTests: XCTestCase {

    private var container: Container!

    override func setUp() async throws {
        try await super.setUp()
        container = Container()
    }

    override func tearDown() async throws {
        await container.reset(ignoreDependencies: [Never.Type]())
        container = nil
        try await super.tearDown()
    }

    // MARK: - Test Types

    private struct TestProduct: Equatable {
        let id: String
        let value: Int
    }

    private struct TestParams {
        let id: String
        let multiplier: Int
    }

    // MARK: - Async Factory Tests

    private final class AsyncTestFactory: Factory {
        typealias Product = TestProduct
        typealias Params = TestParams

        func create(with params: Params) async throws -> TestProduct {
            // Simulate async work
            try? await Task.sleep(nanoseconds: 1_000_000)
            return TestProduct(id: params.id, value: params.multiplier * 10)
        }
    }

    func test_asyncFactory_createsProductWithParams() async throws {
        // Given
        let factory = AsyncTestFactory()
        let params = TestParams(id: "test-1", multiplier: 5)

        // When
        let product = try await factory.create(with: params)

        // Then
        XCTAssertEqual(product.id, "test-1")
        XCTAssertEqual(product.value, 50)
    }

    // MARK: - Sync Factory Tests

    private final class SyncTestFactory: SynchronousFactory {
        typealias Product = TestProduct
        typealias Params = TestParams

        func createSync(with params: Params) throws -> TestProduct {
            TestProduct(id: params.id, value: params.multiplier * 10)
        }
    }

    func test_syncFactory_createsSyncProductWithParams() throws {
        // Given
        let factory = SyncTestFactory()
        let params = TestParams(id: "sync-1", multiplier: 3)

        // When
        let product = try factory.createSync(with: params)

        // Then
        XCTAssertEqual(product.id, "sync-1")
        XCTAssertEqual(product.value, 30)
    }

    func test_syncFactory_createAsyncCallsSyncMethod() async throws {
        // Given
        let factory = SyncTestFactory()
        let params = TestParams(id: "async-sync-1", multiplier: 4)

        // When - call async method on sync factory
        let product = try await factory.create(with: params)

        // Then
        XCTAssertEqual(product.id, "async-sync-1")
        XCTAssertEqual(product.value, 40)
    }

    // MARK: - Void Params Factory Tests

    private final class VoidParamsFactory: Factory {
        typealias Product = TestProduct
        typealias Params = Void

        private var counter = 0

        func create(with params: Void) async throws -> TestProduct {
            counter += 1
            return TestProduct(id: "void-\(counter)", value: counter)
        }
    }

    func test_voidParamsFactory_createWithoutParams() async throws {
        // Given
        let factory = VoidParamsFactory()

        // When - call create() without params
        let product = try await factory.create()

        // Then
        XCTAssertEqual(product.id, "void-1")
        XCTAssertEqual(product.value, 1)
    }

    // MARK: - Void Params Sync Factory Tests

    private final class VoidParamsSyncFactory: SynchronousFactory {
        typealias Product = TestProduct
        typealias Params = Void

        private var counter = 0

        func createSync(with params: Void) throws -> TestProduct {
            counter += 1
            return TestProduct(id: "sync-void-\(counter)", value: counter * 100)
        }
    }

    func test_voidParamsSyncFactory_createSyncWithoutParams() throws {
        // Given
        let factory = VoidParamsSyncFactory()

        // When - call createSync() without params
        let product = try factory.createSync()

        // Then
        XCTAssertEqual(product.id, "sync-void-1")
        XCTAssertEqual(product.value, 100)
    }

    // MARK: - Container Registration Tests

    func test_registerFactory_registersAsSingleton() async throws {
        // Given
        let factory = AsyncTestFactory()

        // When
        try await container.registerFactory(factory)

        // Then - resolve the factory
        let resolvedFactory: AsyncTestFactory = try await container.resolve(AsyncTestFactory.self)
        XCTAssertNotNil(resolvedFactory)
    }

    func test_registerFactory_withName_registersNamedFactory() async throws {
        // Given
        let factory1 = VoidParamsFactory()
        let factory2 = VoidParamsFactory()

        // When
        try await container.registerFactory(factory1, name: "factory-1")
        try await container.registerFactory(factory2, name: "factory-2")

        // Then - resolve both factories by name
        let resolved1: VoidParamsFactory = try await container.resolve(VoidParamsFactory.self, name: "factory-1")
        let resolved2: VoidParamsFactory = try await container.resolve(VoidParamsFactory.self, name: "factory-2")

        // Create products to verify they're different instances
        let product1 = try await resolved1.create()
        let product2 = try await resolved2.create()

        XCTAssertEqual(product1.id, "void-1")
        XCTAssertEqual(product2.id, "void-1") // Both start at counter 1
    }

    func test_registerFactory_withPolicy_singleton() async throws {
        // Given
        let factory = VoidParamsFactory()

        // When
        try await container.registerFactory(factory, policy: .singleton)

        // Then - resolve twice, should be same instance
        let resolved1: VoidParamsFactory = try await container.resolve(VoidParamsFactory.self)
        let resolved2: VoidParamsFactory = try await container.resolve(VoidParamsFactory.self)

        // Create products - counter should increment across resolves
        let product1 = try await resolved1.create()
        let product2 = try await resolved2.create()

        XCTAssertEqual(product1.value, 1)
        XCTAssertEqual(product2.value, 2) // Same instance, counter continues
    }

    func test_registerFactory_withPolicy_transient() async throws {
        // Given
        try await container.registerFactory(
            VoidParamsFactory.self,
            policy: .transient
        ) { _ in VoidParamsFactory() }

        // When - resolve twice
        let resolved1: VoidParamsFactory = try await container.resolve(VoidParamsFactory.self)
        let resolved2: VoidParamsFactory = try await container.resolve(VoidParamsFactory.self)

        // Create products - each should start fresh
        let product1 = try await resolved1.create()
        let product2 = try await resolved2.create()

        // Then - both should be 1 (different instances, fresh counters)
        XCTAssertEqual(product1.value, 1)
        XCTAssertEqual(product2.value, 1)
    }

    func test_registerFactory_withClosure_createsFactory() async throws {
        // Given/When
        try await container.registerFactory(
            AsyncTestFactory.self,
            policy: .singleton
        ) { _ in AsyncTestFactory() }

        // Then
        let factory: AsyncTestFactory = try await container.resolve(AsyncTestFactory.self)
        let product = try await factory.create(with: TestParams(id: "closure-test", multiplier: 7))

        XCTAssertEqual(product.id, "closure-test")
        XCTAssertEqual(product.value, 70)
    }

    func test_registerFactory_withClosureAndName_registersNamedFactory() async throws {
        // Given/When
        try await container.registerFactory(
            VoidParamsFactory.self,
            policy: .singleton,
            name: "named-closure"
        ) { _ in VoidParamsFactory() }

        // Then
        let factory: VoidParamsFactory = try await container.resolve(VoidParamsFactory.self, name: "named-closure")
        let product = try await factory.create()

        XCTAssertEqual(product.id, "void-1")
    }

    // MARK: - Error Handling Tests

    private final class ThrowingFactory: Factory {
        typealias Product = TestProduct
        typealias Params = Void

        struct FactoryError: Error {}

        func create(with params: Void) async throws -> TestProduct {
            throw FactoryError()
        }
    }

    func test_factory_throwsError_propagatesToCaller() async {
        // Given
        let factory = ThrowingFactory()

        // When/Then
        do {
            _ = try await factory.create()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is ThrowingFactory.FactoryError)
        }
    }

    private final class ThrowingSyncFactory: SynchronousFactory {
        typealias Product = TestProduct
        typealias Params = Void

        struct SyncFactoryError: Error {}

        func createSync(with params: Void) throws -> TestProduct {
            throw SyncFactoryError()
        }
    }

    func test_syncFactory_throwsError_propagatesToCaller() {
        // Given
        let factory = ThrowingSyncFactory()

        // When/Then
        XCTAssertThrowsError(try factory.createSync()) { error in
            XCTAssertTrue(error is ThrowingSyncFactory.SyncFactoryError)
        }
    }

    func test_syncFactory_asyncCreate_throwsError_propagatesToCaller() async {
        // Given
        let factory = ThrowingSyncFactory()

        // When/Then
        do {
            _ = try await factory.create()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is ThrowingSyncFactory.SyncFactoryError)
        }
    }

    // MARK: - Sendable Conformance Tests

    func test_factory_canBeSentAcrossConcurrencyBoundaries() async throws {
        // Given
        let factory = VoidParamsFactory()

        // When - send across concurrency boundary
        let product = try await Task.detached {
            try await factory.create()
        }.value

        // Then
        XCTAssertEqual(product.id, "void-1")
    }
}
