//
//  ContainerProtocolTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

// MARK: - Test Types

@available(iOS 15.0, *)
protocol CPTestService: Sendable {}

@available(iOS 15.0, *)
final class CPTestServiceImpl: CPTestService, @unchecked Sendable {}

/// Tests for ContainerProtocol, Registrar, DIResolver, LifecycleManager protocols
/// and their default extension methods.
@available(iOS 15.0, *)
final class ContainerProtocolTests: XCTestCase {

    // MARK: - Registrar Extension Tests

    func test_registrar_unregisterWithoutName_callsUnregisterWithNilName() async {
        // Given
        let mockRegistrar = CPMockRegistrar()

        // When
        _ = await mockRegistrar.unregister(CPTestService.self)

        // Then
        XCTAssertEqual(mockRegistrar.unregisterCallCount, 1)
        XCTAssertNil(mockRegistrar.lastUnregisteredName)
        XCTAssertEqual(mockRegistrar.lastUnregisteredType, String(describing: CPTestService.self))
    }

    func test_registrar_unregisterWithName_passesNameCorrectly() async {
        // Given
        let mockRegistrar = CPMockRegistrar()
        let serviceName = "testService"

        // When
        _ = await mockRegistrar.unregister(CPTestService.self, name: serviceName)

        // Then
        XCTAssertEqual(mockRegistrar.unregisterCallCount, 1)
        XCTAssertEqual(mockRegistrar.lastUnregisteredName, serviceName)
    }

    func test_registrar_discardableResultChaining() async {
        // Given
        let mockRegistrar = CPMockRegistrar()

        // When - chain multiple unregisters
        let result = await mockRegistrar
            .unregister(CPTestService.self)
            .unregister(CPTestService.self, name: "named")

        // Then
        XCTAssertEqual(mockRegistrar.unregisterCallCount, 2)
        XCTAssertNotNil(result)
    }

    // MARK: - DIResolver Extension Tests

    func test_resolver_resolveWithoutName_callsResolveWithNilName() async throws {
        // Given
        let mockResolver = CPMockDIResolver()

        // When
        _ = try await mockResolver.resolve(CPTestService.self)

        // Then
        XCTAssertEqual(mockResolver.resolveCallCount, 1)
        XCTAssertNil(mockResolver.lastResolvedName)
    }

    func test_resolver_resolveWithName_passesNameCorrectly() async throws {
        // Given
        let mockResolver = CPMockDIResolver()
        let serviceName = "customService"

        // When
        _ = try await mockResolver.resolve(CPTestService.self, name: serviceName)

        // Then
        XCTAssertEqual(mockResolver.resolveCallCount, 1)
        XCTAssertEqual(mockResolver.lastResolvedName, serviceName)
    }

    func test_resolver_resolveSyncWithoutName_callsResolveSyncWithNilName() throws {
        // Given
        let mockResolver = CPMockDIResolver()

        // When
        _ = try mockResolver.resolveSync(CPTestService.self)

        // Then
        XCTAssertEqual(mockResolver.resolveSyncCallCount, 1)
        XCTAssertNil(mockResolver.lastResolvedSyncName)
    }

    func test_resolver_resolveSyncWithName_passesNameCorrectly() throws {
        // Given
        let mockResolver = CPMockDIResolver()
        let serviceName = "syncService"

        // When
        _ = try mockResolver.resolveSync(CPTestService.self, name: serviceName)

        // Then
        XCTAssertEqual(mockResolver.resolveSyncCallCount, 1)
        XCTAssertEqual(mockResolver.lastResolvedSyncName, serviceName)
    }

    // MARK: - Container Protocol Composition Tests

    func test_containerProtocol_conformsToAllProtocols() async throws {
        // Given
        let container = CPMockContainer()

        // Then - verify protocol conformance
        XCTAssertTrue(container is Registrar)
        XCTAssertTrue(container is DIResolver)
        XCTAssertTrue(container is LifecycleManager)
        XCTAssertTrue(container is ContainerProtocol)
    }

    func test_containerProtocol_canUseAllDefaultMethods() async throws {
        // Given
        let container = CPMockContainer()

        // When - use default extension methods
        _ = await container.unregister(CPTestService.self)
        _ = try await container.resolve(CPTestService.self)
        _ = try container.resolveSync(CPTestService.self)

        // Then - all methods were called
        XCTAssertEqual(container.unregisterCallCount, 1)
        XCTAssertEqual(container.resolveCallCount, 1)
        XCTAssertEqual(container.resolveSyncCallCount, 1)
    }

    // MARK: - Sendable Conformance Tests

    func test_registrar_isSendable() async {
        // Given
        let registrar = CPMockRegistrar()

        // When - pass across concurrency boundary
        let result: CPMockRegistrar = await Task.detached {
            return registrar
        }.value

        // Then
        XCTAssertNotNil(result)
    }

    func test_resolver_isSendable() async {
        // Given
        let resolver = CPMockDIResolver()

        // When - pass across concurrency boundary
        let result: CPMockDIResolver = await Task.detached {
            return resolver
        }.value

        // Then
        XCTAssertNotNil(result)
    }
}

// MARK: - Mock Implementations

@available(iOS 15.0, *)
final class CPMockRegistrar: Registrar, @unchecked Sendable {
    var unregisterCallCount = 0
    var lastUnregisteredType: String?
    var lastUnregisteredName: String?
    var registerCallCount = 0

    func register<T>(_ type: T.Type) -> any RegistrationBuilder<T> {
        registerCallCount += 1
        return CPMockRegistrationBuilder<T>()
    }

    func unregister<T>(_ type: T.Type, name: String?) async -> Self {
        unregisterCallCount += 1
        lastUnregisteredType = String(describing: type)
        lastUnregisteredName = name
        return self
    }
}

@available(iOS 15.0, *)
final class CPMockDIResolver: DIResolver, @unchecked Sendable {
    var resolveCallCount = 0
    var lastResolvedName: String?
    var resolveSyncCallCount = 0
    var lastResolvedSyncName: String?
    var resolveAllCallCount = 0

    private let mockService: Any

    init() {
        self.mockService = CPTestServiceImpl()
    }

    func resolve<T>(_ type: T.Type, name: String?) async throws -> T {
        resolveCallCount += 1
        lastResolvedName = name
        guard let result = mockService as? T else {
            throw CPMockError.typeMismatch
        }
        return result
    }

    func resolveSync<T>(_ type: T.Type, name: String?) throws -> T {
        resolveSyncCallCount += 1
        lastResolvedSyncName = name
        guard let result = mockService as? T else {
            throw CPMockError.typeMismatch
        }
        return result
    }

    func resolveAll<T>(_ type: T.Type) async -> [T] {
        resolveAllCallCount += 1
        if let result = mockService as? T {
            return [result]
        }
        return []
    }
}

@available(iOS 15.0, *)
final class CPMockContainer: ContainerProtocol, @unchecked Sendable {
    var registerCallCount = 0
    var unregisterCallCount = 0
    var resolveCallCount = 0
    var resolveSyncCallCount = 0
    var resolveAllCallCount = 0
    var resetCallCount = 0

    private let mockService: Any

    init() {
        self.mockService = CPTestServiceImpl()
    }

    func register<T>(_ type: T.Type) -> any RegistrationBuilder<T> {
        registerCallCount += 1
        return CPMockRegistrationBuilder<T>()
    }

    func unregister<T>(_ type: T.Type, name: String?) async -> Self {
        unregisterCallCount += 1
        return self
    }

    func resolve<T>(_ type: T.Type, name: String?) async throws -> T {
        resolveCallCount += 1
        guard let result = mockService as? T else {
            throw CPMockError.typeMismatch
        }
        return result
    }

    func resolveSync<T>(_ type: T.Type, name: String?) throws -> T {
        resolveSyncCallCount += 1
        guard let result = mockService as? T else {
            throw CPMockError.typeMismatch
        }
        return result
    }

    func resolveAll<T>(_ type: T.Type) async -> [T] {
        resolveAllCallCount += 1
        if let result = mockService as? T {
            return [result]
        }
        return []
    }

    func reset<T>(ignoreDependencies: [T.Type]) async {
        resetCallCount += 1
    }
}

@available(iOS 15.0, *)
final class CPMockRegistrationBuilder<T>: RegistrationBuilder, @unchecked Sendable {
    func named(_ name: String) -> Self { self }
    func asSingleton() -> Self { self }
    func asWeak() -> Self { self }
    func asTransient() -> Self { self }
    func with(_ factory: @escaping (any ContainerProtocol) async throws -> T) async throws -> Self { self }
    func with(_ factory: @escaping (any ContainerProtocol) throws -> T) async throws -> Self { self }
}

private enum CPMockError: Error {
    case typeMismatch
    case notFound
}
