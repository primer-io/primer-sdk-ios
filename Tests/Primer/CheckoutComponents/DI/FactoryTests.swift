//
//  FactoryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

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
            try? await Task.sleep(nanoseconds: TestData.DIContainer.Timing.oneMillisecondNanoseconds)
            return TestProduct(id: params.id, value: params.multiplier * TestData.DIContainer.Factory.defaultMultiplier)
        }
    }

    func test_asyncFactory_createsProductWithParams() async throws {
        // Given
        let factory = AsyncTestFactory()
        let testId = "\(TestData.DIContainer.Factory.testIdPrefix)1"
        let params = TestParams(id: testId, multiplier: TestData.DIContainer.Values.multiplier5)

        // When
        let product = try await factory.create(with: params)

        // Then
        XCTAssertEqual(product.id, testId)
        XCTAssertEqual(product.value, TestData.DIContainer.Values.multiplier5 * TestData.DIContainer.Factory.defaultMultiplier)
    }

    // MARK: - Sync Factory Tests

    private final class SyncTestFactory: SynchronousFactory {
        typealias Product = TestProduct
        typealias Params = TestParams

        func createSync(with params: Params) throws -> TestProduct {
            TestProduct(id: params.id, value: params.multiplier * TestData.DIContainer.Factory.defaultMultiplier)
        }
    }

    func test_syncFactory_createsSyncProductWithParams() throws {
        // Given
        let factory = SyncTestFactory()
        let testId = "\(TestData.DIContainer.Factory.syncIdPrefix)1"
        let params = TestParams(id: testId, multiplier: TestData.DIContainer.Values.multiplier3)

        // When
        let product = try factory.createSync(with: params)

        // Then
        XCTAssertEqual(product.id, testId)
        XCTAssertEqual(product.value, TestData.DIContainer.Values.multiplier3 * TestData.DIContainer.Factory.defaultMultiplier)
    }

    func test_syncFactory_createAsyncCallsSyncMethod() async throws {
        // Given
        let factory = SyncTestFactory()
        let testId = "\(TestData.DIContainer.Factory.asyncSyncIdPrefix)1"
        let params = TestParams(id: testId, multiplier: TestData.DIContainer.Values.multiplier4)

        // When - call async method on sync factory
        let product = try await factory.create(with: params)

        // Then
        XCTAssertEqual(product.id, testId)
        XCTAssertEqual(product.value, TestData.DIContainer.Values.multiplier4 * TestData.DIContainer.Factory.defaultMultiplier)
    }

    // MARK: - Void Params Factory Tests

    private final class VoidParamsFactory: Factory {
        typealias Product = TestProduct
        typealias Params = Void

        private var counter = 0

        func create(with params: Void) async throws -> TestProduct {
            counter += 1
            return TestProduct(id: "\(TestData.DIContainer.Factory.voidIdPrefix)\(counter)", value: counter)
        }
    }

    func test_voidParamsFactory_createWithoutParams() async throws {
        // Given
        let factory = VoidParamsFactory()

        // When - call create() without params
        let product = try await factory.create()

        // Then
        XCTAssertEqual(product.id, "\(TestData.DIContainer.Factory.voidIdPrefix)1")
        XCTAssertEqual(product.value, 1)
    }

    // MARK: - Void Params Sync Factory Tests

    private final class VoidParamsSyncFactory: SynchronousFactory {
        typealias Product = TestProduct
        typealias Params = Void

        private var counter = 0

        func createSync(with params: Void) throws -> TestProduct {
            counter += 1
            return TestProduct(id: "\(TestData.DIContainer.Factory.syncVoidIdPrefix)\(counter)", value: counter * TestData.DIContainer.Factory.largeMultiplier)
        }
    }

    func test_voidParamsSyncFactory_createSyncWithoutParams() throws {
        // Given
        let factory = VoidParamsSyncFactory()

        // When - call createSync() without params
        let product = try factory.createSync()

        // Then
        XCTAssertEqual(product.id, "\(TestData.DIContainer.Factory.syncVoidIdPrefix)1")
        XCTAssertEqual(product.value, TestData.DIContainer.Factory.largeMultiplier)
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
        try await container.registerFactory(factory1, name: TestData.DIContainer.Factory.factoryName1)
        try await container.registerFactory(factory2, name: TestData.DIContainer.Factory.factoryName2)

        // Then - resolve both factories by name
        let resolved1: VoidParamsFactory = try await container.resolve(VoidParamsFactory.self, name: TestData.DIContainer.Factory.factoryName1)
        let resolved2: VoidParamsFactory = try await container.resolve(VoidParamsFactory.self, name: TestData.DIContainer.Factory.factoryName2)

        // Create products to verify they're different instances
        let product1 = try await resolved1.create()
        let product2 = try await resolved2.create()

        XCTAssertEqual(product1.id, "\(TestData.DIContainer.Factory.voidIdPrefix)1")
        XCTAssertEqual(product2.id, "\(TestData.DIContainer.Factory.voidIdPrefix)1") // Both start at counter 1
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

        XCTAssertEqual(product1.value, 1) // First call
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
        XCTAssertEqual(product1.value, 1) // First instance
        XCTAssertEqual(product2.value, 1) // Different instance, fresh counter
    }

    func test_registerFactory_withClosure_createsFactory() async throws {
        // Given/When
        try await container.registerFactory(
            AsyncTestFactory.self,
            policy: .singleton
        ) { _ in AsyncTestFactory() }

        // Then
        let factory: AsyncTestFactory = try await container.resolve(AsyncTestFactory.self)
        let product = try await factory.create(with: TestParams(id: TestData.DIContainer.Factory.closureTestId, multiplier: TestData.DIContainer.Values.multiplier7))

        XCTAssertEqual(product.id, TestData.DIContainer.Factory.closureTestId)
        XCTAssertEqual(product.value, TestData.DIContainer.Values.multiplier7 * TestData.DIContainer.Factory.defaultMultiplier)
    }

    func test_registerFactory_withClosureAndName_registersNamedFactory() async throws {
        // Given/When
        try await container.registerFactory(
            VoidParamsFactory.self,
            policy: .singleton,
            name: TestData.DIContainer.Factory.namedClosure
        ) { _ in VoidParamsFactory() }

        // Then
        let factory: VoidParamsFactory = try await container.resolve(VoidParamsFactory.self, name: TestData.DIContainer.Factory.namedClosure)
        let product = try await factory.create()

        XCTAssertEqual(product.id, "\(TestData.DIContainer.Factory.voidIdPrefix)1")
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
}
