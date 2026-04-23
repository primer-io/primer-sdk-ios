//
//  ComposableContainerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class ComposableContainerTests: XCTestCase {

    private var savedContainer: ContainerProtocol?

    override func setUp() async throws {
        try await super.setUp()
        savedContainer = await DIContainer.current
        await DIContainer.clearContainer()
    }

    override func tearDown() async throws {
        if let savedContainer {
            await DIContainer.setContainer(savedContainer)
        } else {
            await DIContainer.clearContainer()
        }
        try await super.tearDown()
    }

    // MARK: - Happy Path

    func test_configure_withValidSettings_doesNotThrow() async throws {
        let sut = ComposableContainer(settings: PrimerSettings())

        try await sut.configure()

        let current = await DIContainer.current
        XCTAssertNotNil(current, "Container should be published only after successful configuration")
    }

    // MARK: - Critical Dependency Validation

    func test_configure_registersAllCriticalDependencies_resolvable() async throws {
        let sut = ComposableContainer(settings: PrimerSettings())

        try await sut.configure()

        guard let container = await DIContainer.current else {
            XCTFail("Container should be published after configure")
            return
        }

        // Each critical dependency must be resolvable post-configure; if any
        // factory threw during validation, configure() would have failed.
        _ = try await container.resolve(PrimerSettings.self)
        _ = try await container.resolve(CheckoutComponentsAnalyticsServiceProtocol.self)
        _ = try await container.resolve(CheckoutComponentsAnalyticsInteractorProtocol.self)
        _ = try await container.resolve(ConfigurationService.self)
        _ = try await container.resolve(ValidationService.self)
        _ = try await container.resolve(HeadlessRepository.self)
        _ = try await container.resolve(PaymentMethodMapper.self)
    }

    // MARK: - Container Publishing Ordering

    func test_configure_beforeCall_doesNotPublishContainer() async {
        _ = ComposableContainer(settings: PrimerSettings())

        let current = await DIContainer.current
        XCTAssertNil(current, "Container should not be published until configure() runs")
    }
}
