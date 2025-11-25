//
//  AccessibilityDIContainerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class AccessibilityDIContainerTests: XCTestCase {

    var composableContainer: ComposableContainer!

    override func setUp() async throws {
        try await super.setUp()

        // Create settings for the container
        let settings = PrimerSettings(
            paymentHandling: .manual,
            paymentMethodOptions: PrimerPaymentMethodOptions()
        )

        // Create and configure the ComposableContainer
        composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()
    }

    override func tearDown() async throws {
        composableContainer = nil
        try await super.tearDown()
    }

    // MARK: - Registration Tests

    func testAccessibilityAnnouncementService_IsRegistered() async throws {
        // Given: Container is configured
        guard let container = await DIContainer.current else {
            XCTFail("DIContainer.current should be set")
            return
        }

        // When: Resolving AccessibilityAnnouncementService
        let service = try await container.resolve(AccessibilityAnnouncementService.self)

        // Then: Service should be resolved successfully
        XCTAssertNotNil(service)
    }

    func testAccessibilityAnnouncementService_ResolvesToDefaultImplementation() async throws {
        // Given: Container is configured
        guard let container = await DIContainer.current else {
            XCTFail("DIContainer.current should be set")
            return
        }

        // When: Resolving AccessibilityAnnouncementService
        let service = try await container.resolve(AccessibilityAnnouncementService.self)

        // Then: Service should be DefaultAccessibilityAnnouncementService
        XCTAssertTrue(service is DefaultAccessibilityAnnouncementService)
    }

    // MARK: - Multiple Resolve Tests

    func testAccessibilityAnnouncementService_CanBeResolvedMultipleTimes() async throws {
        // Given: Container is configured
        guard let container = await DIContainer.current else {
            XCTFail("DIContainer.current should be set")
            return
        }

        // When: Resolving service multiple times
        let service1 = try await container.resolve(AccessibilityAnnouncementService.self)
        let service2 = try await container.resolve(AccessibilityAnnouncementService.self)

        // Then: Both services should be resolved successfully
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        XCTAssertTrue(service1 is DefaultAccessibilityAnnouncementService)
        XCTAssertTrue(service2 is DefaultAccessibilityAnnouncementService)
    }

    // MARK: - Service Functionality Tests

    func testAccessibilityAnnouncementService_CanAnnounceError() async throws {
        // Given: Service is resolved
        guard let container = await DIContainer.current else {
            XCTFail("DIContainer.current should be set")
            return
        }
        let service = try await container.resolve(AccessibilityAnnouncementService.self)

        // When: Announcing an error
        // Then: Should not crash (UIAccessibility.post is tested separately)
        service.announceError("Test error message")

        // Note: We can't directly test UIAccessibility.post without mocking,
        // but we verify the method doesn't crash
        XCTAssertTrue(true, "announceError should execute without crashing")
    }

    func testAccessibilityAnnouncementService_CanAnnounceStateChange() async throws {
        // Given: Service is resolved
        guard let container = await DIContainer.current else {
            XCTFail("DIContainer.current should be set")
            return
        }
        let service = try await container.resolve(AccessibilityAnnouncementService.self)

        // When: Announcing state change
        service.announceStateChange("Loading complete")

        // Then: Should not crash
        XCTAssertTrue(true, "announceStateChange should execute without crashing")
    }

    func testAccessibilityAnnouncementService_CanAnnounceLayoutChange() async throws {
        // Given: Service is resolved
        guard let container = await DIContainer.current else {
            XCTFail("DIContainer.current should be set")
            return
        }
        let service = try await container.resolve(AccessibilityAnnouncementService.self)

        // When: Announcing layout change
        service.announceLayoutChange("New content available")

        // Then: Should not crash
        XCTAssertTrue(true, "announceLayoutChange should execute without crashing")
    }

    func testAccessibilityAnnouncementService_CanAnnounceScreenChange() async throws {
        // Given: Service is resolved
        guard let container = await DIContainer.current else {
            XCTFail("DIContainer.current should be set")
            return
        }
        let service = try await container.resolve(AccessibilityAnnouncementService.self)

        // When: Announcing screen change
        service.announceScreenChange("Card form")

        // Then: Should not crash
        XCTAssertTrue(true, "announceScreenChange should execute without crashing")
    }

    // MARK: - Integration Tests

    func testComposableContainer_RegistersAccessibilityServices() async throws {
        // Given: ComposableContainer is configured
        // (done in setUp)

        // When: Getting current container
        let container = await DIContainer.current

        // Then: Container should be available
        XCTAssertNotNil(container)

        // And: Should be able to resolve accessibility services
        if let container = container {
            let service = try? await container.resolve(AccessibilityAnnouncementService.self)
            XCTAssertNotNil(service)
        }
    }
}
