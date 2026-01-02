//
//  ContainerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for the DI Container registration and resolution functionality.
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

    // MARK: - Diagnostics Tests

    func test_getDiagnostics_returnsRegistrationInfo() async throws {
        // Given
        _ = try await sut.register(ValidationService.self)
            .asSingleton()
            .with { _ in
                DefaultValidationService()
            }

        // When
        let diagnostics = await sut.getDiagnostics()

        // Then
        XCTAssertGreaterThan(diagnostics.registeredTypes.count, 0)
    }

    // MARK: - Health Check Tests

    func test_performHealthCheck_returnsValidStatus() async throws {
        // Given
        _ = try await sut.register(ValidationService.self)
            .asSingleton()
            .with { _ in
                DefaultValidationService()
            }

        // When
        let result = await sut.performHealthCheck()

        // Then - Health check should return a valid status (not critical for minimal registration)
        XCTAssertNotEqual(result.status, .critical)
    }
}
