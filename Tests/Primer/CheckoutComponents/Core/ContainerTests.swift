//
//  ContainerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class ContainerTests: XCTestCase {

    private var sut: Container!

    override func setUp() {
        super.setUp()
        sut = Container()
    }

    override func tearDown() async throws {
        await sut.reset(ignoreDependencies: [Never.Type]())
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Registration Tests

    func test_register_withProtocol_registersSuccessfully() async throws {
        // When
        _ = try await sut.register(ValidationService.self)
            .asSingleton()
            .with { _ in
                DefaultValidationService()
            }

        // Then - resolution should succeed
        let service: ValidationService = try await sut.resolve(ValidationService.self)
        XCTAssertNotNil(service)
    }

    // MARK: - Resolution Tests

    func test_resolve_withRegisteredType_returnsInstance() async throws {
        // Given
        _ = try await sut.register(ValidationService.self)
            .asSingleton()
            .with { _ in
                DefaultValidationService()
            }

        // When
        let service: ValidationService = try await sut.resolve(ValidationService.self)

        // Then
        XCTAssertNotNil(service)
        XCTAssertTrue(service is DefaultValidationService)
    }

    func test_resolve_withUnregisteredType_throws() async {
        // When/Then
        do {
            _ = try await sut.resolve(RulesFactory.self)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is ContainerError)
        }
    }

    // MARK: - Retention Policy Tests

    func test_singleton_returnsSameInstance() async throws {
        // Given
        _ = try await sut.register(ValidationService.self)
            .asSingleton()
            .with { _ in
                DefaultValidationService()
            }

        // When
        let service1: ValidationService = try await sut.resolve(ValidationService.self)
        let service2: ValidationService = try await sut.resolve(ValidationService.self)

        // Then
        XCTAssertTrue(service1 as AnyObject === service2 as AnyObject)
    }

    func test_transient_returnsNewInstanceEachTime() async throws {
        // Given
        _ = try await sut.register(ValidationService.self)
            .asTransient()
            .with { _ in
                DefaultValidationService()
            }

        // When
        let service1: ValidationService = try await sut.resolve(ValidationService.self)
        let service2: ValidationService = try await sut.resolve(ValidationService.self)

        // Then
        XCTAssertFalse(service1 as AnyObject === service2 as AnyObject)
    }

    // MARK: - Named Registration Tests

    func test_register_withName_canResolveByName() async throws {
        // Given
        _ = try await sut.register(ValidationService.self)
            .named("default")
            .asSingleton()
            .with { _ in
                DefaultValidationService()
            }

        // When
        let service: ValidationService = try await sut.resolve(ValidationService.self, name: "default")

        // Then
        XCTAssertNotNil(service)
    }

    // MARK: - Unregister Tests

    func test_unregister_removesRegistration() async throws {
        // Given
        _ = try await sut.register(ValidationService.self)
            .asSingleton()
            .with { _ in
                DefaultValidationService()
            }

        // Verify it's registered
        let service: ValidationService = try await sut.resolve(ValidationService.self)
        XCTAssertNotNil(service)

        // When
        await sut.unregister(ValidationService.self)

        // Then - resolution should fail
        do {
            _ = try await sut.resolve(ValidationService.self)
            XCTFail("Expected error after unregister")
        } catch {
            XCTAssertTrue(error is ContainerError)
        }
    }

    // MARK: - Reset Tests

    func test_reset_clearsAllRegistrations() async throws {
        // Given
        _ = try await sut.register(ValidationService.self)
            .asSingleton()
            .with { _ in
                DefaultValidationService()
            }

        _ = try await sut.register(RulesFactory.self)
            .asSingleton()
            .with { _ in
                DefaultRulesFactory()
            }

        // When
        await sut.reset(ignoreDependencies: [Never.Type]())

        // Then - both resolutions should fail
        do {
            _ = try await sut.resolve(ValidationService.self)
            XCTFail("Expected error after reset")
        } catch {
            XCTAssertTrue(error is ContainerError)
        }

        do {
            _ = try await sut.resolve(RulesFactory.self)
            XCTFail("Expected error after reset")
        } catch {
            XCTAssertTrue(error is ContainerError)
        }
    }

    // MARK: - Batch Resolution Tests

    func test_resolveBatch_resolvesMultipleDependenciesInOrder() async throws {
        // Given - register multiple named services of the same concrete type
        _ = try await sut.register(DefaultValidationService.self)
            .named("service1")
            .asSingleton()
            .with { _ in DefaultValidationService() }

        _ = try await sut.register(DefaultValidationService.self)
            .named("service2")
            .asSingleton()
            .with { _ in DefaultValidationService() }

        _ = try await sut.register(DefaultValidationService.self)
            .named("service3")
            .asSingleton()
            .with { _ in DefaultValidationService() }

        // When - resolve in batch
        let requests: [(type: DefaultValidationService.Type, name: String?)] = [
            (DefaultValidationService.self, "service1"),
            (DefaultValidationService.self, "service2"),
            (DefaultValidationService.self, "service3")
        ]

        let results = try await sut.resolveBatch(requests)

        // Then - should resolve all three in order
        XCTAssertEqual(results.count, 3)
        XCTAssertNotNil(results[0])
        XCTAssertNotNil(results[1])
        XCTAssertNotNil(results[2])
    }

    func test_resolveBatch_throwsOnUnregisteredService() async throws {
        // When/Then - should throw when encountering unregistered service
        let requests: [(type: DefaultValidationService.Type, name: String?)] = [
            (DefaultValidationService.self, nil)
        ]

        do {
            _ = try await sut.resolveBatch(requests)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is ContainerError)
        }
    }

    // MARK: - Sync Resolution Tests

    func test_resolveSync_withSlowFactory_throwsTimeoutError() async throws {
        // Given - register a factory that takes > 500ms
        _ = try await sut.register(SlowService.self)
            .asSingleton()
            .with { _ in
                try await Task.sleep(nanoseconds: TestData.DIContainer.Timing.oneSecondNanoseconds)
                return SlowServiceImpl()
            }

        // When/Then - sync resolution should timeout
        XCTAssertThrowsError(try sut.resolveSync(SlowService.self)) { error in
            guard let containerError = error as? ContainerError else {
                XCTFail("Expected ContainerError")
                return
            }
            // Verify it's a factory failed error with timeout message
            if case let .factoryFailed(_, underlying) = containerError {
                XCTAssertTrue(underlying.localizedDescription.contains("timed out"))
            } else {
                XCTFail("Expected factoryFailed error")
            }
        }
    }
}

// MARK: - Test Support Types

private protocol SlowService {}
private final class SlowServiceImpl: SlowService {}
